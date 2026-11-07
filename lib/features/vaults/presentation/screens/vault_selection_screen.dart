import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/arca_design_system.dart';
import '../../../../core/vault/models/vault.dart';
import '../bloc/vault_bloc.dart';
import '../bloc/vault_event.dart';
import '../bloc/vault_state.dart';

/// Screen allowing users to select an active Health Vault or create their first vault
/// if none are currently provisioned (enforcing the vault route guard).
///
/// Self-contained: forwards user selections and creations via constructor callbacks
/// [onVaultSelected] and [onVaultCreated] without cross-module dependencies.
class VaultSelectionScreen extends StatefulWidget {
  const VaultSelectionScreen({
    super.key,
    this.onVaultSelected,
    this.onVaultCreated,
  });

  final ValueChanged<String>? onVaultSelected;
  final ValueChanged<Vault>? onVaultCreated;

  @override
  State<VaultSelectionScreen> createState() => _VaultSelectionScreenState();
}

class _VaultSelectionScreenState extends State<VaultSelectionScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bloodTypeController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  VaultRelationship _selectedRelationship = VaultRelationship.self;
  bool _isCreatingInline = false;

  @override
  void initState() {
    super.initState();
    context.read<VaultBloc>().add(const VaultLoadRequested());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  void _createAndOpenVault(BuildContext context) {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final now = DateTime.now();
    final newVault = Vault(
      id: 'vault-${now.millisecondsSinceEpoch}',
      name: name,
      relationship: _selectedRelationship,
      bloodType: _bloodTypeController.text.trim().isNotEmpty
          ? _bloodTypeController.text.trim()
          : null,
      allergies: _allergiesController.text.trim().isNotEmpty
          ? _allergiesController.text.trim()
          : null,
      createdAt: now,
    );

    context.read<VaultBloc>().add(VaultAdded(newVault));
    widget.onVaultCreated?.call(newVault);
  }

  void _selectAndOpenVault(BuildContext context, Vault vault) {
    context.read<VaultBloc>().add(VaultActiveSwitched(vault.id));
    widget.onVaultSelected?.call(vault.id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VaultBloc, VaultState>(
      builder: (context, state) {
        final vaults = state is VaultLoaded ? state.vaults : <Vault>[];
        final hasVaults = vaults.isNotEmpty;

        return ArcaScaffold(
          header: ArcaHeader(
            title: hasVaults ? 'Select Health Vault' : 'No Vaults Configured',
            subtitle: hasVaults
                ? 'Choose a family member vault to view clinical records'
                : 'A vault is required before accessing clinical features',
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(ArcaSpacing.md),
            child: hasVaults
                ? _buildVaultList(context, vaults)
                : _buildEmptyStateForm(context),
          ),
        );
      },
    );
  }

  Widget _buildEmptyStateForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(ArcaSpacing.md),
          decoration: BoxDecoration(
            color: ArcaColors.warningSubtle,
            borderRadius: ArcaRadii.md,
            border: Border.all(
              color: ArcaColors.warning.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: ArcaSpacing.sm),
              Expanded(
                child: Text(
                  'Arca is an offline-first clinical vault. The application requires at least one health vault to store records, lab results, and vitals.',
                  style: ArcaTypography.caption.copyWith(
                    color: ArcaColors.warning,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ArcaSpacing.lg),
        ArcaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create Your First Health Vault',
                style: ArcaTypography.titleLarge,
              ),
              const SizedBox(height: ArcaSpacing.xs),
              Text(
                'This will be your default clinical vault on this device.',
                style: ArcaTypography.caption.copyWith(
                  color: ArcaColors.textSecondary,
                ),
              ),
              const SizedBox(height: ArcaSpacing.md),
              ArcaTextField(
                controller: _nameController,
                label: 'Vault / Profile Name *',
                hintText: 'e.g. Me (Primary), Sarah, Alex',
              ),
              const SizedBox(height: ArcaSpacing.sm),
              Text(
                'Relationship',
                style: ArcaTypography.caption.copyWith(
                  color: ArcaColors.textSecondary,
                  fontWeight: FontWeight.w600,
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: ArcaSpacing.sm),
              ArcaTextField(
                controller: _bloodTypeController,
                label: 'Blood Type (Optional)',
                hintText: 'e.g. O+, A-, B+',
              ),
              const SizedBox(height: ArcaSpacing.sm),
              ArcaTextField(
                controller: _allergiesController,
                label: 'Allergies / Critical Warnings (Optional)',
                hintText: 'e.g. Sulfa drugs, Penicillin',
              ),
              const SizedBox(height: ArcaSpacing.lg),
              ArcaButton(
                label: 'Create & Open Vault →',
                variant: ArcaButtonVariant.primary,
                semanticsLabel:
                    'Create initial health vault and enter dashboard',
                onPressed: () => _createAndOpenVault(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVaultList(BuildContext context, List<Vault> vaults) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Available Health Vaults', style: ArcaTypography.titleLarge),
        const SizedBox(height: ArcaSpacing.xxs),
        Text(
          'Select a vault to unlock its private timeline and biometric logs.',
          style: ArcaTypography.bodyMedium.copyWith(
            color: ArcaColors.textSecondary,
          ),
        ),
        const SizedBox(height: ArcaSpacing.md),
        for (final vault in vaults) ...[
          ArcaCard(
            onTap: () => _selectAndOpenVault(context, vault),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ArcaColors.primarySubtle,
                    borderRadius: ArcaRadii.md,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    vault.name.isNotEmpty ? vault.name[0].toUpperCase() : 'V',
                    style: ArcaTypography.titleMedium.copyWith(
                      color: ArcaColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: ArcaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              vault.name,
                              style: ArcaTypography.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: ArcaSpacing.xs),
                          ArcaBadge(
                            label: vault.relationship.name.toUpperCase(),
                            variant: ArcaBadgeVariant.info,
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
                const Text(
                  'Open →',
                  style: TextStyle(
                    color: ArcaColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ArcaSpacing.sm),
        ],
        const SizedBox(height: ArcaSpacing.md),
        if (!_isCreatingInline)
          ArcaButton(
            label: '+ Create Additional Vault',
            variant: ArcaButtonVariant.secondary,
            semanticsLabel: 'Create another family vault',
            onPressed: () => setState(() => _isCreatingInline = true),
          )
        else
          ArcaCard(
            backgroundColor: ArcaColors.surfaceElevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add New Family Vault',
                  style: ArcaTypography.titleMedium,
                ),
                const SizedBox(height: ArcaSpacing.sm),
                ArcaTextField(
                  controller: _nameController,
                  label: 'Vault / Member Name *',
                  hintText: 'e.g. Leo, Eleanor',
                ),
                const SizedBox(height: ArcaSpacing.sm),
                ArcaTextField(
                  controller: _bloodTypeController,
                  label: 'Blood Type (Optional)',
                  hintText: 'e.g. O+',
                ),
                const SizedBox(height: ArcaSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: ArcaButton(
                        label: 'Cancel',
                        variant: ArcaButtonVariant.ghost,
                        onPressed: () =>
                            setState(() => _isCreatingInline = false),
                      ),
                    ),
                    const SizedBox(width: ArcaSpacing.sm),
                    Expanded(
                      child: ArcaButton(
                        label: 'Save Vault',
                        variant: ArcaButtonVariant.primary,
                        onPressed: () {
                          _createAndOpenVault(context);
                          setState(() => _isCreatingInline = false);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
