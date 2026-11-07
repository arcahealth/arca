import '../../../../core/model_downloader/models/ai_model_capability.dart';
import '../../../../core/vault/models/vault.dart';

final class SetupWizardState {
  const SetupWizardState({
    this.currentStep = 0,
    this.vaultDrafts = const [],
    this.selectedAiCapabilities = const {
      AiModelCapabilityType.ocr,
      AiModelCapabilityType.asr,
    },
    this.isSaving = false,
    this.isFinished = false,
  });

  final int currentStep;
  final List<Vault> vaultDrafts;
  final Set<AiModelCapabilityType> selectedAiCapabilities;
  final bool isSaving;
  final bool isFinished;

  bool get hasSelectedAiCapabilities => selectedAiCapabilities.isNotEmpty;

  SetupWizardState copyWith({
    int? currentStep,
    List<Vault>? vaultDrafts,
    Set<AiModelCapabilityType>? selectedAiCapabilities,
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
          _listEquals(vaultDrafts, other.vaultDrafts) &&
          _setEquals(selectedAiCapabilities, other.selectedAiCapabilities);

  @override
  int get hashCode => Object.hash(
    currentStep,
    isSaving,
    isFinished,
    Object.hashAll(vaultDrafts),
    Object.hashAll(selectedAiCapabilities),
  );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}
