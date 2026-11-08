import 'package:collection/collection.dart';

import '../../../../core/model_downloader/models/ai_model.dart';
import '../../../../core/vault/models/vault.dart';

final class const SetupWizardState({
  final int currentStep = 0,
  final List<Vault> vaultDrafts = const [],
  final Set<ModelKind> selectedAiCapabilities = const {.ocr, .asr},
  final bool isSaving = false,
  final bool isFinished = false,
}) {
  bool get hasSelectedAiCapabilities => selectedAiCapabilities.isNotEmpty;

  SetupWizardState copyWith({
    int? currentStep,
    List<Vault>? vaultDrafts,
    Set<ModelKind>? selectedAiCapabilities,
    bool? isSaving,
    bool? isFinished,
  }) {
    return SetupWizardState(
      currentStep: currentStep ?? this.currentStep,
      vaultDrafts: vaultDrafts ?? this.vaultDrafts,
      selectedAiCapabilities:
          selectedAiCapabilities ?? this.selectedAiCapabilities,
      isSaving: isSaving ?? this.isSaving,
      isFinished: isFinished ?? this.isFinished,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetupWizardState &&
          runtimeType == other.runtimeType &&
          currentStep == other.currentStep &&
          isSaving == other.isSaving &&
          isFinished == other.isFinished &&
          const ListEquality<Vault>().equals(vaultDrafts, other.vaultDrafts) &&
          const SetEquality<ModelKind>().equals(
            selectedAiCapabilities,
            other.selectedAiCapabilities,
          );

  @override
  int get hashCode => Object.hash(
    currentStep,
    isSaving,
    isFinished,
    const ListEquality<Vault>().hash(vaultDrafts),
    const SetEquality<ModelKind>().hash(selectedAiCapabilities),
  );
}
