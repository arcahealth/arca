import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite_async/sqlite_async.dart';
import 'package:arca/core/database/migrations.dart';
import 'package:arca/features/journal/data/repositories/sqlite_journal_repository.dart';
import 'package:arca/features/journal/domain/models/journal_entry.dart';
import 'package:arca/features/journal/domain/repositories/journal_repository.dart';

void main() {
  group('SqliteJournalRepository Tests', () {
    late Directory tempDir;
    late SqliteDatabase db;
    late JournalRepository repository;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('arca_db_test_');
      final dbPath = p.join(tempDir.path, 'test_vault.db');
      db = SqliteDatabase(path: dbPath);
      await ArcaDatabaseMigrations.migrations.migrate(db);
      repository = SqliteJournalRepository(db: db);
    });

    tearDown(() async {
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'adds and retrieves entries sorted by recordedAt descending',
      () async {
        final entry1 = JournalEntry(
          id: 'entry-1',
          title: 'Morning Vitals',
          summary: 'Blood pressure 120/80 mmHg',
          category: JournalCategory.vital,
          recordedAt: DateTime(2026, 11, 7, 8),
          memberId: 'self',
        );

        final entry2 = JournalEntry(
          id: 'entry-2',
          title: 'Evening Vitals',
          summary: 'Blood pressure 118/76 mmHg',
          category: JournalCategory.vital,
          recordedAt: DateTime(2026, 11, 7, 20),
          memberId: 'self',
        );

        await repository.addEntry(entry1);
        await repository.addEntry(entry2);

        final entries = await repository.getEntries();
        expect(entries.length, 2);
        // Verify descending chronological order
        expect(entries.first.id, 'entry-2');
        expect(entries.last.id, 'entry-1');
      },
    );

    test('filters entries by memberId', () async {
      final selfEntry = JournalEntry(
        id: 'self-1',
        title: 'Self Checkup',
        summary: 'Routine review',
        category: JournalCategory.visit,
        recordedAt: DateTime(2026, 11, 6),
        memberId: 'self',
      );

      final childEntry = JournalEntry(
        id: 'child-1',
        title: 'Pediatric Vaccine',
        summary: 'Scheduled immunization administered',
        category: JournalCategory.medication,
        recordedAt: DateTime(2026, 11, 7),
        memberId: 'child_1',
      );

      await repository.addEntry(selfEntry);
      await repository.addEntry(childEntry);

      final selfRecords = await repository.getEntries(memberId: 'self');
      expect(selfRecords.length, 1);
      expect(selfRecords.first.id, 'self-1');

      final childRecords = await repository.getEntries(memberId: 'child_1');
      expect(childRecords.length, 1);
      expect(childRecords.first.id, 'child-1');
    });

    test('getEntryById returns matching entry or null', () async {
      final entry = JournalEntry(
        id: 'vital-99',
        title: 'Metabolic Panel',
        summary: 'Glucose 95 mg/dL',
        category: JournalCategory.lab,
        recordedAt: DateTime(2026, 11, 7),
        memberId: 'self',
      );

      await repository.addEntry(entry);

      final found = await repository.getEntryById('vital-99');
      expect(found, isNotNull);
      expect(found!.title, 'Metabolic Panel');

      final notFound = await repository.getEntryById('non-existent');
      expect(notFound, isNull);
    });
  });
}
