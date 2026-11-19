import 'package:arca/core/capture/capture.dart';

/// Test fake for [DocumentCaptureService].
final class FakeDocumentCaptureService implements DocumentCaptureService {
  FakeDocumentCaptureService({
    this.scanResult = const DocumentCaptureResult.success(['/tmp/scanned_report.jpg']),
    this.photoResult = const DocumentCaptureResult.success(['/tmp/camera_photo.jpg']),
    this.pickResult = const DocumentCaptureResult.success(['/tmp/gallery_photo.png']),
  });

  DocumentCaptureResult scanResult;
  DocumentCaptureResult photoResult;
  DocumentCaptureResult pickResult;

  int scanCalls = 0;
  int photoCalls = 0;
  int pickCalls = 0;

  @override
  Future<DocumentCaptureResult> scanDocument({int maxPages = 100}) async {
    scanCalls++;
    return scanResult;
  }

  @override
  Future<DocumentCaptureResult> capturePhoto() async {
    photoCalls++;
    return photoResult;
  }

  @override
  Future<DocumentCaptureResult> pickImage() async {
    pickCalls++;
    return pickResult;
  }

  @override
  Future<DocumentCaptureResult> capture({
    required DocumentCaptureSource source,
    int maxPages = 100,
  }) => switch (source) {
    DocumentCaptureSource.documentScan => scanDocument(maxPages: maxPages),
    DocumentCaptureSource.camera => capturePhoto(),
    DocumentCaptureSource.gallery => pickImage(),
  };
}
