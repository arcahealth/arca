import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

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
          onBack,
          builder: (context, back) => ArcaButton(
            label: 'Back',
            icon: const PhosphorIcon(PhosphorIconsBold.arrowLeft, size: 16),
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
                    color: ArcaColors.surface,
                    borderRadius: ArcaRadii.none,
                    border: Border.all(color: ArcaColors.border, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: ArcaColors.borderSubtle,
                        offset: Offset(4.0, 4.0),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: .min,
                      children: [
                        PhosphorIcon(
                          PhosphorIconsBold.fileText,
                          size: 40,
                          color: ArcaColors.textPrimary,
                        ),
                        SizedBox(height: ArcaSpacing.md),
                        Text(
                          'Align document within frame',
                          style: ArcaTypography.titleMedium,
                        ),
                        SizedBox(height: ArcaSpacing.xs),
                        Text(
                          'Ensure adequate lighting & readable text',
                          style: ArcaTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: ArcaSpacing.xl),
              ArcaButton(
                label: 'Capture & Extract Details',
                icon: const PhosphorIcon(
                  PhosphorIconsBold.arrowRight,
                  size: 18,
                ),
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
