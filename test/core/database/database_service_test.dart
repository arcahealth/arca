import 'dart:io';

import 'package:arca/core/database/database_service.dart';
import 'package:arca/core/di/di.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite_async/sqlite_async.dart';

void main() {
  group('DatabaseService Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('arca_db_service_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('DatabaseManager.open initializes database, runs migrations, and creates tables', () async {
      final dbPath = p.join(tempDir.path, 'vault.db');
      final service = await DatabaseManager.open(DatabaseConfig(path: dbPath));

      addTearDown(service.close);

      expect(service.db, isNotNull);

      // Verify tables were created by migrations
      final tables = await service.db.getAll(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );
      final tableNames = tables.map((r) => r['name'] as String).toList();

      expect(tableNames, contains('profiles'));
      expect(tableNames, contains('journal_entries'));
    });

    test('DatabaseManager wraps existing SqliteDatabase directly and closes cleanly', () async {
      final dbPath = p.join(tempDir.path, 'direct_vault.db');
      final sqliteDb = SqliteDatabase(path: dbPath);
      final service = DatabaseManager(sqliteDb);

      expect(service.db, equals(sqliteDb));
      await service.close();
    });

    test(
      'Circuit resolves DatabaseService.wire via DatabaseConfig wire in DAG',
      () async {
        final dbPath = p.join(tempDir.path, 'circuit_vault.db');
        final circuit = await Circuit.build([
          Wire<DatabaseConfig>(() => DatabaseConfig(path: dbPath)),
          DatabaseService.wire,
        ]);

        final service = circuit.get<DatabaseService>();
        expect(service.db, isNotNull);

        final tables = await service.db.getAll(
          "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
        );
        final tableNames = tables.map((r) => r['name'] as String).toList();
        expect(tableNames, contains('profiles'));

        await circuit.dispose();
      },
    );
  });
}
