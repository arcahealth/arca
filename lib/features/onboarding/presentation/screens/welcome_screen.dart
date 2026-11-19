import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:arca/core/design_system/arca_design_system.dart';
import 'package:arca/core/widgets/widgets.dart';

/// Minimal first-launch welcome screen greeting the user.
///
/// Follows Swiss / Neo-brutalist typographic minimalism: bold left-aligned hierarchy,
/// crisp architectural divider rules, and clean, clinical copy.
class const WelcomeScreen({
  super.key,
  final VoidCallback? onStart,
  final VoidCallback? onSkip,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ArcaScaffold(
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
              const SizedBox(height: ArcaSpacing.sm),
              Container(height: 2.0, color: ArcaColors.borderSubtle),
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
              ArcaButton(
                label: 'Get Started',
                icon: const PhosphorIcon(
                  PhosphorIconsBold.arrowRight,
                  size: 18,
                ),
                variant: .primary,
                semanticsLabel: 'Get started with Arca setup',
                onPressed: onStart,
              ),
              NullableBuilder(
                onSkip,
                builder: (context, skip) => Padding(
                  padding: const EdgeInsets.only(top: ArcaSpacing.sm),
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
      ),
    );
  }
}
