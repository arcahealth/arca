import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/model_downloader/repositories/model_downloader_repository.dart';
import '../../../../core/onboarding/repositories/onboarding_repository.dart';
import '../../../../core/vault/repositories/vault_repository.dart';
import 'setup_wizard_event.dart';
import 'setup_wizard_state.dart';

class SetupWizardBloc extends Bloc<SetupWizardEvent, SetupWizardState> {
  SetupWizardBloc({
    required this.vaultRepository,
    required this.onboardingRepository,
    required this.modelDownloaderRepository,
  }) : super(const SetupWizardState()) {
    on<SetupWizardStarted>((event, emit) => emit(const SetupWizardState()));
    on<SetupWizardStepChanged>((event, emit) {
      emit(state.copyWith(currentStep: event.stepIndex));
    });
    on<SetupWizardVaultDraftAdded>((event, emit) {
      final updated = List.of(state.vaultDrafts)..add(event.vault);
      emit(state.copyWith(vaultDrafts: updated));
    });
    on<SetupWizardVaultDraftRemoved>((event, emit) {
      final updated = state.vaultDrafts
          .where((v) => v.id != event.vaultId)
          .toList(growable: false);
      emit(state.copyWith(vaultDrafts: updated));
    });
    on<SetupWizardAiCapabilityToggled>((event, emit) {
      final updated = Set.of(state.selectedAiCapabilities);
      if (updated.contains(event.type)) {
        updated.remove(event.type);
      } else {
        updated.add(event.type);
      }
      emit(state.copyWith(selectedAiCapabilities: updated));
    });
    on<SetupWizardFinishedRequested>(_onFinishedRequested);
  }

  final VaultRepository vaultRepository;
  final OnboardingRepository onboardingRepository;
  final ModelDownloaderRepository modelDownloaderRepository;

  Future<void> _onFinishedRequested(
    SetupWizardFinishedRequested event,
    Emitter<SetupWizardState> emit,
  ) async {
    emit(state.copyWith(isSaving: true));
    try {
      for (final vault in state.vaultDrafts) {
        await vaultRepository.addVault(vault);
      }
      if (state.vaultDrafts.isNotEmpty) {
        await vaultRepository.setActiveVaultId(state.vaultDrafts.first.id);
      }

      if (state.selectedAiCapabilities.isNotEmpty) {
        modelDownloaderRepository.queueDownloads(
          state.selectedAiCapabilities.toList(),
        );
      }

      await onboardingRepository.setCompletedOnboarding(true);
      emit(state.copyWith(isSaving: false, isFinished: true));
    } catch (_) {
      emit(state.copyWith(isSaving: false));
    }
  }
}
