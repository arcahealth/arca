import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite_async/sqlite_async.dart';
import 'package:arca/app/app.dart';
import 'package:arca/core/database/database_manager.dart';
import 'package:arca/core/database/database_service.dart';
import 'package:arca/core/design_system/arca_design_system.dart';
import 'package:arca/core/onboarding/repositories/in_memory_onboarding_repository.dart';
import 'package:arca/core/vault/repositories/in_memory_vault_repository.dart';
import 'package:arca/features/journal/data/repositories/in_memory_journal_repository.dart';
import 'package:arca/features/journal/domain/models/journal_entry.dart';
import 'package:arca/features/journal/domain/repositories/journal_repository.dart';

void main() {
  group('JournalScreen Widget Tests', () {
    late Directory tempDir;
    late SqliteDatabase db;
    late DatabaseService databaseService;
    late JournalRepository fakeRepository;
    final testEntry = JournalEntry(
      id: 'entry-test-1',
      title: 'Resting Heart Rate & HRV Baseline',
      summary: 'Biometrics synced locally via health subsystem.',
      category: JournalCategory.vital,
      recordedAt: DateTime(2026, 11, 7),
      memberId: 'self',
    );

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'arca_journal_screen_test_',
      );
      final dbPath = p.join(tempDir.path, 'test.db');
      db = SqliteDatabase(path: dbPath);
      databaseService = DatabaseManager(customDatabase: db);
      fakeRepository = InMemoryJournalRepository(initialEntries: [testEntry]);
    });

    tearDown(() async {
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets('renders header, badges, and clinical journal entry', (
      tester,
    ) async {
      final container = ArcaAppContainer(
        journalRepository: fakeRepository,
        vaultRepository: InMemoryVaultRepository(),
        onboardingRepository: InMemoryOnboardingRepository(
          hasCompletedOnboarding: true,
        ),
        databaseService: databaseService,
      );
      await container.init();
      await tester.pumpWidget(ArcaApp(appContainer: container));
      await tester.pumpAndSettle();

      expect(find.text('Arca Journal'), findsOneWidget);
      expect(find.textContaining('Longitudinal Family Vault'), findsOneWidget);
      expect(find.text('Resting Heart Rate & HRV Baseline'), findsOneWidget);
      expect(find.text('VITAL'), findsOneWidget);
    });

    testWidgets('tapping an entry navigates to RecordDetailScreen and back', (
      tester,
    ) async {
      final container = ArcaAppContainer(
        journalRepository: fakeRepository,
        vaultRepository: InMemoryVaultRepository(),
        onboardingRepository: InMemoryOnboardingRepository(
          hasCompletedOnboarding: true,
        ),
        databaseService: databaseService,
      );
      await container.init();
      await tester.pumpWidget(ArcaApp(appContainer: container));
      await tester.pumpAndSettle();

      // Tap on the card
      final cardFinder = find.byType(ArcaCard);
      expect(cardFinder, findsOneWidget);
      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      // Verify we arrived at the detail screen
      expect(find.text('Clinical Record Detail'), findsOneWidget);
      expect(find.text('Clinical Findings & Summary'), findsOneWidget);
      expect(find.text('VERIFIED ON-DEVICE'), findsOneWidget);

      // Tap the back button
      final backButton = find.text('← Back');
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Verify we returned to the journal timeline
      expect(find.text('Arca Journal'), findsOneWidget);
    });
  });
}
