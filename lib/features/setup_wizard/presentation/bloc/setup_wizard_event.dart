import '../../../../core/model_downloader/models/ai_model_capability.dart';
import '../../../../core/vault/models/vault.dart';

sealed class const SetupWizardEvent();

final class const SetupWizardStarted() extends SetupWizardEvent;

final class const SetupWizardStepChanged(final int stepIndex)
    extends SetupWizardEvent;

final class const SetupWizardVaultDraftAdded(final Vault vault)
    extends SetupWizardEvent;

final class const SetupWizardVaultDraftRemoved(final String vaultId)
    extends SetupWizardEvent;

final class const SetupWizardAiCapabilityToggled(
  final AiModelCapabilityType type,
) extends SetupWizardEvent;

final class const SetupWizardFinishedRequested() extends SetupWizardEvent;
