import 'package:arca/core/database/migrations.dart';
import 'package:circuitry_flutter/circuitry_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_manager/path_manager.dart';
import 'package:sqlite_async/sqlite_async.dart';

/// Configuration for on-device SQLite database storage location and options.
final class const DatabaseConfig({
  /// Absolute filesystem path to the SQLite vault file.
  required final String path,
}) {
  /// Default wire resolving application support directory via [PathManager].
  static AsyncWire<DatabaseConfig> get wire => .new(() async {
    final supportDir = await PathManager.getApplicationSupportDirectory();
    return .new(path: p.join(supportDir.path, 'arca_vault.db'));
  });
}

/// Abstract service interface for managing on-device SQLite database connection pools
/// and lifecycle.
abstract interface class DatabaseService {
  /// Resolves [DatabaseService] by feeding [DatabaseConfig] into [DatabaseManager.open].
  static AsyncWire<DatabaseService> get wire => AsyncWire.takes<DatabaseConfig>().to(
    DatabaseManager.open,
    onDispose: (service) => service.close(),
  );

  /// Active SQLite database connection pool.
  SqliteDatabase get db;

  /// Closes database connections safely.
  Future<void> close();
}

/// Creates a ready-to-use [DatabaseService] wrapping an already opened and migrated connection pool.
/// Manages lifecycle, connection pool, and migrations for the on-device SQLite vault.
final class const DatabaseManager(this.db) implements DatabaseService {
  @override
  final SqliteDatabase db;

  /// Asynchronous factory: opens the SQLite connection pool at [config.path],
  /// runs pending schema migrations, and returns an initialized [DatabaseManager].
  static Future<DatabaseManager> open(DatabaseConfig config) async {
    final database = SqliteDatabase(path: config.path);
    await ArcaDatabaseMigrations.migrate(database);
    return DatabaseManager(database);
  }

  /// Closes database connections safely.
  @override
  Future<void> close() => db.close();
}
