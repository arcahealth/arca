import 'dart:async';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Source selection for capturing health documents or images.
enum DocumentCaptureSource {
  /// Native document scanner with edge detection and perspective deskewing.
  documentScan,

  /// Direct camera photo snapshot.
  camera,

  /// Image selection from photo gallery.
  gallery,

  /// Document or PDF file selection from file storage.
  files,
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

/// Function signature for launching the platform document scanner.
typedef DocumentScannerLauncher = Future<ScanResult?> Function({
  int noOfPages,
  ScannerSource scannerSource,
  ScanOutput output,
});

/// Function signature for launching the platform image picker or camera.
typedef ImagePickerLauncher = Future<XFile?> Function({
  required ImageSource source,
});

/// Function signature for launching the platform file picker.
typedef FilePickerLauncher = Future<List<PlatformFile>> Function({
  FileType type,
  List<String>? allowedExtensions,
});

/// Abstract interface for scanning documents, capturing photos, and selecting images.
abstract interface class DocumentCaptureService {
  /// Scans physical documents using the platform document scanner (VisionKit / ML Kit).
  Future<DocumentCaptureResult> scanDocument({int maxPages = 100});

  /// Captures a single image via the device camera.
  Future<DocumentCaptureResult> capturePhoto();

  /// Chooses an image from the photo library or gallery.
  Future<DocumentCaptureResult> pickImage();

  /// Allowed file extensions when importing document files via [pickFiles].
  ///
  /// Image-based capture (.jpg, .png) is handled via [capturePhoto], [pickImage],
  /// and [scanDocument].
  static const List<String> allowedFileExtensions = [
    'txt',
    'json',
    'md',
    'csv',
  ];

  /// Chooses document files from storage matching [allowedExtensions].
  Future<DocumentCaptureResult> pickFiles({
    List<String>? allowedExtensions = allowedFileExtensions,
  });

  /// Captures documents or images from the requested [source].
  Future<DocumentCaptureResult> capture({
    required DocumentCaptureSource source,
    int maxPages = 100,
  });
}

/// Default production implementation of [DocumentCaptureService] using
/// [CunningDocumentScanner], [ImagePicker], and [FilePicker].
final class DefaultDocumentCaptureService([
  final DocumentScannerLauncher? scannerLauncher,
  final ImagePickerLauncher? pickerLauncher,
  final FilePickerLauncher? filePickerLauncher,
]) implements DocumentCaptureService {
  this
    : _scannerLauncher = scannerLauncher ?? _defaultScannerLauncher,
      _pickerLauncher = pickerLauncher ?? _defaultPickerLauncher,
      _filePickerLauncher = filePickerLauncher ?? _defaultFilePickerLauncher;

  final DocumentScannerLauncher _scannerLauncher;
  final ImagePickerLauncher _pickerLauncher;
  final FilePickerLauncher _filePickerLauncher;

  static Future<ScanResult?> _defaultScannerLauncher({
    int noOfPages = 100,
    ScannerSource scannerSource = ScannerSource.camera,
    ScanOutput output = ScanOutput.images,
  }) => CunningDocumentScanner.scanDocuments(
    noOfPages: noOfPages,
    scannerSource: scannerSource,
    output: output,
  );

  static Future<XFile?> _defaultPickerLauncher({required ImageSource source}) =>
      ImagePicker().pickImage(source: source);

  static Future<List<PlatformFile>> _defaultFilePickerLauncher({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) => FilePicker.pickFiles(
    type: type,
    allowedExtensions: allowedExtensions,
  );

  @override
  Future<DocumentCaptureResult> scanDocument({int maxPages = 100}) async {
    try {
      final result = await _scannerLauncher(
        noOfPages: maxPages,
        scannerSource: ScannerSource.camera,
        output: ScanOutput.images,
      );
      if (result == null || result.images.isEmpty) {
        return const DocumentCaptureResult.canceled();
      }
      return DocumentCaptureResult.success(result.images);
    } on CunningDocumentScannerException catch (e) {
      if (e.code == 'permission_denied') {
        return DocumentCaptureResult.failure(
          DocumentCaptureFailure.permissionDenied(e.message),
        );
      }
      return DocumentCaptureResult.failure(
        DocumentCaptureFailure.unknown(e.message),
      );
    } on PlatformException catch (e) {
      if (_isPermissionDenied(e)) {
        return DocumentCaptureResult.failure(
          DocumentCaptureFailure.permissionDenied(e.message),
        );
      }
      return DocumentCaptureResult.failure(
        DocumentCaptureFailure.unknown(e.message ?? 'Scanning failed'),
      );
    } catch (e) {
      return DocumentCaptureResult.failure(
        DocumentCaptureFailure.unknown(e.toString()),
      );
    }
  }

  @override
  Future<DocumentCaptureResult> capturePhoto() async {
    try {
      final file = await _pickerLauncher(source: ImageSource.camera);
      if (file == null) {
        return const DocumentCaptureResult.canceled();
      }
      return DocumentCaptureResult.success([file.path]);
    } on PlatformException catch (e) {
      if (_isPermissionDenied(e)) {
        return DocumentCaptureResult.failure(
          DocumentCaptureFailure.permissionDenied(e.message),
        );
      }
      return DocumentCaptureResult.failure(
        DocumentCaptureFailure.unknown(e.message ?? 'Camera capture failed'),
      );
    } catch (e) {
      return DocumentCaptureResult.failure(
        DocumentCaptureFailure.unknown(e.toString()),
      );
    }
  }

  @override
  Future<DocumentCaptureResult> pickImage() async {
    try {
      final file = await _pickerLauncher(source: ImageSource.gallery);
      if (file == null) {
        return const DocumentCaptureResult.canceled();
      }
      return DocumentCaptureResult.success([file.path]);
    } on PlatformException catch (e) {
      if (_isPermissionDenied(e)) {
        return DocumentCaptureResult.failure(
          DocumentCaptureFailure.permissionDenied(e.message),
        );
      }
      return DocumentCaptureResult.failure(
        DocumentCaptureFailure.unknown(e.message ?? 'Photo selection failed'),
      );
    } catch (e) {
      return DocumentCaptureResult.failure(
        DocumentCaptureFailure.unknown(e.toString()),
      );
    }
  }

  @override
  Future<DocumentCaptureResult> pickFiles({
    List<String>? allowedExtensions = DocumentCaptureService.allowedFileExtensions,
  }) async {
    try {
      final files = await _filePickerLauncher(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
      );
      if (files.isEmpty) {
        return const DocumentCaptureResult.canceled();
      }
      final paths = files.map((f) => f.path).whereType<String>().toList();
      if (paths.isEmpty) {
        return const DocumentCaptureResult.canceled();
      }

      // Enforce extension validation in case the platform picker returned non-matching files
      if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
        final validPaths = paths.where((p) {
          final ext = p.split('.').last.toLowerCase();
          return allowedExtensions.contains(ext);
        }).toList();

        if (validPaths.isEmpty) {
          return DocumentCaptureResult.failure(
            DocumentCaptureFailure.unsupported(
              'Unsupported file type selected. Allowed formats: ${allowedExtensions.map((e) => '.$e').join(', ')}.',
            ),
          );
        }
        return DocumentCaptureResult.success(validPaths);
      }

      return DocumentCaptureResult.success(paths);
    } on PlatformException catch (e) {
      if (_isPermissionDenied(e)) {
        return DocumentCaptureResult.failure(
          DocumentCaptureFailure.permissionDenied(e.message),
        );
      }
      return DocumentCaptureResult.failure(
        DocumentCaptureFailure.unknown(e.message ?? 'File selection failed'),
      );
    } catch (e) {
      return DocumentCaptureResult.failure(
        DocumentCaptureFailure.unknown(e.toString()),
      );
    }
  }

  @override
  Future<DocumentCaptureResult> capture({
    required DocumentCaptureSource source,
    int maxPages = 100,
  }) => switch (source) {
    .documentScan => scanDocument(maxPages: maxPages),
    .camera => capturePhoto(),
    .gallery => pickImage(),
    .files => pickFiles(),
  };

  bool _isPermissionDenied(PlatformException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();
    return code.contains('permission') ||
        code.contains('denied') ||
        code == 'camera_access_denied' ||
        code == 'photo_access_denied' ||
        message.contains('permission');
  }
}
