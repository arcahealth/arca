import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:arca/core/ai/ocr_engine.dart';

void main() {
  group('DefaultOcrEngine Tests', () {
    late DefaultOcrEngine engine;
    late Directory tempDir;

    setUp(() async {
      engine = DefaultOcrEngine();
      tempDir = await Directory.systemTemp.createTemp('arca_ocr_test_');
    });

    tearDown(() async {
      await engine.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('returns empty string when file path does not exist', () async {
      final text = await engine.recognizeText('/non/existent/doc.jpg');
      expect(text, isEmpty);
    });

    test('OcrEngine.isSupported correctly validates file extensions', () {
      expect(OcrEngine.isSupported('notes.txt'), isTrue);
      expect(OcrEngine.isSupported('records.JSON'), isTrue);
      expect(OcrEngine.isSupported('summary.md'), isTrue);
      expect(OcrEngine.isSupported('labs.csv'), isTrue);

      expect(OcrEngine.isSupported('scan.jpg'), isFalse);
      expect(OcrEngine.isSupported('scan.jpeg'), isFalse);
      expect(OcrEngine.isSupported('scan.png'), isFalse);
      expect(OcrEngine.isSupported('doc.pdf'), isFalse);
      expect(OcrEngine.isSupported('file_without_ext'), isFalse);
    });

    test('returns empty string when file is an unsupported format', () async {
      final unsupportedFile = File('${tempDir.path}/report.jpg');
      await unsupportedFile.writeAsString('fake image bytes');

      final text = await engine.recognizeText(unsupportedFile.path);
      expect(text, isEmpty);
    });

    test('extracts text directly from textual files and fixtures', () async {
      final sampleFile = File('${tempDir.path}/clinical_note.txt');
      await sampleFile.writeAsString(
        'Patient Name: Alex Morgan\nDOB: 1988-04-12\nRx: Amoxicillin 500mg',
      );

      final text = await engine.recognizeText(sampleFile.path);
      expect(text, contains('Patient Name: Alex Morgan'));
      expect(text, contains('Rx: Amoxicillin 500mg'));
    });

    test('recognizeAll combines multiple document pages with page breaks', () async {
      final page1 = File('${tempDir.path}/page1.txt');
      await page1.writeAsString('Page 1 Header\nPatient: Jane Doe');

      final page2 = File('${tempDir.path}/page2.txt');
      await page2.writeAsString('Page 2 Details\nAllergies: Penicillin');

      final combined = await engine.recognizeAll([page1.path, page2.path]);
      expect(combined, contains('Page 1 Header'));
      expect(combined, contains('--- Page Break ---'));
      expect(combined, contains('Page 2 Details'));
    });

    test('recognizeAll returns empty string when list is empty', () async {
      final result = await engine.recognizeAll([]);
      expect(result, isEmpty);
    });
  });
}
