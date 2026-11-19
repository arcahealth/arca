import 'dart:async';

import 'package:circuitry_flutter/circuitry_flutter.dart';

import 'default_document_capture_service.dart';

/// Source selection for capturing health documents or images.
enum DocumentCaptureSource {
  /// Native document scanner with edge detection and perspective deskewing.
  documentScan,

  /// Direct camera photo snapshot.
  camera,

  /// Image selection from photo gallery or files.
  gallery,
}

/// Sealed result returned by document and image capture operations.
sealed class const DocumentCaptureResult() {
  const factory DocumentCaptureResult.success(List<String> filePaths) = DocumentCaptureSuccess;
  const factory DocumentCaptureResult.canceled() = DocumentCaptureCanceled;
  const factory DocumentCaptureResult.failure(DocumentCaptureFailure failure) = DocumentCaptureError;
}

/// Capture succeeded with one or more physical file paths.
final class const DocumentCaptureSuccess(final List<String> filePaths) extends DocumentCaptureResult {
  /// First captured file path, or null if empty.
  String? get firstFilePath => filePaths.isEmpty ? null : filePaths.first;
}

/// Capture was canceled by the user without producing files.
final class const DocumentCaptureCanceled() extends DocumentCaptureResult;

/// Capture failed due to a platform, permission, or hardware error.
final class const DocumentCaptureError(final DocumentCaptureFailure failure) extends DocumentCaptureResult;

/// Typed failure categories for document and image capture.
sealed class const DocumentCaptureFailure() {
  const factory DocumentCaptureFailure.permissionDenied([String? message]) = DocumentCapturePermissionDenied;
  const factory DocumentCaptureFailure.unsupported([String? message]) = DocumentCaptureUnsupported;
  const factory DocumentCaptureFailure.unknown(String message) = DocumentCaptureUnknownError;
}

/// Camera or photo library permission was denied by the user or OS.
final class const DocumentCapturePermissionDenied([final String? message]) extends DocumentCaptureFailure;

/// Requested capture capability is not supported on this platform/device.
final class const DocumentCaptureUnsupported([final String? message]) extends DocumentCaptureFailure;

/// Unknown or unexpected exception during capture.
final class const DocumentCaptureUnknownError(final String message) extends DocumentCaptureFailure;

/// Abstract interface for scanning documents, capturing photos, and selecting images.
abstract interface class DocumentCaptureService {
  /// Declarative Circuitry Wire recipe for [DocumentCaptureService].
  static Wire<DocumentCaptureService> get wire => .new(DefaultDocumentCaptureService.new);

  /// Scans physical documents using the platform document scanner (VisionKit / ML Kit).
  Future<DocumentCaptureResult> scanDocument({int maxPages = 100});

  /// Captures a single image via the device camera.
  Future<DocumentCaptureResult> capturePhoto();

  /// Chooses an image from the photo library or gallery.
  Future<DocumentCaptureResult> pickImage();

  /// Captures documents or images from the requested [source].
  Future<DocumentCaptureResult> capture({
    required DocumentCaptureSource source,
    int maxPages = 100,
  });
}
