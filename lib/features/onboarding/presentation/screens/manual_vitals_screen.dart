import 'package:flutter/widgets.dart';

import '../../../../core/design_system/arca_design_system.dart';

/// Optional vitals and baseline health information screen in the manual onboarding flow.
///
/// Collects optional date of birth, blood type, and known allergies with skip affordances.
class const ManualVitalsScreen({
  required final VoidCallback onFinish,
  super.key,
  final VoidCallback? onSkip,
  final VoidCallback? onBack,
  final String? initialDob,
  final String? initialBloodType,
  final String? initialAllergies,
}) extends StatefulWidget {
  @override
  State<ManualVitalsScreen> createState() => _ManualVitalsScreenState();
}

class _ManualVitalsScreenState extends State<ManualVitalsScreen> {
  late final TextEditingController _dobController;
  late final TextEditingController _bloodTypeController;
  late final TextEditingController _allergiesController;

  @override
  void initState() {
    super.initState();
    _dobController = TextEditingController(text: widget.initialDob ?? '');
    _bloodTypeController = TextEditingController(
      text: widget.initialBloodType ?? '',
    );
    _allergiesController = TextEditingController(
      text: widget.initialAllergies ?? '',
    );
  }

  @override
  void dispose() {
    _dobController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ArcaScaffold(
      header: ArcaHeader(
        title: 'Vitals',
        leading: widget.onBack != null
            ? ArcaButton(
                label: '←',
                variant: .ghost,
                semanticsLabel: 'Go back',
                onPressed: widget.onBack,
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
              const Text('Basic Vitals', style: ArcaTypography.display),
              const SizedBox(height: ArcaSpacing.xs),
              Text(
                'Optional baseline info to contextualize lab results and reference ranges. You can edit this anytime.',
                style: ArcaTypography.bodyLarge.copyWith(
                  color: ArcaColors.textSecondary,
                ),
              ),
              const SizedBox(height: ArcaSpacing.xl),
              ArcaTextField(
                controller: _dobController,
                label: 'Date of Birth (YYYY-MM-DD)',
                hintText: 'e.g. 1990-05-14',
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: ArcaSpacing.md),
              ArcaTextField(
                controller: _bloodTypeController,
                label: 'Blood Type',
                hintText: 'e.g. O+, A+, B-',
              ),
              const SizedBox(height: ArcaSpacing.md),
              ArcaTextField(
                controller: _allergiesController,
                label: 'Known Allergies or Reactions',
                hintText: 'e.g. Penicillin, Peanuts, None',
              ),
              const SizedBox(height: ArcaSpacing.xxl),
              ArcaButton(
                label: 'Complete Setup & Create Vault →',
                variant: .primary,
                semanticsLabel: 'Complete onboarding and create health vault',
                onPressed: widget.onFinish,
              ),
              if (widget.onSkip != null) ...[
                const SizedBox(height: ArcaSpacing.sm),
                ArcaButton(
                  label: 'Skip for Now',
                  variant: .ghost,
                  semanticsLabel: 'Skip vitals and enter health vault',
                  onPressed: widget.onSkip,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
