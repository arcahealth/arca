import 'package:flutter/widgets.dart';

import '../../../../core/design_system/arca_design_system.dart';

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
        title: 'Intelligence Prep',
        leading: onBack != null
            ? ArcaButton(
                label: '←',
                variant: .ghost,
                semanticsLabel: 'Go back to setup choice',
                onPressed: onBack,
              )
            : null,
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
                'Arca prepares local models on your device to parse documents privately. No photos, text, or audio ever leave your phone.',
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
                      description: 'On-device text extraction for prescriptions & lab panels',
                      badgeLabel: 'Ready',
                      badgeVariant: .normal,
                    ),
                    const SizedBox(height: ArcaSpacing.sm),
                    _buildAiComponentStatus(
                      title: 'PII Sanitizer & Vault Redactor',
                      description: 'Scrubs sensitive metadata before indexing',
                      badgeLabel: 'Active',
                      badgeVariant: .normal,
                    ),
                    const SizedBox(height: ArcaSpacing.sm),
                    _buildAiComponentStatus(
                      title: 'Clinical Voice ASR',
                      description: 'Offline speech recognition for dictation',
                      badgeLabel: 'Ready',
                      badgeVariant: .normal,
                    ),
                    const SizedBox(height: ArcaSpacing.sm),
                    _buildAiComponentStatus(
                      title: 'Clinical Chat Assistant',
                      description: 'Optional deep clinical reasoning model',
                      badgeLabel: 'Optional',
                      badgeVariant: .neutral,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ArcaSpacing.xxl),
              ArcaButton(
                label: 'Proceed to Document Capture →',
                variant: .primary,
                semanticsLabel: 'Proceed to document capture screen',
                onPressed: onReady,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
