import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:step_seoul_app/services/app_state.dart';
import 'package:step_seoul_app/services/employee_operations_api.dart';

class EmployeeOperationsSync {
  EmployeeOperationsSync._();
  static final instance = EmployeeOperationsSync._();

  final _database = MockDatabase.instance;
  final _api = EmployeeOperationsApi.instance;
  Timer? _saveTimer;
  bool _started = false;
  bool _connecting = false;
  bool _saving = false;
  bool _applyingRemote = false;
  bool _initialized = false;
  bool _dirty = false;
  int _revision = 0;
  bool isConnected = false;
  String? lastError;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _database.addListener(_onLocalChange);
    Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_initialized || _dirty) unawaited(_connectAndSync());
    });
    await _connectAndSync();
  }

  void _onLocalChange() {
    if (_applyingRemote) return;
    _revision++;
    _dirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), () {
      if (_initialized) unawaited(_writeLatest());
    });
  }

  Future<void> _connectAndSync() async {
    if (_connecting) return;
    _connecting = true;
    try {
      final remoteState = await _api.readState();
      if (!_initialized) {
        if (remoteState != null && !_dirty) {
          _applyingRemote = true;
          try {
            _database.restoreState(remoteState);
          } finally {
            _applyingRemote = false;
          }
        }
        _initialized = true;
      }
      isConnected = true;
      lastError = null;
      if (_dirty || remoteState == null) await _writeLatest();
    } catch (error) {
      isConnected = false;
      lastError = error.toString();
      debugPrint('Employee state sync unavailable: ' + error.toString());
    } finally {
      _connecting = false;
    }
  }

  Future<void> _writeLatest() async {
    if (!_initialized || _saving) return;
    _saving = true;
    final revision = _revision;
    try {
      await _api.writeState(_database.exportState());
      isConnected = true;
      lastError = null;
      if (_revision == revision) _dirty = false;
    } catch (error) {
      isConnected = false;
      lastError = error.toString();
      debugPrint('Employee state save failed: ' + error.toString());
    } finally {
      _saving = false;
      if (_dirty) {
        _saveTimer?.cancel();
        _saveTimer = Timer(const Duration(milliseconds: 300), () {
          unawaited(_writeLatest());
        });
      }
    }
  }
}
