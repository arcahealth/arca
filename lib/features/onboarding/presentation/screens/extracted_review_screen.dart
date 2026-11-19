import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:arca/core/design_system/arca_design_system.dart';

/// Overview screen presenting the profile and health records with edit functionality.
///
/// Allows confirming the profile into the vault via [onConfirm] or stepping
/// through the manual inputs via [onEditManually] with prefilled values.
class const ExtractedReviewScreen({
  required final VoidCallback onConfirm,
  required final VoidCallback onEditManually,
  super.key,
  final VoidCallback? onBack,
  final String extractedName = '',
  final String extractedDob = '',
  final String extractedMedication = '',
  final String extractedAllergy = '',
}) extends StatelessWidget {
  Widget _buildFieldRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ArcaSpacing.xs),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(label, style: ArcaTypography.caption),
          const SizedBox(height: ArcaSpacing.xxs),
          Text(
            value.isNotEmpty ? value : '—',
            style: ArcaTypography.titleMedium,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ArcaScaffold(
      bottomBar: ArcaBottomBar(
        leading: ArcaButton(
          label: 'Edit Details Manually',
          leadingIcon: const PhosphorIcon(
            PhosphorIconsBold.pencilSimple,
            size: 18,
          ),
          variant: .secondary,
          semanticsLabel: 'Edit profile fields manually',
          onPressed: onEditManually,
        ),
        trailing: ArcaButton(
          label: 'Confirm & Create Vault',
          trailingIcon: const PhosphorIcon(
            PhosphorIconsBold.arrowRight,
            size: 18,
          ),
          variant: .primary,
          semanticsLabel: 'Confirm profile and create vault',
          onPressed: onConfirm,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: ArcaSpacing.lg,
            vertical: ArcaSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  Text(
                    'ARCA',
                    style: ArcaTypography.label.copyWith(
                      color: ArcaColors.textPrimary,
                    ),
                  ),
                  Text(
                    'VAULT OVERVIEW',
                    style: ArcaTypography.label.copyWith(
                      color: ArcaColors.textMuted,
                    ),
                  ),
                ],
              ),
              const ArcaDivider(
                margin: EdgeInsets.symmetric(vertical: ArcaSpacing.md),
              ),
              const Text('Profile Overview', style: ArcaTypography.display),
              const SizedBox(height: ArcaSpacing.xs),
              Text(
                'Review your profile and health records. You can edit any details or confirm to initialize your encrypted vault.',
                style: ArcaTypography.bodyLarge.copyWith(
                  color: ArcaColors.textSecondary,
                ),
              ),
              const SizedBox(height: ArcaSpacing.xl),
              ArcaCard(
                padding: const EdgeInsets.all(ArcaSpacing.lg),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    const Row(
                      mainAxisAlignment: .spaceBetween,
                      children: [
                        Text(
                          'Profile Information',
                          style: ArcaTypography.titleMedium,
                        ),
                        ArcaBadge(label: '100% On-Device', variant: .normal),
                      ],
                    ),
                    const SizedBox(height: ArcaSpacing.md),
                    _buildFieldRow('Full Name', extractedName),
                    const SizedBox(height: ArcaSpacing.xs),
                    _buildFieldRow('Date of Birth', extractedDob),
                    const SizedBox(height: ArcaSpacing.xs),
                    _buildFieldRow('Medication', extractedMedication),
                    const SizedBox(height: ArcaSpacing.xs),
                    _buildFieldRow('Known Allergy', extractedAllergy),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
