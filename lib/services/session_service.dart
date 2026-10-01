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
  Database? _database;

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
    return AppSession(userId: rows.first['user_id']! as String, role: role);
  }

  Future<void> saveSession({
    required String userId,
    required UserRole role,
  }) async {
    await (await _db).insert(_table, {
      'id': 1,
      'user_id': userId,
      'role': role.name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearSession() async {
    await (await _db).delete(_table, where: 'id = ?', whereArgs: [1]);
  }
}
