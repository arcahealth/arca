import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arca/core/ai/models/ai_model.dart';
import 'package:arca/core/design_system/arca_design_system.dart';
import 'package:arca/core/downloader/services/download_manager.dart';
import 'package:arca/core/downloader/services/downloader_service.dart';
import 'package:arca/core/onboarding/repositories/in_memory_onboarding_repository.dart';
import 'package:arca/core/onboarding/repositories/onboarding_repository.dart';
import 'package:arca/core/vault/repositories/in_memory_vault_repository.dart';
import 'package:arca/core/vault/repositories/vault_repository.dart';
import 'package:arca/features/setup_wizard/presentation/bloc/setup_wizard_bloc.dart';
import 'package:arca/features/setup_wizard/presentation/screens/setup_wizard_screen.dart';

void main() {
  group('SetupWizardScreen Tests', () {
    testWidgets(
      'creates vault draft, advances step, and fires onComplete callback',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final VaultRepository vaultRepo = InMemoryVaultRepository(
          initialVaults: [],
        );
        final OnboardingRepository onboardingRepo =
            InMemoryOnboardingRepository();
        final DownloaderService<AIKind, AIKind> modelService =
            DownloadManager<AIKind, AIKind>(tickInterval: Duration.zero);
        addTearDown(vaultRepo.dispose);
        addTearDown(modelService.dispose);

        var completed = false;
        var hasAi = false;
        var capturedVaultCount = 0;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: BlocProvider<SetupWizardBloc>(
              create: (_) => SetupWizardBloc(
                vaultRepository: vaultRepo,
                onboardingRepository: onboardingRepo,
                modelDownloadService: modelService,
              ),
              child: SetupWizardScreen(
                onComplete:
                    ({required hasSelectedAiModels, required vaultCount}) {
                      completed = true;
                      hasAi = hasSelectedAiModels;
                      capturedVaultCount = vaultCount;
                    },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final textField = find.byType(ArcaTextField).first;
        await tester.enterText(textField, 'Personal Vault');
        await tester.pumpAndSettle();

        final addBtn = find.text('+ Add to Vault List');
        await tester.ensureVisible(addBtn);
        await tester.tap(addBtn);
        await tester.pumpAndSettle();

        expect(find.text('Configured Vaults (1)'), findsOneWidget);
        expect(find.text('Personal Vault'), findsOneWidget);

        final nextBtn = find.text('Next: AI Setup →');
        await tester.ensureVisible(nextBtn);
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();

        expect(find.text('On-Device AI Setup'), findsOneWidget);

        final completeBtn = find.text('Complete Setup ✓');
        await tester.ensureVisible(completeBtn);
        await tester.tap(completeBtn);
        await tester.pumpAndSettle();

        expect(completed, isTrue);
        expect(hasAi, isTrue);
        expect(capturedVaultCount, 1);
      },
    );
  });
}
