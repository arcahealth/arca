import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:arca/core/design_system/arca_design_system.dart';
import 'package:arca/core/widgets/widgets.dart';

/// Review screen presenting the data extracted from a scanned document.
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
      header: ArcaHeader(
        title: 'Review Data',
        leading: NullableBuilder(
          onBack,
          builder: (context, back) => ArcaButton(
            label: 'Back',
            icon: const PhosphorIcon(PhosphorIconsBold.arrowLeft, size: 16),
            variant: .ghost,
            semanticsLabel: 'Go back to scan screen',
            onPressed: back,
          ),
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
              const Text('Review Profile', style: ArcaTypography.display),
              const SizedBox(height: ArcaSpacing.xs),
              Text(
                'Arca extracted these records directly from your document. You can confirm to build your vault now or adjust any field manually.',
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
                          'Extracted Information',
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
              const SizedBox(height: ArcaSpacing.xxl),
              ArcaButton(
                label: 'Confirm & Create Vault',
                icon: const PhosphorIcon(
                  PhosphorIconsBold.arrowRight,
                  size: 18,
                ),
                variant: .primary,
                semanticsLabel: 'Confirm extracted profile and create vault',
                onPressed: onConfirm,
              ),
              const SizedBox(height: ArcaSpacing.sm),
              ArcaButton(
                label: 'Edit Details Manually',
                variant: .ghost,
                semanticsLabel: 'Edit profile fields manually',
                onPressed: onEditManually,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
