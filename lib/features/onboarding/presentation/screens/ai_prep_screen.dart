import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:arca/core/design_system/arca_design_system.dart';
import 'package:arca/core/widgets/widgets.dart';

/// Screen displaying the status of on-device AI features before scanning.
///
/// Communicates local privacy guarantees and forwards to the document scan viewfinder via [onReady].
class const AiPrepScreen({
  required final VoidCallback onReady,
  super.key,
  final VoidCallback? onBack,
}) extends StatelessWidget {
  Widget _buildAiComponentStatus({
    required String title,
    required String description,
    required String badgeLabel,
    required ArcaBadgeVariant badgeVariant,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ArcaSpacing.xs),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(title, style: ArcaTypography.titleMedium),
                const SizedBox(height: ArcaSpacing.xxs),
                Text(description, style: ArcaTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: ArcaSpacing.sm),
          ArcaBadge(label: badgeLabel, variant: badgeVariant),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ArcaScaffold(
      header: ArcaHeader(
        title: 'Device Readiness',
        leading: NullableBuilder(
          onBack,
          builder: (context, back) => ArcaButton(
            label: 'Back',
            icon: const PhosphorIcon(PhosphorIconsBold.arrowLeft, size: 16),
            variant: .ghost,
            semanticsLabel: 'Go back to setup choice',
            onPressed: back,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: ArcaSpacing.lg,
            vertical: ArcaSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              const Text(
                'On-Device Intelligence',
                style: ArcaTypography.display,
              ),
              const SizedBox(height: ArcaSpacing.xs),
              Text(
                'Arca initializes local models directly on your hardware. Document text, images, and clinical metrics are never transmitted off-device.',
                style: ArcaTypography.bodyLarge.copyWith(
                  color: ArcaColors.textSecondary,
                ),
              ),
              const SizedBox(height: ArcaSpacing.lg),
              const ArcaProgressBar(
                value: 1.0,
                semanticsLabel: 'AI models ready',
              ),
              const SizedBox(height: ArcaSpacing.xl),
              ArcaCard(
                padding: const EdgeInsets.all(ArcaSpacing.lg),
                child: Column(
                  children: [
                    _buildAiComponentStatus(
                      title: 'Local OCR Engine',
                      description: 'On-device text recognition for prescriptions & reports',
                      badgeLabel: 'Ready',
                      badgeVariant: .normal,
                    ),
                    const SizedBox(height: ArcaSpacing.sm),
                    _buildAiComponentStatus(
                      title: 'Clinical Entity Parser',
                      description:
                          'Identifies biometric values, dosages, and dates',
                      badgeLabel: 'Active',
                      badgeVariant: .normal,
                    ),
                    const SizedBox(height: ArcaSpacing.sm),
                    _buildAiComponentStatus(
                      title: 'Hardware Vault Encryption',
                      description:
                          'Local SQLite database encrypted with hardware key',
                      badgeLabel: 'Active',
                      badgeVariant: .normal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ArcaSpacing.xxl),
              ArcaButton(
                label: 'Proceed to Document Capture',
                icon: const PhosphorIcon(
                  PhosphorIconsBold.arrowRight,
                  size: 18,
                ),
                variant: .primary,
                semanticsLabel: 'Proceed to document scan viewfinder',
                onPressed: onReady,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
