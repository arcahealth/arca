import 'dart:io';

import 'package:circuitry_flutter/circuitry_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arca/core/ai/ai.dart';

import '../../test_utils/fake_ai_engines.dart';

void main() {
  group('DefaultDocumentInferencePipeline Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('arca_pipeline_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('returns DocumentInferenceFailure when filePaths is empty', () async {
      final pipeline = DefaultDocumentInferencePipeline();
      final result = await pipeline.processDocuments([]);

      expect(result, isA<DocumentInferenceFailure>());
      final failure = result as DocumentInferenceFailure;
      expect(failure.message, contains('No document files provided'));
    });

    test('returns empty ExtractedProfileData when OCR text is empty', () async {
      final emptyFile = File('${tempDir.path}/empty.txt');
      await emptyFile.writeAsString('   ');

      final pipeline = DefaultDocumentInferencePipeline(
        ocrEngine: FakeOcrEngine(text: '   '),
      );
      final result = await pipeline.processDocuments([emptyFile.path]);

      expect(result, isA<DocumentInferenceSuccess>());
      final success = result as DocumentInferenceSuccess;
      expect(success.data.isEmpty, isTrue);
      expect(success.data.patientName, isEmpty);
    });

    test('successfully extracts profile and clinical records end-to-end', () async {
      final sampleDoc = File('${tempDir.path}/prescription.txt');
      await sampleDoc.writeAsString('Dummy path content');

      const ocrOutput = '''
CLINICAL DISCHARGE SUMMARY
Patient Name: Alex Morgan
DOB: 1988-04-12
Rx: Amoxicillin 500mg
Allergies: Penicillin
''';

      final pipeline = DefaultDocumentInferencePipeline(
        ocrEngine: FakeOcrEngine(text: ocrOutput),
      );

      final result = await pipeline.processDocuments([sampleDoc.path]);

      expect(result, isA<DocumentInferenceSuccess>());
      final success = result as DocumentInferenceSuccess;
      final profile = success.data;

      expect(profile.patientName, 'Alex Morgan');
      expect(profile.dateOfBirth, '1988-04-12');
      expect(profile.medications, contains('Amoxicillin 500mg'));
      expect(profile.allergies, contains('Penicillin'));
      expect(profile.confidence, greaterThan(0.8));
      expect(profile.isNotEmpty, isTrue);
    });

    test('synthesizes patient name from first_name and last_name entities', () async {
      final sampleDoc = File('${tempDir.path}/report.txt');
      await sampleDoc.writeAsString('Dummy');

      final fakePii = FakePiiExtractor(
        entities: const [
          ExtractedEntity(label: 'first_name', value: 'Sarah', confidence: 0.95),
          ExtractedEntity(label: 'last_name', value: 'Connor', confidence: 0.95),
          ExtractedEntity(label: 'date_of_birth', value: '1985-02-28', confidence: 0.92),
          ExtractedEntity(label: 'medication', value: 'Lisinopril 10mg', confidence: 0.90),
        ],
      );

      final pipeline = DefaultDocumentInferencePipeline(
        ocrEngine: FakeOcrEngine(text: 'Raw scan text without headers'),
        piiExtractor: fakePii,
      );

      final result = await pipeline.processDocuments([sampleDoc.path]);
      expect(result, isA<DocumentInferenceSuccess>());
      final profile = (result as DocumentInferenceSuccess).data;

      expect(profile.patientName, 'Sarah Connor');
      expect(profile.dateOfBirth, '1985-02-28');
      expect(profile.medications, ['Lisinopril 10mg']);
    });

    test('resolves DocumentInferencePipeline.wire inside Circuit graph', () async {
      final circuit = await Circuit.build([
        DocumentInferencePipeline.wire,
      ]);

      expect(circuit.isInitialized<DocumentInferencePipeline>(), isFalse);
      final pipeline = circuit.get<DocumentInferencePipeline>();
      expect(pipeline, isA<DefaultDocumentInferencePipeline>());
      expect(circuit.isInitialized<DocumentInferencePipeline>(), isTrue);

      await circuit.dispose();
    });
  });
}
