import 'package:sqlite_async/sqlite_async.dart';

/// Abstract service interface for managing on-device SQLite database connection pools,
/// lifecycle, and migrations.
abstract interface class DatabaseService {
  /// Active SQLite database connection pool.
  SqliteDatabase get db;

  /// Initializes the local database file and runs pending migrations.
  Future<void> initialize({String? customPath});

  /// Closes database connections safely.
  Future<void> close();
}
