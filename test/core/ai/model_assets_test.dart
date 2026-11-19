import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arca/core/ai/ai.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ArcaModelAssets Bundle Tests', () {
    test('all registered assets physically exist on disk in assets folder', () {
      for (final assetPath in ArcaModelAssets.allAssets) {
        final file = File(assetPath);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Expected asset to exist on disk: $assetPath',
        );
        expect(
          file.lengthSync(),
          greaterThan(0),
          reason: 'Asset file should not be empty: $assetPath',
        );
      }
    });

    test('companion dictionary and configuration files contain expected keys', () async {
      // Verify PP-OCRv6 dictionary content
      final dictContent = await File(ArcaModelAssets.ocrDict).readAsString();
      expect(dictContent, contains('0'));
      expect(dictContent, contains('A'));
      expect(dictContent.trim().split('\n').length, greaterThan(1000));

      // Verify MiniLM-L6 PII config.json
      final piiConfigContent = await File(ArcaModelAssets.piiConfig).readAsString();
      expect(piiConfigContent, contains('"id2label"'));
      expect(piiConfigContent, contains('medical_record_number'));

      // Verify MiniLM-L6 tokenizer vocabulary
      final piiVocabContent = await File(ArcaModelAssets.piiVocab).readAsString();
      expect(piiVocabContent, contains('[CLS]'));
      expect(piiVocabContent, contains('[SEP]'));
    });

    test('bundle can load companion text assets via rootBundle', () async {
      final dictString = await rootBundle.loadString(ArcaModelAssets.ocrDict);
      expect(dictString.isNotEmpty, isTrue);

      final piiConfigString = await rootBundle.loadString(ArcaModelAssets.piiConfig);
      expect(piiConfigString, contains('"id2label"'));
    });

    test('bundle can load binary ONNX models via rootBundle', () async {
      final detMediumData = await rootBundle.load(ArcaModelAssets.ocrDetMediumInt8);
      expect(detMediumData.lengthInBytes, greaterThan(10000000));

      final recMediumData = await rootBundle.load(ArcaModelAssets.ocrRecMediumInt8);
      expect(recMediumData.lengthInBytes, greaterThan(10000000));

      final piiModelData = await rootBundle.load(ArcaModelAssets.piiModelInt8);
      expect(piiModelData.lengthInBytes, greaterThan(10000000));
    });
  });
}
