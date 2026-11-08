import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/arca_design_system.dart';
import '../../../../core/model_downloader/models/ai_model_capability.dart';
import '../../../../core/vault/models/vault.dart';
import '../bloc/setup_wizard_bloc.dart';
import '../bloc/setup_wizard_event.dart';
import '../bloc/setup_wizard_state.dart';

/// Multi-step setup wizard allowing users to configure initial Health Vaults
/// and choose on-device AI capabilities.
///
/// Self-contained: receives constructor callbacks [onBack], [onSkip], and [onComplete]
/// to communicate user actions to the router orchestrator without cross-module leaks.
class const SetupWizardScreen({
  super.key,
  final VoidCallback? onBack,
  final VoidCallback? onSkip,
  final void Function({
    required bool hasSelectedAiModels,
    required int vaultCount,
  })?
  onComplete,
}) extends StatefulWidget {
  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _bloodTypeController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();

  VaultRelationship _selectedRelationship = .self;

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  void _addVaultDraft(BuildContext context) {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final now = DateTime.now();
    final vault = Vault(
      id: 'vault-${now.millisecondsSinceEpoch}',
      name: name,
      relationship: _selectedRelationship,
      dateOfBirth: _dobController.text.trim().isNotEmpty
          ? _dobController.text.trim()
          : null,
      bloodType: _bloodTypeController.text.trim().isNotEmpty
          ? _bloodTypeController.text.trim()
          : null,
      allergies: _allergiesController.text.trim().isNotEmpty
          ? _allergiesController.text.trim()
          : null,
      createdAt: now,
    );

    context.read<SetupWizardBloc>().add(SetupWizardVaultDraftAdded(vault));

    _nameController.clear();
    _dobController.clear();
    _bloodTypeController.clear();
    _allergiesController.clear();
    setState(() {
      _selectedRelationship = .child;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SetupWizardBloc, SetupWizardState>(
      listener: (context, state) {
        if (state.isFinished) {
          widget.onComplete?.call(
            hasSelectedAiModels: state.selectedAiCapabilities.isNotEmpty,
            vaultCount: state.vaultDrafts.length,
          );
        }
      },
      builder: (context, state) {
        final isStepOne = state.currentStep == 0;

        return ArcaScaffold(
          header: ArcaHeader(
            title: isStepOne ? 'Setup Health Vaults' : 'On-Device AI Setup',
            subtitle: isStepOne
                ? 'Step 1 of 2: Create personal or family vaults'
                : 'Step 2 of 2: Select privacy-first local models',
            leading: ArcaButton(
              label: '← Back',
              variant: .ghost,
              semanticsLabel: 'Navigate to previous step',
              onPressed: () {
                if (isStepOne) {
                  widget.onBack?.call();
                } else {
                  context.read<SetupWizardBloc>().add(
                    const SetupWizardStepChanged(0),
                  );
                }
              },
            ),
            trailing: ArcaButton(
              label: 'Skip',
              variant: .ghost,
              semanticsLabel: 'Skip setup step',
              onPressed: widget.onSkip,
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(ArcaSpacing.md),
            child: isStepOne
                ? _buildVaultStep(context, state)
                : _buildAiStep(context, state),
          ),
          bottomBar: Container(
            padding: const EdgeInsets.all(ArcaSpacing.md),
            decoration: const BoxDecoration(
              color: ArcaColors.background,
              border: Border(
                top: BorderSide(color: ArcaColors.borderSubtle, width: 1.0),
              ),
            ),
            child: Row(
              children: [
                if (!isStepOne) ...[
                  Expanded(
                    child: ArcaButton(
                      label: '← Back',
                      variant: .secondary,
                      onPressed: () => context.read<SetupWizardBloc>().add(
                        const SetupWizardStepChanged(0),
                      ),
                    ),
                  ),
                  const SizedBox(width: ArcaSpacing.sm),
                ],
                Expanded(
                  flex: 2,
                  child: ArcaButton(
                    label: isStepOne ? 'Next: AI Setup →' : 'Complete Setup ✓',
                    variant: .primary,
                    isLoading: state.isSaving,
                    onPressed: () {
                      if (isStepOne) {
                        if (_nameController.text.trim().isNotEmpty) {
                          _addVaultDraft(context);
                        }
                        context.read<SetupWizardBloc>().add(
                          const SetupWizardStepChanged(1),
                        );
                      } else {
                        context.read<SetupWizardBloc>().add(
                          const SetupWizardFinishedRequested(),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVaultStep(BuildContext context, SetupWizardState state) {
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const Text(
          'Personal & Family Health Vaults',
          style: ArcaTypography.titleLarge,
        ),
        const SizedBox(height: ArcaSpacing.xxs),
        Text(
          'Each member receives an isolated, encrypted vault. Create your primary vault now or add family members.',
          style: ArcaTypography.bodyMedium.copyWith(
            color: ArcaColors.textSecondary,
          ),
        ),
        const SizedBox(height: ArcaSpacing.lg),
        if (state.vaultDrafts.isNotEmpty) ...[
          Text(
            'Configured Vaults (${state.vaultDrafts.length})',
            style: ArcaTypography.caption.copyWith(fontWeight: .w600),
          ),
          const SizedBox(height: ArcaSpacing.xs),
          for (final vault in state.vaultDrafts)
            Padding(
              padding: const EdgeInsets.only(bottom: ArcaSpacing.xs),
              child: ArcaCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: ArcaSpacing.md,
                  vertical: ArcaSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Row(
                            children: [
                              Text(
                                vault.name,
                                style: ArcaTypography.titleMedium.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: ArcaSpacing.xs),
                              ArcaBadge(
                                label: vault.relationship.name.toUpperCase(),
                                variant: .info,
                              ),
                            ],
                          ),
                          if (vault.bloodType != null ||
                              vault.allergies != null) ...[
                            const SizedBox(height: ArcaSpacing.xxs),
                            Text(
                              [
                                if (vault.bloodType != null)
                                  'Blood: ${vault.bloodType}',
                                if (vault.allergies != null)
                                  'Allergies: ${vault.allergies}',
                              ].join(' • '),
                              style: ArcaTypography.caption,
                            ),
                          ],
                        ],
                      ),
                    ),
                    ArcaButton(
                      label: 'Remove',
                      variant: .ghost,
                      semanticsLabel: 'Remove ${vault.name} vault',
                      onPressed: () => context.read<SetupWizardBloc>().add(
                        SetupWizardVaultDraftRemoved(vault.id),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: ArcaSpacing.md),
        ],
        ArcaCard(
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Text(
                state.vaultDrafts.isEmpty
                    ? 'Create Your Initial Vault'
                    : 'Add Another Family Vault',
                style: ArcaTypography.titleMedium,
              ),
              const SizedBox(height: ArcaSpacing.md),
              ArcaTextField(
                controller: _nameController,
                label: 'Vault / Member Name *',
                hintText: 'e.g. Me (Primary), Leo, Eleanor',
              ),
              const SizedBox(height: ArcaSpacing.sm),
              Text(
                'Relationship',
                style: ArcaTypography.caption.copyWith(
                  color: ArcaColors.textSecondary,
                  fontWeight: .w600,
                ),
              ),
              const SizedBox(height: ArcaSpacing.xxs),
              Wrap(
                spacing: ArcaSpacing.xs,
                runSpacing: ArcaSpacing.xs,
                children: [
                  for (final rel in VaultRelationship.values)
                    GestureDetector(
                      onTap: () => setState(() => _selectedRelationship = rel),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ArcaSpacing.sm,
                          vertical: ArcaSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedRelationship == rel
                              ? ArcaColors.primary
                              : ArcaColors.surfaceElevated,
                          borderRadius: ArcaRadii.pill,
                          border: Border.all(
                            color: _selectedRelationship == rel
                                ? ArcaColors.primary
                                : ArcaColors.border,
                          ),
                        ),
                        child: Text(
                          rel.name.toUpperCase(),
                          style: ArcaTypography.caption.copyWith(
                            color: _selectedRelationship == rel
                                ? ArcaColors.textInverse
                                : ArcaColors.textPrimary,
                            fontWeight: .w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: ArcaSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: ArcaTextField(
                      controller: _bloodTypeController,
                      label: 'Blood Type (Optional)',
                      hintText: 'e.g. O+, A-',
                    ),
                  ),
                  const SizedBox(width: ArcaSpacing.sm),
                  Expanded(
                    child: ArcaTextField(
                      controller: _dobController,
                      label: 'Birth Date (Optional)',
                      hintText: 'YYYY-MM-DD',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ArcaSpacing.sm),
              ArcaTextField(
                controller: _allergiesController,
                label: 'Allergies / Critical Alerts (Optional)',
                hintText: 'e.g. Penicillin, Peanuts',
              ),
              const SizedBox(height: ArcaSpacing.md),
              ArcaButton(
                label: '+ Add to Vault List',
                variant: .secondary,
                semanticsLabel: 'Add vault to setup list',
                onPressed: () => _addVaultDraft(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiStep(BuildContext context, SetupWizardState state) {
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const Text('Edge AI Capabilities', style: ArcaTypography.titleLarge),
        const SizedBox(height: ArcaSpacing.xxs),
        Text(
          'Arca processes records locally with zero external network queries. Choose which capabilities to enable:',
          style: ArcaTypography.bodyMedium.copyWith(
            color: ArcaColors.textSecondary,
          ),
        ),
        const SizedBox(height: ArcaSpacing.lg),
        for (final cap in AiModelCapabilityType.values) ...[
          _buildCapabilityCard(
            context: context,
            type: cap,
            isSelected: state.selectedAiCapabilities.contains(cap),
          ),
          const SizedBox(height: ArcaSpacing.sm),
        ],
        const SizedBox(height: ArcaSpacing.md),
        Container(
          padding: const EdgeInsets.all(ArcaSpacing.md),
          decoration: BoxDecoration(
            color: ArcaColors.surfaceElevated,
            borderRadius: ArcaRadii.md,
            border: Border.all(color: ArcaColors.border),
          ),
          child: Row(
            crossAxisAlignment: .start,
            children: [
              const Text('🔒', style: TextStyle(fontSize: 20)),
              const SizedBox(width: ArcaSpacing.sm),
              Expanded(
                child: Text(
                  'No cloud leakage. Downloaded quantized weights execute strictly on CPU/NPU hardware isolates. You can pause or delete models anytime in Settings.',
                  style: ArcaTypography.caption.copyWith(
                    color: ArcaColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCapabilityCard({
    required BuildContext context,
    required AiModelCapabilityType type,
    required bool isSelected,
  }) {
    return ArcaCard(
      borderColor: isSelected ? ArcaColors.primary : ArcaColors.border,
      backgroundColor: isSelected
          ? ArcaColors.primarySubtle.withValues(alpha: 0.15)
          : ArcaColors.surface,
      onTap: () => context.read<SetupWizardBloc>().add(
        SetupWizardAiCapabilityToggled(type),
      ),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isSelected ? ArcaColors.primary : ArcaColors.surface,
              borderRadius: ArcaRadii.sm,
              border: Border.all(
                color: isSelected ? ArcaColors.primary : ArcaColors.border,
                width: 1.5,
              ),
            ),
            alignment: .center,
            child: isSelected
                ? const Text(
                    '✓',
                    style: TextStyle(
                      color: ArcaColors.textInverse,
                      fontSize: 14,
                      fontWeight: .bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: ArcaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Row(
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        type.name,
                        style: ArcaTypography.titleMedium.copyWith(
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: ArcaSpacing.xs),
                    ArcaBadge(
                      label: type.estimatedSize,
                      variant: isSelected ? .info : .neutral,
                    ),
                  ],
                ),
                const SizedBox(height: ArcaSpacing.xxs),
                Text(
                  type.description,
                  style: ArcaTypography.caption.copyWith(
                    color: ArcaColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
