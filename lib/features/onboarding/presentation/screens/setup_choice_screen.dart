import 'package:flutter/widgets.dart';

import '../../../../core/design_system/arca_design_system.dart';

/// Screen allowing the user to choose between automatic document extraction or manual entry.
///
/// Emphasizes on-device privacy guarantee and forwards selection via [onChooseAuto]
/// and [onChooseManual].
class const SetupChoiceScreen({
  required final VoidCallback onChooseAuto,
  required final VoidCallback onChooseManual,
  super.key,
  final VoidCallback? onBack,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ArcaScaffold(
      header: ArcaHeader(
        title: 'Setup',
        leading: onBack != null
            ? ArcaButton(
                label: '←',
                variant: .ghost,
                semanticsLabel: 'Go back to welcome screen',
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
              const Text('Choose Setup Mode', style: ArcaTypography.display),
              const SizedBox(height: ArcaSpacing.xs),
              Text(
                'Everything happens 100% on-device once AI features are ready. No accounts, no cloud servers, and zero data leaves your hardware.',
                style: ArcaTypography.bodyLarge.copyWith(
                  color: ArcaColors.textSecondary,
                ),
              ),
              const SizedBox(height: ArcaSpacing.xl),
              ArcaCard(
                onTap: onChooseAuto,
                padding: const EdgeInsets.all(ArcaSpacing.lg),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Row(
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 22.0)),
                        const SizedBox(width: ArcaSpacing.xs),
                        const Expanded(
                          child: Text(
                            'Automatic Setup',
                            style: ArcaTypography.titleMedium,
                          ),
                        ),
                        const ArcaBadge(label: 'Recommended', variant: .normal),
                      ],
                    ),
                    const SizedBox(height: ArcaSpacing.xs),
                    Text(
                      'Scan a prescription or lab report. On-device AI extracts your name, medications, and details in one step.',
                      style: ArcaTypography.bodyMedium,
                    ),
                    const SizedBox(height: ArcaSpacing.md),
                    ArcaButton(
                      label: 'Scan Document →',
                      variant: .primary,
                      semanticsLabel: 'Choose automatic document scan setup',
                      onPressed: onChooseAuto,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ArcaSpacing.lg),
              ArcaCard(
                onTap: onChooseManual,
                padding: const EdgeInsets.all(ArcaSpacing.lg),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Row(
                      children: [
                        const Text('✍️', style: TextStyle(fontSize: 22.0)),
                        const SizedBox(width: ArcaSpacing.xs),
                        const Expanded(
                          child: Text(
                            'Manual Setup',
                            style: ArcaTypography.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: ArcaSpacing.xs),
                    Text(
                      'Walk through standard profile setup step-by-step. Enter your name and vitals using keyboard or voice dictation.',
                      style: ArcaTypography.bodyMedium,
                    ),
                    const SizedBox(height: ArcaSpacing.md),
                    ArcaButton(
                      label: 'Enter Manually →',
                      variant: .secondary,
                      semanticsLabel: 'Choose manual setup flow',
                      onPressed: onChooseManual,
                    ),
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
