import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:arca/core/capture/capture.dart';

void main() {
  group('DefaultDocumentCaptureService Tests', () {
    test('scanDocument returns DocumentCaptureSuccess on non-empty results', () async {
      final service = DefaultDocumentCaptureService(
        ({noOfPages = 100, scannerSource = ScannerSource.camera, output = ScanOutput.images}) async {
          return const ScanResult(images: ['/tmp/page1.jpg', '/tmp/page2.jpg']);
        },
      );

      final result = await service.scanDocument();
      expect(result, isA<DocumentCaptureSuccess>());
      final success = result as DocumentCaptureSuccess;
      expect(success.filePaths, ['/tmp/page1.jpg', '/tmp/page2.jpg']);
      expect(success.firstFilePath, '/tmp/page1.jpg');
    });

    test('scanDocument returns DocumentCaptureCanceled when scanner returns null', () async {
      final service = DefaultDocumentCaptureService(
        ({noOfPages = 100, scannerSource = ScannerSource.camera, output = ScanOutput.images}) async {
          return null;
        },
      );

      final result = await service.scanDocument();
      expect(result, isA<DocumentCaptureCanceled>());
    });

    test('scanDocument returns DocumentCaptureCanceled when scanner returns empty images', () async {
      final service = DefaultDocumentCaptureService(
        ({noOfPages = 100, scannerSource = ScannerSource.camera, output = ScanOutput.images}) async {
          return const ScanResult(images: []);
        },
      );

      final result = await service.scanDocument();
      expect(result, isA<DocumentCaptureCanceled>());
    });

    test('scanDocument maps permission_denied exception to permissionDenied', () async {
      final service = DefaultDocumentCaptureService(
        ({noOfPages = 100, scannerSource = ScannerSource.camera, output = ScanOutput.images}) async {
          throw const CunningDocumentScannerException.permissionDenied(
            'Camera permission is required',
          );
        },
      );

      final result = await service.scanDocument();
      expect(result, isA<DocumentCaptureError>());
      final error = result as DocumentCaptureError;
      expect(error.failure, isA<DocumentCapturePermissionDenied>());
      final failure = error.failure as DocumentCapturePermissionDenied;
      expect(failure.message, 'Camera permission is required');
    });

    test('scanDocument maps PlatformException permission error to permissionDenied', () async {
      final service = DefaultDocumentCaptureService(
        ({noOfPages = 100, scannerSource = ScannerSource.camera, output = ScanOutput.images}) async {
          throw PlatformException(
            code: 'camera_access_denied',
            message: 'Camera permission denied',
          );
        },
      );

      final result = await service.scanDocument();
      expect(result, isA<DocumentCaptureError>());
      final error = result as DocumentCaptureError;
      expect(error.failure, isA<DocumentCapturePermissionDenied>());
    });

    test('scanDocument maps general exception to unknown error', () async {
      final service = DefaultDocumentCaptureService(
        ({noOfPages = 100, scannerSource = ScannerSource.camera, output = ScanOutput.images}) async {
          throw StateError('Scanner crash');
        },
      );

      final result = await service.scanDocument();
      expect(result, isA<DocumentCaptureError>());
      final error = result as DocumentCaptureError;
      expect(error.failure, isA<DocumentCaptureUnknownError>());
    });

    test('capturePhoto returns DocumentCaptureSuccess when XFile returned', () async {
      final service = DefaultDocumentCaptureService(
        null,
        ({required source}) async {
          expect(source, ImageSource.camera);
          return XFile('/tmp/photo.jpg');
        },
      );

      final result = await service.capturePhoto();
      expect(result, isA<DocumentCaptureSuccess>());
      final success = result as DocumentCaptureSuccess;
      expect(success.filePaths, ['/tmp/photo.jpg']);
      expect(success.firstFilePath, '/tmp/photo.jpg');
    });

    test('capturePhoto returns DocumentCaptureCanceled when user cancels', () async {
      final service = DefaultDocumentCaptureService(
        null,
        ({required source}) async => null,
      );

      final result = await service.capturePhoto();
      expect(result, isA<DocumentCaptureCanceled>());
    });

    test('capturePhoto maps permission error to permissionDenied', () async {
      final service = DefaultDocumentCaptureService(
        null,
        ({required source}) async {
          throw PlatformException(
            code: 'camera_access_denied',
            message: 'User denied camera',
          );
        },
      );

      final result = await service.capturePhoto();
      expect(result, isA<DocumentCaptureError>());
      final error = result as DocumentCaptureError;
      expect(error.failure, isA<DocumentCapturePermissionDenied>());
    });

    test('pickImage returns DocumentCaptureSuccess when XFile selected', () async {
      final service = DefaultDocumentCaptureService(
        null,
        ({required source}) async {
          expect(source, ImageSource.gallery);
          return XFile('/tmp/gallery_photo.png');
        },
      );

      final result = await service.pickImage();
      expect(result, isA<DocumentCaptureSuccess>());
      final success = result as DocumentCaptureSuccess;
      expect(success.filePaths, ['/tmp/gallery_photo.png']);
    });

    test('pickImage returns DocumentCaptureCanceled on cancel', () async {
      final service = DefaultDocumentCaptureService(
        null,
        ({required source}) async => null,
      );

      final result = await service.pickImage();
      expect(result, isA<DocumentCaptureCanceled>());
    });

    test('capture routes correctly by DocumentCaptureSource', () async {
      var scanCount = 0;
      var photoCount = 0;
      var galleryCount = 0;

      final service = DefaultDocumentCaptureService(
        ({noOfPages = 100, scannerSource = ScannerSource.camera, output = ScanOutput.images}) async {
          scanCount++;
          return const ScanResult(images: ['/tmp/scanned.jpg']);
        },
        ({required source}) async {
          if (source == ImageSource.camera) photoCount++;
          if (source == ImageSource.gallery) galleryCount++;
          return XFile('/tmp/picked.jpg');
        },
      );

      await service.capture(source: DocumentCaptureSource.documentScan);
      expect(scanCount, 1);

      await service.capture(source: DocumentCaptureSource.camera);
      expect(photoCount, 1);

      await service.capture(source: DocumentCaptureSource.gallery);
      expect(galleryCount, 1);
    });

    test('DocumentCaptureService.wire is registered and constructs service', () {
      final wire = DocumentCaptureService.wire;
      expect(wire, isNotNull);
    });
  });
}
