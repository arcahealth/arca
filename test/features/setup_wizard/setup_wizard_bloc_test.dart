import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arca/core/ai/models/ai_model.dart';
import 'package:arca/core/model_downloader/services/model_download_manager.dart';
import 'package:arca/core/model_downloader/services/model_download_service.dart';
import 'package:arca/core/onboarding/repositories/in_memory_onboarding_repository.dart';
import 'package:arca/core/onboarding/repositories/onboarding_repository.dart';
import 'package:arca/core/vault/models/vault.dart';
import 'package:arca/core/vault/repositories/in_memory_vault_repository.dart';
import 'package:arca/core/vault/repositories/vault_repository.dart';
import 'package:arca/features/setup_wizard/presentation/bloc/setup_wizard_bloc.dart';
import 'package:arca/features/setup_wizard/presentation/bloc/setup_wizard_event.dart';
import 'package:arca/features/setup_wizard/presentation/bloc/setup_wizard_state.dart';

void main() {
  group('SetupWizardBloc Tests', () {
    late VaultRepository vaultRepository;
    late OnboardingRepository onboardingRepository;
    late ModelDownloadService modelDownloadService;

    setUp(() {
      vaultRepository = InMemoryVaultRepository(initialVaults: []);
      onboardingRepository = InMemoryOnboardingRepository();
      modelDownloadService = ModelDownloadManager(tickInterval: Duration.zero);
    });

    tearDown(() {
      vaultRepository.dispose();
      modelDownloadService.dispose();
    });

    final testVault = Vault(
      id: 'vault-1',
      name: 'Primary Vault',
      relationship: VaultRelationship.self,
      createdAt: DateTime(2026, 1, 1),
    );

    blocTest<SetupWizardBloc, SetupWizardState>(
      'adds and removes draft vaults',
      build: () => SetupWizardBloc(
        vaultRepository: vaultRepository,
        onboardingRepository: onboardingRepository,
        modelDownloadService: modelDownloadService,
      ),
      act: (bloc) {
        bloc.add(SetupWizardVaultDraftAdded(testVault));
        bloc.add(const SetupWizardVaultDraftRemoved('vault-1'));
      },
      expect: () => [
        SetupWizardState(vaultDrafts: [testVault]),
        const SetupWizardState(vaultDrafts: []),
      ],
    );

    blocTest<SetupWizardBloc, SetupWizardState>(
      'toggles AI capabilities and finishes setup by persisting data',
      build: () => SetupWizardBloc(
        vaultRepository: vaultRepository,
        onboardingRepository: onboardingRepository,
        modelDownloadService: modelDownloadService,
      ),
      seed: () => SetupWizardState(vaultDrafts: [testVault]),
      act: (bloc) {
        bloc.add(const SetupWizardAiCapabilityToggled(AIKind.ocr));
        bloc.add(const SetupWizardFinishedRequested());
      },
      expect: () => [
        SetupWizardState(
          vaultDrafts: [testVault],
          selectedAiCapabilities: const {AIKind.asr},
        ),
        SetupWizardState(
          vaultDrafts: [testVault],
          selectedAiCapabilities: const {AIKind.asr},
          isSaving: true,
        ),
        SetupWizardState(
          vaultDrafts: [testVault],
          selectedAiCapabilities: const {AIKind.asr},
          isSaving: false,
          isFinished: true,
        ),
      ],
      verify: (_) async {
        expect(await onboardingRepository.hasCompletedOnboarding(), isTrue);
        final vaults = await vaultRepository.getVaults();
        expect(vaults.length, 1);
        expect(vaults.first.name, 'Primary Vault');
      },
    );
  });
}
