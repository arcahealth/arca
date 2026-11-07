import '../../../../core/model_downloader/models/ai_model_capability.dart';
import '../../../../core/vault/models/vault.dart';

sealed class SetupWizardEvent {
  const SetupWizardEvent();
}

final class SetupWizardStarted extends SetupWizardEvent {
  const SetupWizardStarted();
}

final class SetupWizardStepChanged extends SetupWizardEvent {
  const SetupWizardStepChanged(this.stepIndex);
  final int stepIndex;
}

final class SetupWizardVaultDraftAdded extends SetupWizardEvent {
  const SetupWizardVaultDraftAdded(this.vault);
  final Vault vault;
}

final class SetupWizardVaultDraftRemoved extends SetupWizardEvent {
  const SetupWizardVaultDraftRemoved(this.vaultId);
  final String vaultId;
}

final class SetupWizardAiCapabilityToggled extends SetupWizardEvent {
  const SetupWizardAiCapabilityToggled(this.type);
  final AiModelCapabilityType type;
}

final class SetupWizardFinishedRequested extends SetupWizardEvent {
  const SetupWizardFinishedRequested();
}
