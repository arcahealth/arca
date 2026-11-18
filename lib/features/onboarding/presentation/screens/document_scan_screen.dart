import 'package:flutter/widgets.dart';

import 'package:arca/core/design_system/arca_design_system.dart';
import 'package:arca/core/widgets/widgets.dart';

/// Document capture viewfinder screen for prescription or lab report scanning.
///
/// Pure UI screen: forwards intent via [onCapture] and [onSwitchToManual]
/// without camera platform plugins or mock service calls.
class const DocumentScanScreen({
  required final VoidCallback onCapture,
  required final VoidCallback onSwitchToManual,
  super.key,
  final VoidCallback? onBack,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ArcaScaffold(
      header: ArcaHeader(
        title: 'Document Scan',
        leading: NullableBuilder(
          value: onBack,
          builder: (context, back) => ArcaButton(
            label: '←',
            variant: .ghost,
            semanticsLabel: 'Go back to intelligence prep',
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
              const Text('Scan Document', style: ArcaTypography.display),
              const SizedBox(height: ArcaSpacing.xs),
              Text(
                'Position your prescription or lab summary inside the frame. Details will be extracted automatically on-device.',
                style: ArcaTypography.bodyLarge.copyWith(
                  color: ArcaColors.textSecondary,
                ),
              ),
              const SizedBox(height: ArcaSpacing.lg),
              AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: ArcaColors.surfaceElevated,
                    borderRadius: ArcaRadii.lg,
                    border: Border.all(color: ArcaColors.primary, width: 2.0),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: .min,
                      children: [
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: ArcaColors.primarySubtle,
                              borderRadius: ArcaRadii.md,
                            ),
                            child: Center(
                              child: Text('📄', style: TextStyle(fontSize: 28)),
                            ),
                          ),
                        ),
                        SizedBox(height: ArcaSpacing.md),
                        Text(
                          'Align document within frame',
                          style: ArcaTypography.titleMedium,
                        ),
                        SizedBox(height: ArcaSpacing.xs),
                        Text(
                          'Ensure good lighting & legible text',
                          style: ArcaTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: ArcaSpacing.xl),
              ArcaButton(
                label: 'Capture & Extract Details →',
                variant: .primary,
                semanticsLabel: 'Capture document and extract health details',
                onPressed: onCapture,
              ),
              const SizedBox(height: ArcaSpacing.sm),
              ArcaButton(
                label: 'Enter Details Manually Instead',
                variant: .ghost,
                semanticsLabel: 'Switch to manual profile entry flow',
                onPressed: onSwitchToManual,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
