import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

enum UserRole { customer, employee, executive }

class AppSession {
  const AppSession({required this.userId, required this.role});
  final String userId;
  final UserRole role;
}

/// Persists only an account identifier and its resolved role.
/// Passwords are intentionally never written to device storage.
class SessionService {
  SessionService._();
  static final instance = SessionService._();

  static const _table = 'app_session';
  static const _branchTable = 'selected_branch';
  Database? _database;
  AppSession? _memorySession;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    final directory = await getDatabasesPath();
    _database = await openDatabase(
      join(directory, 'step_seoul.db'),
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE $_table (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          user_id TEXT NOT NULL,
          role TEXT NOT NULL
        )
      '''),
    );
    return _database!;
  }

  Future<AppSession?> readSession() async {
    if (_memorySession != null) return _memorySession;
    final rows = await (await _db).query(
      _table,
      where: 'id = ?',
      whereArgs: [1],
    );
    if (rows.isEmpty) return null;
    final role = UserRole.values
        .where((item) => item.name == rows.first['role'])
        .firstOrNull;
    if (role == null) {
      await clearSession();
      return null;
    }
    _memorySession = AppSession(
      userId: rows.first['user_id']! as String,
      role: role,
    );
    return _memorySession;
  }

  Future<void> _ensureBranchTable() async {
    await (await _db).execute('''
      CREATE TABLE IF NOT EXISTS $_branchTable (
        user_id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL
      )
    ''');
  }

  Future<String?> readSelectedStoreId(String userId) async {
    await _ensureBranchTable();
    final rows = await (await _db).query(
      _branchTable,
      columns: ['store_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return rows.isEmpty ? null : rows.first['store_id'] as String?;
  }

  Future<void> saveSelectedStoreId({
    required String userId,
    required String storeId,
  }) async {
    await _ensureBranchTable();
    await (await _db).insert(_branchTable, {
      'user_id': userId,
      'store_id': storeId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveSession({
    required String userId,
    required UserRole role,
    bool persist = true,
  }) async {
    _memorySession = AppSession(userId: userId, role: role);
    if (!persist) {
      await (await _db).delete(_table, where: 'id = ?', whereArgs: [1]);
      return;
    }
    await (await _db).insert(_table, {
      'id': 1,
      'user_id': userId,
      'role': role.name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearSession() async {
    _memorySession = null;
    final rows = await (await _db).query(
      _table,
      columns: ['user_id'],
      where: 'id = ?',
      whereArgs: [1],
    );
    final userId = rows.isEmpty ? null : rows.first['user_id'] as String?;
    if (userId != null) {
      await _ensureBranchTable();
      await (await _db).delete(
        _branchTable,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }
    await (await _db).delete(_table, where: 'id = ?', whereArgs: [1]);
  }
}
