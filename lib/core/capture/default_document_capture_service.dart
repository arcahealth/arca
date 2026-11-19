import 'dart:async';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'document_capture_service.dart';

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

/// Default production implementation of [DocumentCaptureService] using
/// [CunningDocumentScanner] and [ImagePicker].
final class DefaultDocumentCaptureService implements DocumentCaptureService {
  DefaultDocumentCaptureService([
    DocumentScannerLauncher? scannerLauncher,
    ImagePickerLauncher? pickerLauncher,
  ]) : _scannerLauncher = scannerLauncher ?? _defaultScannerLauncher,
       _pickerLauncher = pickerLauncher ?? _defaultPickerLauncher;

  final DocumentScannerLauncher _scannerLauncher;
  final ImagePickerLauncher _pickerLauncher;

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
  Future<DocumentCaptureResult> capture({
    required DocumentCaptureSource source,
    int maxPages = 100,
  }) => switch (source) {
    DocumentCaptureSource.documentScan => scanDocument(maxPages: maxPages),
    DocumentCaptureSource.camera => capturePhoto(),
    DocumentCaptureSource.gallery => pickImage(),
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
