import 'package:circuitry_flutter/circuitry_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:arca/core/capture/capture.dart';
import 'package:arca/core/design_system/arca_design_system.dart';

/// Document capture viewfinder screen for prescription or lab report scanning.
///
/// Supports native document scanning with edge detection, direct camera photo
/// capture, and photo gallery selection.
class DocumentScanScreen extends StatefulWidget {
  const DocumentScanScreen({
    required this.onCapture,
    required this.onSwitchToManual,
    super.key,
    this.captureService,
    this.onImagesCaptured,
    this.onBack,
  });

  final VoidCallback onCapture;
  final VoidCallback onSwitchToManual;
  final DocumentCaptureService? captureService;
  final ValueChanged<List<String>>? onImagesCaptured;
  final VoidCallback? onBack;

  @override
  State<DocumentScanScreen> createState() => _DocumentScanScreenState();
}

class _DocumentScanScreenState extends State<DocumentScanScreen> {
  bool _isCapturing = false;
  String? _errorMessage;
  List<String> _capturedPaths = const [];

  DocumentCaptureService _resolveCaptureService() =>
      widget.captureService ??
      CircuitProvider.maybeOf(context)?.get<DocumentCaptureService>() ??
      DefaultDocumentCaptureService();

  Future<void> _handleCapture(DocumentCaptureSource source) async {
    setState(() {
      _isCapturing = true;
      _errorMessage = null;
    });

    try {
      final service = _resolveCaptureService();
      final result = await service.capture(source: source);
      if (!mounted) return;

      switch (result) {
        case DocumentCaptureSuccess(:final filePaths):
          setState(() {
            _capturedPaths = filePaths;
            _isCapturing = false;
          });
          widget.onImagesCaptured?.call(filePaths);
        case DocumentCaptureCanceled():
          setState(() {
            _isCapturing = false;
          });
        case DocumentCaptureError(:final failure):
          setState(() {
            _isCapturing = false;
            _errorMessage = switch (failure) {
              DocumentCapturePermissionDenied(:final message) =>
                message ?? 'Permission denied. Please allow camera or photo library access in Settings.',
              DocumentCaptureUnsupported(:final message) =>
                message ?? 'This capture capability is not supported on this device.',
              DocumentCaptureUnknownError(:final message) => message,
            };
          });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCaptured = _capturedPaths.isNotEmpty;

    return ArcaScaffold(
      bottomBar: ArcaBottomBar(
        leading: widget.onBack != null
            ? ArcaButton(
                label: 'Back',
                leadingIcon: const PhosphorIcon(
                  PhosphorIconsBold.arrowLeft,
                  size: 18,
                ),
                variant: .secondary,
                semanticsLabel: 'Go back',
                onPressed: widget.onBack,
              )
            : ArcaButton(
                label: 'Enter Details Manually Instead',
                variant: .ghost,
                semanticsLabel: 'Switch to manual profile entry flow',
                onPressed: widget.onSwitchToManual,
              ),
        trailing: ArcaButton(
          label: hasCaptured ? 'Proceed to Review' : 'Capture & Extract Details',
          trailingIcon: const PhosphorIcon(
            PhosphorIconsBold.arrowRight,
            size: 18,
          ),
          variant: .primary,
          semanticsLabel: 'Capture document and extract health details',
          onPressed: () {
            if (hasCaptured) {
              widget.onImagesCaptured?.call(_capturedPaths);
            }
            widget.onCapture();
          },
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
                'Scan your prescription or lab summary using native document scanning, camera, or gallery. Details are extracted 100% on-device.',
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
                      color: hasCaptured ? ArcaColors.success : ArcaColors.borderSubtle,
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(ArcaSpacing.md),
                      child: Column(
                        mainAxisSize: .min,
                        children: [
                          if (_isCapturing) ...[
                            const PhosphorIcon(
                              PhosphorIconsBold.scan,
                              size: 40,
                              color: ArcaColors.primary,
                            ),
                            const SizedBox(height: ArcaSpacing.md),
                            const Text(
                              'Launching Scanner...',
                              style: ArcaTypography.titleMedium,
                            ),
                            const SizedBox(height: ArcaSpacing.xs),
                            const Text(
                              'Please wait while the scanner opens',
                              style: ArcaTypography.caption,
                            ),
                            const SizedBox(height: ArcaSpacing.md),
                            const ArcaBadge(
                              label: 'Scanning',
                              variant: .info,
                            ),
                          ] else if (hasCaptured) ...[
                            const PhosphorIcon(
                              PhosphorIconsBold.checkCircle,
                              size: 40,
                              color: ArcaColors.success,
                            ),
                            const SizedBox(height: ArcaSpacing.md),
                            Text(
                              '${_capturedPaths.length} Document Page(s) Selected',
                              style: ArcaTypography.titleMedium,
                              textAlign: .center,
                            ),
                            const SizedBox(height: ArcaSpacing.xs),
                            Text(
                              _capturedPaths.first.split('/').last,
                              style: ArcaTypography.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: ArcaSpacing.md),
                            const ArcaBadge(
                              label: 'Ready for OCR',
                              variant: .normal,
                            ),
                          ] else ...[
                            const PhosphorIcon(
                              PhosphorIconsBold.fileText,
                              size: 40,
                              color: ArcaColors.textPrimary,
                            ),
                            const SizedBox(height: ArcaSpacing.md),
                            const Text(
                              'Align document within frame',
                              style: ArcaTypography.titleMedium,
                            ),
                            const SizedBox(height: ArcaSpacing.xs),
                            const Text(
                              'Ensure adequate lighting & readable text',
                              style: ArcaTypography.caption,
                            ),
                            const SizedBox(height: ArcaSpacing.md),
                            const ArcaBadge(
                              label: 'Bundled RapidOCR',
                              variant: .normal,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: ArcaSpacing.md),
                ArcaCard(
                  borderColor: ArcaColors.warning,
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      const ArcaBadge(
                        label: 'Action Required',
                        variant: .warning,
                      ),
                      const SizedBox(height: ArcaSpacing.xs),
                      Text(
                        _errorMessage!,
                        style: ArcaTypography.bodyMedium.copyWith(
                          color: ArcaColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: ArcaSpacing.lg),
              ArcaButton(
                label: 'Start Document Scan',
                leadingIcon: const PhosphorIcon(
                  PhosphorIconsBold.scan,
                  size: 20,
                ),
                variant: .primary,
                semanticsLabel: 'Scan document using native scanner',
                onPressed: _isCapturing ? null : () => _handleCapture(DocumentCaptureSource.documentScan),
              ),
              const SizedBox(height: ArcaSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: ArcaButton(
                      label: 'Take Photo',
                      leadingIcon: const PhosphorIcon(
                        PhosphorIconsBold.camera,
                        size: 18,
                      ),
                      variant: .secondary,
                      semanticsLabel: 'Capture photo with camera',
                      onPressed: _isCapturing ? null : () => _handleCapture(DocumentCaptureSource.camera),
                    ),
                  ),
                  const SizedBox(width: ArcaSpacing.sm),
                  Expanded(
                    child: ArcaButton(
                      label: 'Choose from Gallery',
                      leadingIcon: const PhosphorIcon(
                        PhosphorIconsBold.images,
                        size: 18,
                      ),
                      variant: .secondary,
                      semanticsLabel: 'Choose document image from gallery',
                      onPressed: _isCapturing ? null : () => _handleCapture(DocumentCaptureSource.gallery),
                    ),
                  ),
                ],
              ),
              if (widget.onBack != null) ...[
                const SizedBox(height: ArcaSpacing.lg),
                ArcaButton(
                  label: 'Enter Details Manually Instead',
                  variant: .ghost,
                  semanticsLabel: 'Switch to manual profile entry flow',
                  onPressed: widget.onSwitchToManual,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
