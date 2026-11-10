import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite_async/sqlite_async.dart';
import 'package:arca/app/app.dart';
import 'package:arca/core/ai/models/ai_model.dart';
import 'package:arca/core/database/database_manager.dart';
import 'package:arca/core/database/database_service.dart';
import 'package:arca/core/design_system/arca_design_system.dart';
import 'package:arca/core/downloader/services/download_manager.dart';
import 'package:arca/core/downloader/services/download_service.dart';
import 'package:arca/core/onboarding/repositories/in_memory_onboarding_repository.dart';
import 'package:arca/core/onboarding/repositories/onboarding_repository.dart';
import 'package:arca/core/vault/repositories/in_memory_vault_repository.dart';
import 'package:arca/core/vault/repositories/vault_repository.dart';
import 'package:arca/features/journal/data/repositories/in_memory_journal_repository.dart';
import 'package:arca/features/journal/domain/repositories/journal_repository.dart';

void main() {
  group('Router Orchestration End-to-End Tests', () {
    late Directory tempDir;
    late SqliteDatabase db;
    late DatabaseService databaseService;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('arca_router_test_');
      final dbPath = p.join(tempDir.path, 'test.db');
      db = SqliteDatabase(path: dbPath);
      databaseService = DatabaseManager(customDatabase: db);
    });

    tearDown(() async {
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets(
      'Full flow: Welcome -> SetupWizard -> ModelDownload -> Dashboard',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final VaultRepository vaultRepo = InMemoryVaultRepository(
          initialVaults: [],
        );
        final JournalRepository journalRepo = InMemoryJournalRepository();
        final OnboardingRepository onboardingRepo =
            InMemoryOnboardingRepository(hasCompletedOnboarding: false);
        final DownloadService<AIKind, AIKind> modelService =
            DownloadManager<AIKind, AIKind>();
        addTearDown(vaultRepo.dispose);
        addTearDown(modelService.dispose);

        final container = ArcaAppContainer(
          vaultRepository: vaultRepo,
          journalRepository: journalRepo,
          onboardingRepository: onboardingRepo,
          modelDownloadService: modelService,
          databaseService: databaseService,
        );
        await container.init();

        await tester.pumpWidget(ArcaApp(appContainer: container));
        await tester.pumpAndSettle();

        // 1. Welcome screen renders
        expect(find.text('Welcome to Arca'), findsOneWidget);

        // Tap start setup CTA (router pushes SetupWizardRoute)
        final startBtn = find.text('Start Setup Wizard →');
        await tester.ensureVisible(startBtn);
        await tester.tap(startBtn);
        await tester.pumpAndSettle();

        // 2. Setup wizard renders
        expect(find.text('Setup Health Vaults'), findsOneWidget);

        final textField = find.byType(ArcaTextField).first;
        await tester.enterText(textField, 'Primary Vault');
        await tester.pumpAndSettle();

        final addBtn = find.text('+ Add to Vault List');
        await tester.ensureVisible(addBtn);
        await tester.tap(addBtn);
        await tester.pumpAndSettle();

        final nextBtn = find.text('Next: AI Setup →');
        await tester.ensureVisible(nextBtn);
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();

        expect(find.text('On-Device AI Setup'), findsOneWidget);

        final completeBtn = find.text('Complete Setup ✓');
        await tester.ensureVisible(completeBtn);
        await tester.tap(completeBtn);
        await tester.pumpAndSettle();

        // 3. Router pushed ModelDownloadRoute because AI models were selected
        expect(find.text('Downloading Edge AI'), findsOneWidget);

        // Tap Continue to App (router pushes JournalRoute)
        final continueBtn = find.byWidgetPredicate(
          (w) =>
              w is ArcaButton &&
              (w.label.contains('Open Health Dashboard') ||
                  w.label.contains('Continue to App')),
        );
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        // 4. Arrived at Dashboard / Journal with active vault
        expect(find.text('Arca Journal'), findsOneWidget);
        expect(
          find.textContaining('Primary Vault • Longitudinal Family Vault'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Skipping welcome with 0 vaults navigates to VaultSelectionRoute (route guard)',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final VaultRepository vaultRepo = InMemoryVaultRepository(
          initialVaults: [],
        );
        final JournalRepository journalRepo = InMemoryJournalRepository();
        final OnboardingRepository onboardingRepo =
            InMemoryOnboardingRepository(hasCompletedOnboarding: false);
        final DownloadService<AIKind, AIKind> modelService =
            DownloadManager<AIKind, AIKind>();
        addTearDown(vaultRepo.dispose);
        addTearDown(modelService.dispose);

        final container = ArcaAppContainer(
          vaultRepository: vaultRepo,
          journalRepository: journalRepo,
          onboardingRepository: onboardingRepo,
          modelDownloadService: modelService,
          databaseService: databaseService,
        );
        await container.init();

        await tester.pumpWidget(ArcaApp(appContainer: container));
        await tester.pumpAndSettle();

        final skipBtn = find.text('Skip Setup & Quick Start');
        await tester.ensureVisible(skipBtn);
        await tester.tap(skipBtn);
        await tester.pumpAndSettle();

        // Enforced by router: 0 vaults -> VaultSelectionRoute
        expect(find.text('No Vaults Configured'), findsOneWidget);
        expect(find.text('Create Your First Health Vault'), findsOneWidget);
      },
    );
  });
}
