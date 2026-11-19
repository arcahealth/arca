import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:arca/core/design_system/arca_design_system.dart';
import 'package:arca/core/widgets/widgets.dart';

/// Minimal first-launch welcome screen greeting the user.
///
/// Follows Swiss typographic minimalism: stark left-aligned hierarchy,
/// crisp architectural divider rules, and clean, clinical copy.
/// Provides direct entry points to on-device scan or manual profile setup.
class const WelcomeScreen({
  super.key,
  final VoidCallback? onScan,
  final VoidCallback? onManualEntry,
  final VoidCallback? onStart,
  final VoidCallback? onSkip,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final effectiveScan = onScan ?? onStart;

    return ArcaScaffold(
      bottomBar: ArcaBottomBar(
        showTopDivider: false,
        padding: const EdgeInsets.symmetric(
          horizontal: ArcaSpacing.lg,
          vertical: ArcaSpacing.md,
        ),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            Row(
              children: [
                if (onManualEntry != null) ...[
                  Expanded(
                    child: ArcaButton(
                      label: 'Enter Manually',
                      leadingIcon: const PhosphorIcon(
                        PhosphorIconsBold.pencilSimple,
                        size: 18,
                      ),
                      variant: .secondary,
                      semanticsLabel: 'Enter health details manually',
                      onPressed: onManualEntry,
                    ),
                  ),
                  const SizedBox(width: ArcaSpacing.md),
                ],
                Expanded(
                  child: ArcaButton(
                    label: onManualEntry != null
                        ? 'Scan Document'
                        : 'Get Started',
                    trailingIcon: const PhosphorIcon(
                      PhosphorIconsBold.scan,
                      size: 18,
                    ),
                    variant: .primary,
                    semanticsLabel:
                        'Scan prescription or document with on-device OCR',
                    onPressed: effectiveScan,
                  ),
                ),
              ],
            ),
            NullableBuilder(
              onSkip,
              builder: (context, skip) => Padding(
                padding: const EdgeInsets.only(top: ArcaSpacing.xs),
                child: ArcaButton(
                  label: 'Skip Setup',
                  variant: .ghost,
                  semanticsLabel: 'Skip onboarding setup and enter Arca',
                  onPressed: skip,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
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
                    'HEALTH VAULT',
                    style: ArcaTypography.label.copyWith(
                      color: ArcaColors.textMuted,
                    ),
                  ),
                ],
              ),
              const ArcaDivider(
                margin: EdgeInsets.symmetric(vertical: ArcaSpacing.md),
              ),
              const Spacer(),
              const Text(
                'Your medical records.\nEncrypted on your device.',
                style: ArcaTypography.display,
              ),
              const SizedBox(height: ArcaSpacing.md),
              Text(
                'A private health vault for your clinical records, prescriptions, and vitals. Everything is processed and stored on-device with zero cloud dependencies.',
                style: ArcaTypography.bodyLarge.copyWith(
                  color: ArcaColors.textSecondary,
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
