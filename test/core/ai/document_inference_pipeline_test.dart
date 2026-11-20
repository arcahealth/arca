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
      expect(success.data.name, isEmpty);
      expect(success.data.firstName, isEmpty);
      expect(success.data.lastName, isEmpty);
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

      expect(profile.name, 'Alex Morgan');
      expect(profile.firstName, 'Alex');
      expect(profile.lastName, 'Morgan');
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

      expect(profile.name, 'Sarah Connor');
      expect(profile.firstName, 'Sarah');
      expect(profile.lastName, 'Connor');
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

  group('ExtractedProfileData Model Tests', () {
    test('supports empty constant singleton and isEmpty comparison', () {
      const data = ExtractedProfileData.empty;
      expect(data.isEmpty, isTrue);
      expect(data.isNotEmpty, isFalse);
      expect(data.name, isEmpty);
      expect(data.firstName, isEmpty);
      expect(data.middleName, isEmpty);
      expect(data.lastName, isEmpty);

      const defaultInstance = ExtractedProfileData();
      expect(defaultInstance.isEmpty, isTrue);
      expect(defaultInstance == ExtractedProfileData.empty, isTrue);
    });

    test('assembles computed name from individual components', () {
      const fullName = ExtractedProfileData(
        firstName: 'John',
        middleName: 'Fitzgerald',
        lastName: 'Kennedy',
      );
      expect(fullName.name, 'John Fitzgerald Kennedy');

      const firstAndLast = ExtractedProfileData(
        firstName: 'Ada',
        lastName: 'Lovelace',
      );
      expect(firstAndLast.name, 'Ada Lovelace');

      const firstOnly = ExtractedProfileData(firstName: 'Aristotle');
      expect(firstOnly.name, 'Aristotle');
    });

    test('supports copyWith updates', () {
      const original = ExtractedProfileData(
        firstName: 'Alex',
        lastName: 'Smith',
        medications: ['Aspirin'],
      );

      final updated = original.copyWith(
        lastName: 'Morgan',
        allergies: const ['Penicillin'],
      );

      expect(updated.firstName, 'Alex');
      expect(updated.lastName, 'Morgan');
      expect(updated.name, 'Alex Morgan');
      expect(updated.medications, ['Aspirin']);
      expect(updated.allergies, ['Penicillin']);
    });

    test('implements value equality and hashCode', () {
      const a = ExtractedProfileData(
        firstName: 'Alex',
        lastName: 'Morgan',
        medications: ['Amoxicillin 500mg'],
        allergies: ['Penicillin'],
      );
      const b = ExtractedProfileData(
        firstName: 'Alex',
        lastName: 'Morgan',
        medications: ['Amoxicillin 500mg'],
        allergies: ['Penicillin'],
      );
      const c = ExtractedProfileData(
        firstName: 'Alex',
        lastName: 'Smith',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('supports DocumentInferenceResult concise factory constructors', () {
      const success = DocumentInferenceResult.success(
        ExtractedProfileData(firstName: 'Jane', lastName: 'Doe'),
      );
      expect(success, isA<DocumentInferenceSuccess>());
      expect((success as DocumentInferenceSuccess).data.name, 'Jane Doe');

      const failure = DocumentInferenceResult.failure('Inference error');
      expect(failure, isA<DocumentInferenceFailure>());
      expect((failure as DocumentInferenceFailure).message, 'Inference error');
    });
  });
}
