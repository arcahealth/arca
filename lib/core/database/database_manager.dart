import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite_async/sqlite_async.dart';

import 'database_service.dart';
import 'migrations.dart';

/// Manages lifecycle, connection pool, and migrations for the on-device SQLite vault.
class DatabaseManager implements DatabaseService {
  DatabaseManager({SqliteDatabase? customDatabase}) : _db = customDatabase;

  SqliteDatabase? _db;

  /// Active SQLite database connection pool.
  @override
  SqliteDatabase get db {
    final database = _db;
    if (database == null) {
      throw StateError(
        'DatabaseManager has not been initialized. Call initialize() first.',
      );
    }
    return database;
  }

  /// Initializes the local database file and runs pending migrations.
  @override
  Future<void> initialize({String? customPath}) async {
    if (_db != null) return;

    final dbPath = customPath ?? await _getDefaultDatabasePath();
    final database = SqliteDatabase(path: dbPath);
    await ArcaDatabaseMigrations.migrations.migrate(database);
    _db = database;
  }

  static Future<String> _getDefaultDatabasePath() async {
    final supportDir = await getApplicationSupportDirectory();
    return p.join(supportDir.path, 'arca_vault.db');
  }

  /// Closes database connections safely.
  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
