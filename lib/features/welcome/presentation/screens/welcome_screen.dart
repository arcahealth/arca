import 'package:flutter/widgets.dart';

import '../../../../core/design_system/arca_design_system.dart';

/// First-launch introduction screen introducing Arca's on-device privacy guarantee.
///
/// Completely self-contained: forwards user intents purely through constructor
/// callbacks [onStartSetup] and [onSkip] without dependencies on other features or routes.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, this.onStartSetup, this.onSkip});

  final VoidCallback? onStartSetup;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return ArcaScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: ArcaSpacing.lg,
          vertical: ArcaSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: ArcaSpacing.xl),
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
                alignment: Alignment.center,
                child: const Text(
                  'A',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: ArcaColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: ArcaSpacing.lg),
            const Text(
              'Welcome to Arca',
              style: ArcaTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ArcaSpacing.xs),
            Text(
              'Automated Records & Clinical Archive\nProcessed entirely on your device.',
              style: ArcaTypography.bodyMedium.copyWith(
                color: ArcaColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ArcaSpacing.xl),
            _buildFeaturePillar(
              icon: '🔒',
              title: '100% On-Device & Private',
              description: 'Zero cloud servers or remote accounts. Encrypted SQLite database stays strictly on your hardware.',
            ),
            const SizedBox(height: ArcaSpacing.md),
            _buildFeaturePillar(
              icon: '🛡️',
              title: 'Isolated Family Health Vaults',
              description: 'Dedicated vaults for yourself, children, and parents with independent export and encryption.',
            ),
            const SizedBox(height: ArcaSpacing.md),
            _buildFeaturePillar(
              icon: '⚡',
              title: 'Edge AI Intelligence',
              description: 'Local OCR lab parsing and clinical voice dictation without streaming audio or photos outside.',
            ),
            const SizedBox(height: ArcaSpacing.xxl),
            ArcaButton(
              label: 'Start Setup Wizard →',
              variant: ArcaButtonVariant.primary,
              semanticsLabel: 'Begin initial Arca setup wizard',
              onPressed: onStartSetup,
            ),
            const SizedBox(height: ArcaSpacing.sm),
            ArcaButton(
              label: 'Skip Setup & Quick Start',
              variant: ArcaButtonVariant.ghost,
              semanticsLabel: 'Skip onboarding and enter Arca',
              onPressed: onSkip,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturePillar({
    required String icon,
    required String title,
    required String description,
  }) {
    return ArcaCard(
      padding: const EdgeInsets.all(ArcaSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: ArcaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ArcaTypography.titleMedium.copyWith(fontSize: 15),
                ),
                const SizedBox(height: ArcaSpacing.xxs),
                Text(
                  description,
                  style: ArcaTypography.caption.copyWith(
                    color: ArcaColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
