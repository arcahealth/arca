import 'package:flutter/widgets.dart';

import '../../../../core/design_system/arca_design_system.dart';

/// Minimal first-launch welcome screen greeting the user.
///
/// Forwards user navigation intent strictly via constructor callbacks [onStart]
/// and [onSkip] without dependencies on other features or router state.
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
              const Spacer(),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: ArcaColors.primarySubtle,
                    borderRadius: ArcaRadii.lg,
                    border: Border.all(
                      color: ArcaColors.primary.withValues(alpha: 0.3),
                      width: 2.0,
                    ),
                  ),
                  alignment: .center,
                  child: const Text(
                    'A',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: .bold,
                      color: ArcaColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: ArcaSpacing.xl),
              const Text(
                'Welcome to Arca',
                style: ArcaTypography.display,
                textAlign: .center,
              ),
              const SizedBox(height: ArcaSpacing.sm),
              Text(
                'Your private, offline-first health vault.\nMedical records, vitals, and family profiles—processed entirely on your device with complete privacy.',
                style: ArcaTypography.bodyLarge.copyWith(
                  color: ArcaColors.textSecondary,
                ),
                textAlign: .center,
              ),
              const Spacer(flex: 2),
              ArcaButton(
                label: 'Get Started →',
                variant: .primary,
                semanticsLabel: 'Get started with Arca setup',
                onPressed: onStart,
              ),
              if (onSkip != null) ...[
                const SizedBox(height: ArcaSpacing.sm),
                ArcaButton(
                  label: 'Skip Setup',
                  variant: .ghost,
                  semanticsLabel: 'Skip onboarding setup and enter Arca',
                  onPressed: onSkip,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
