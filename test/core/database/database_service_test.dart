import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:arca/core/database/database_service.dart';

void main() {
  group('DatabaseService Tests', () {
    late Directory tempDir;
    late DatabaseService databaseService;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('arca_db_service_test_');
      databaseService = DatabaseManager();
    });

    tearDown(() async {
      await databaseService.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('throws StateError when accessing db before initialization', () {
      expect(() => databaseService.db, throwsStateError);
    });

    test('initializes database, runs migrations, and creates tables', () async {
      final dbPath = p.join(tempDir.path, 'vault.db');
      await databaseService.initialize(customPath: dbPath);

      expect(databaseService.db, isNotNull);

      // Verify tables were created by migrations
      final tables = await databaseService.db.getAll(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );
      final tableNames = tables.map((r) => r['name'] as String).toList();

      expect(tableNames, contains('profiles'));
      expect(tableNames, contains('journal_entries'));
    });
  });
}
