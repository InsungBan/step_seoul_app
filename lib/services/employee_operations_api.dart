import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:step_seoul_app/services/api_config.dart';

class EmployeeOperationsApi {
  EmployeeOperationsApi._();
  static final instance = EmployeeOperationsApi._();

  static const _scopeId = 'step-pickup';
  final http.Client _client = http.Client();

  Uri get _stateUri => Uri.parse(
    ApiConfig.baseUrl + '/employee-operations/state',
  ).replace(queryParameters: {'scope_id': _scopeId});

  Future<Map<String, dynamic>?> readState() async {
    final response = await _client
        .get(_stateUri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception(
        'API state read failed (' + response.statusCode.toString() + ')',
      );
    }
    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final state = body['state'];
    return state == null ? null : Map<String, dynamic>.from(state as Map);
  }

  Future<void> writeState(Map<String, dynamic> state) async {
    final response = await _client
        .put(
          _stateUri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'scope_id': _scopeId, 'state': state}),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'API state save failed (' + response.statusCode.toString() + ')',
      );
    }
  }
}
