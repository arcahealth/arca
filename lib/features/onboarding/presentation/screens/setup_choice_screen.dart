import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:arca/core/design_system/arca_design_system.dart';
import 'package:arca/core/widgets/widgets.dart';

/// Screen allowing the user to choose between automatic document extraction or manual entry.
///
/// Emphasizes on-device privacy guarantee and forwards selection via [onChooseAuto]
/// and [onChooseManual]. Follows Swiss typographic minimalism with clean cards and
/// thumb-reachable bottom navigation.
class const SetupChoiceScreen({
  required final VoidCallback onChooseAuto,
  required final VoidCallback onChooseManual,
  super.key,
  final VoidCallback? onBack,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ArcaScaffold(
      bottomBar: NullableBuilder(
        onBack,
        builder: (context, back) => ArcaBottomBar(
          leading: ArcaButton(
            label: 'Back',
            leadingIcon: const PhosphorIcon(
              PhosphorIconsBold.arrowLeft,
              size: 18,
            ),
            variant: .secondary,
            semanticsLabel: 'Go back to welcome screen',
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
                    'SETUP METHOD',
                    style: ArcaTypography.label.copyWith(
                      color: ArcaColors.textMuted,
                    ),
                  ),
                ],
              ),
              const ArcaDivider(
                margin: EdgeInsets.symmetric(vertical: ArcaSpacing.md),
              ),
              const Text('Choose Setup Mode', style: ArcaTypography.display),
              const SizedBox(height: ArcaSpacing.xs),
              Text(
                'All extraction and encryption runs locally on this device. No data leaves your hardware.',
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
                    const Row(
                      children: [
                        PhosphorIcon(
                          PhosphorIconsBold.scan,
                          size: 22,
                          color: ArcaColors.textPrimary,
                        ),
                        SizedBox(width: ArcaSpacing.sm),
                        Expanded(
                          child: Text(
                            'Automatic Extraction',
                            style: ArcaTypography.titleMedium,
                          ),
                        ),
                        ArcaBadge(label: 'Recommended', variant: .normal),
                      ],
                    ),
                    const SizedBox(height: ArcaSpacing.sm),
                    const Text(
                      'Scan a prescription or lab report. Details are parsed automatically into your vault.',
                      style: ArcaTypography.bodyMedium,
                    ),
                    const SizedBox(height: ArcaSpacing.md),
                    ArcaButton(
                      label: 'Scan Document',
                      trailingIcon: const PhosphorIcon(
                        PhosphorIconsBold.arrowRight,
                        size: 18,
                      ),
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
                    const Row(
                      children: [
                        PhosphorIcon(
                          PhosphorIconsBold.pencilSimple,
                          size: 22,
                          color: ArcaColors.textPrimary,
                        ),
                        SizedBox(width: ArcaSpacing.sm),
                        Expanded(
                          child: Text(
                            'Manual Setup',
                            style: ArcaTypography.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: ArcaSpacing.sm),
                    const Text(
                      'Enter your name and details directly via text input or voice dictation.',
                      style: ArcaTypography.bodyMedium,
                    ),
                    const SizedBox(height: ArcaSpacing.md),
                    ArcaButton(
                      label: 'Enter Manually',
                      trailingIcon: const PhosphorIcon(
                        PhosphorIconsBold.arrowRight,
                        size: 18,
                      ),
                      variant: .secondary,
                      semanticsLabel: 'Choose manual profile entry setup',
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
