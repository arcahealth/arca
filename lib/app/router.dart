import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaisel/kaisel.dart';

import '../core/onboarding/repositories/onboarding_repository.dart';
import '../core/vault/models/vault.dart';
import '../core/vault/repositories/vault_repository.dart';
import '../features/journal/domain/repositories/journal_repository.dart';
import '../features/journal/presentation/bloc/journal_bloc.dart';
import '../features/journal/presentation/bloc/journal_event.dart';
import '../features/journal/presentation/screens/journal_screen.dart';
import '../features/journal/presentation/screens/record_detail_screen.dart';
import '../features/model_downloader/presentation/screens/model_download_screen.dart';
import '../features/model_downloader/presentation/widgets/model_download_indicator_bar.dart';
import '../features/setup_wizard/presentation/screens/setup_wizard_screen.dart';
import '../features/vaults/presentation/bloc/vault_bloc.dart';
import '../features/vaults/presentation/bloc/vault_event.dart';
import '../features/vaults/presentation/bloc/vault_state.dart';
import '../features/vaults/presentation/screens/vault_selection_screen.dart';
import '../features/vaults/presentation/widgets/vault_switcher_bar.dart';
import '../features/welcome/presentation/screens/welcome_screen.dart';
import 'routes.dart';

/// Constructs the top-level Kaisel router configuration with sealed-route pattern matching.
///
/// Serves as the central orchestration seam: wires constructor callbacks between
/// isolated feature modules without allowing cross-module imports.
KaiselRouterConfig<AppRoute> createAppRouter({
  required JournalRepository repository,
  required VaultRepository vaultRepository,
  required OnboardingRepository onboardingRepository,
  AppRoute initial = const JournalRoute(),
}) {
  return KaiselRouterConfig<AppRoute>(
    initial: initial,
    codec: const StackToConfigCodec(AppStackCodec()),
    builder: (context, route) => switch (route) {
      WelcomeRoute() => WelcomeScreen(
        onStartSetup: () => context.push(const SetupWizardRoute()),
        onSkip: () async {
          await onboardingRepository.setCompletedOnboarding(true);
          final vaults = await vaultRepository.getVaults();
          if (!context.mounted) return;
          if (vaults.isEmpty) {
            context.push(const VaultSelectionRoute());
          } else if (vaults.length == 1) {
            context.push(const JournalRoute());
          } else {
            context.push(const VaultSelectionRoute());
          }
        },
      ),
      SetupWizardRoute() => SetupWizardScreen(
        onBack: () => context.pop(),
        onSkip: () async {
          await onboardingRepository.setCompletedOnboarding(true);
          final vaults = await vaultRepository.getVaults();
          if (!context.mounted) return;
          if (vaults.isEmpty) {
            context.push(const VaultSelectionRoute());
          } else if (vaults.length == 1) {
            context.push(const JournalRoute());
          } else {
            context.push(const VaultSelectionRoute());
          }
        },
        onComplete: ({required hasSelectedAiModels, required vaultCount}) {
          if (hasSelectedAiModels) {
            context.push(const ModelDownloadRoute());
          } else if (vaultCount == 0) {
            context.push(const VaultSelectionRoute());
          } else if (vaultCount == 1) {
            context.push(const JournalRoute());
          } else {
            context.push(const VaultSelectionRoute());
          }
        },
      ),
      ModelDownloadRoute(:final selectedCapabilityIds) => ModelDownloadScreen(
        selectedCapabilityIds: selectedCapabilityIds,
        onContinue: () async {
          final vaults = await vaultRepository.getVaults();
          if (!context.mounted) return;
          if (vaults.isEmpty) {
            context.push(const VaultSelectionRoute());
          } else if (vaults.length == 1) {
            context.push(const JournalRoute());
          } else {
            context.push(const VaultSelectionRoute());
          }
        },
      ),
      VaultSelectionRoute() => VaultSelectionScreen(
        onVaultSelected: (vaultId) => context.push(const JournalRoute()),
        onVaultCreated: (vault) => context.push(const JournalRoute()),
      ),
      JournalRoute() => Builder(
        builder: (context) {
          VaultLoaded? vaultLoaded;
          try {
            final state = context.watch<VaultBloc>().state;
            if (state is VaultLoaded) {
              vaultLoaded = state;
            }
          } catch (_) {
            // Isolated test fallback
          }

          final activeVault = vaultLoaded?.activeVault;
          final vaults = vaultLoaded?.vaults ?? <Vault>[];

          // Route guard: if no vaults exist, render VaultSelectionScreen
          if (vaultLoaded != null && vaults.isEmpty) {
            return VaultSelectionScreen(
              onVaultCreated: (_) =>
                  context.read<VaultBloc>().add(const VaultLoadRequested()),
            );
          }

          return JournalScreen(
            activeMemberName: activeVault?.name,
            topBanner: ModelDownloadIndicatorBar(
              onTap: () => context.push(const ModelDownloadRoute()),
            ),
            vaultSwitcher: vaults.isNotEmpty && activeVault != null
                ? VaultSwitcherBar(
                    vaults: vaults,
                    activeVault: activeVault,
                    onVaultSelected: (id) {
                      context.read<VaultBloc>().add(VaultActiveSwitched(id));
                      context.read<JournalBloc>().add(
                        JournalLoadRequested(memberId: id),
                      );
                    },
                    onAddVault: () => context.push(const VaultSelectionRoute()),
                  )
                : null,
            onRecordSelected: (recordId) =>
                context.push(RecordDetailRoute(recordId)),
            onManageVaults: () => context.push(const VaultSelectionRoute()),
          );
        },
      ),
      RecordDetailRoute(:final recordId) => RecordDetailScreen(
        recordId: recordId,
        repository: repository,
        onBack: () => context.pop(),
      ),
    },
  );
}
