import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/routes.dart';
import 'core/database/database_manager.dart';
import 'core/database/database_service.dart';
import 'core/onboarding/repositories/onboarding_repository.dart';
import 'core/onboarding/repositories/shared_prefs_onboarding_repository.dart';
import 'core/vault/repositories/sqlite_vault_repository.dart';
import 'core/vault/repositories/vault_repository.dart';
import 'features/journal/data/repositories/sqlite_journal_repository.dart';
import 'features/journal/domain/repositories/journal_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core on-device persistence services via their abstract interfaces
  final OnboardingRepository onboardingRepo = SharedPrefsOnboardingRepository();
  final hasCompleted = await onboardingRepo.hasCompletedOnboarding();

  final DatabaseService databaseService = DatabaseManager();
  await databaseService.initialize();

  final VaultRepository vaultRepo = SqliteVaultRepository(
    db: databaseService.db,
  );
  final JournalRepository journalRepo = SqliteJournalRepository(
    db: databaseService.db,
  );

  final initialRoute = hasCompleted
      ? const JournalRoute()
      : const WelcomeRoute();

  runApp(
    ArcaApp(
      onboardingRepository: onboardingRepo,
      vaultRepository: vaultRepo,
      journalRepository: journalRepo,
      databaseService: databaseService,
      initialRoute: initialRoute,
    ),
  );
}
