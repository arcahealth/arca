import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:arca/core/design_system/arca_design_system.dart';

/// Document capture viewfinder screen for prescription or lab report scanning.
///
/// Pure UI screen: forwards intent via [onCapture] and [onSwitchToManual]
/// utilizing bundled onnxruntime & RapidOCR on-device models without external download steps.
class const DocumentScanScreen({
  required final VoidCallback onCapture,
  required final VoidCallback onSwitchToManual,
  super.key,
  final VoidCallback? onBack,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ArcaScaffold(
      bottomBar: ArcaBottomBar(
        leading: onBack != null
            ? ArcaButton(
                label: 'Back',
                leadingIcon: const PhosphorIcon(
                  PhosphorIconsBold.arrowLeft,
                  size: 18,
                ),
                variant: .secondary,
                semanticsLabel: 'Go back',
                onPressed: onBack,
              )
            : ArcaButton(
                label: 'Enter Details Manually Instead',
                variant: .ghost,
                semanticsLabel: 'Switch to manual profile entry flow',
                onPressed: onSwitchToManual,
              ),
        trailing: ArcaButton(
          label: 'Capture & Extract Details',
          trailingIcon: const PhosphorIcon(
            PhosphorIconsBold.arrowRight,
            size: 18,
          ),
          variant: .primary,
          semanticsLabel: 'Capture document and extract health details',
          onPressed: onCapture,
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
                    'DOCUMENT SCAN',
                    style: ArcaTypography.label.copyWith(
                      color: ArcaColors.textMuted,
                    ),
                  ),
                ],
              ),
              const ArcaDivider(
                margin: EdgeInsets.symmetric(vertical: ArcaSpacing.md),
              ),
              const Text('Scan Document', style: ArcaTypography.display),
              const SizedBox(height: ArcaSpacing.xs),
              Text(
                'Position your prescription or lab summary inside the frame. Details are extracted instantly using bundled on-device OCR.',
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
                    border: Border.all(
                      color: ArcaColors.borderSubtle,
                      width: 1.0,
                    ),
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
                        SizedBox(height: ArcaSpacing.md),
                        ArcaBadge(label: 'Bundled RapidOCR', variant: .normal),
                      ],
                    ),
                  ),
                ),
              ),
              if (onBack != null) ...[
                const SizedBox(height: ArcaSpacing.lg),
                ArcaButton(
                  label: 'Enter Details Manually Instead',
                  variant: .ghost,
                  semanticsLabel: 'Switch to manual profile entry flow',
                  onPressed: onSwitchToManual,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
