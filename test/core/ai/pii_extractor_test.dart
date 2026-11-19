import 'package:flutter_test/flutter_test.dart';
import 'package:arca/core/ai/pii_extractor.dart';

void main() {
  group('DefaultPiiExtractor Tests', () {
    late DefaultPiiExtractor extractor;

    setUp(() {
      extractor = DefaultPiiExtractor();
    });

    tearDown(() async {
      await extractor.dispose();
    });

    test('returns empty list when input text is empty or whitespace', () async {
      final entities = await extractor.extractEntities('   ');
      expect(entities, isEmpty);
    });

    test('extracts name and components from clinical summary header', () async {
      const text = '''
Arca Health Clinic
Patient Name: Alex Morgan
Date: 2026-11-20
''';
      final entities = await extractor.extractEntities(text);
      final nameEntity = entities.firstWhere((e) => e.label == 'name');

      expect(nameEntity.value, 'Alex Morgan');
      expect(nameEntity.confidence, greaterThanOrEqualTo(0.90));
      expect(entities.any((e) => e.label == 'first_name' && e.value == 'Alex'), isTrue);
      expect(entities.any((e) => e.label == 'last_name' && e.value == 'Morgan'), isTrue);
    });

    test('extracts and normalizes date of birth', () async {
      const text = 'Patient: Jane Doe\nDOB: 04/12/1988\nGender: Female';
      final entities = await extractor.extractEntities(text);
      final dobEntity = entities.firstWhere((e) => e.label == 'date_of_birth');

      expect(dobEntity.value, '1988-04-12');
    });

    test('extracts explicit Rx medications and dosage patterns', () async {
      const text = '''
PRESCRIPTION RECORD
Patient: Michael Scott
Rx: Amoxicillin 500mg, Lisinopril 10mg
Take one tablet daily
''';
      final entities = await extractor.extractEntities(text);
      final medEntities = entities.where((e) => e.label == 'medication').toList();

      expect(medEntities, isNotEmpty);
      final medValues = medEntities.map((e) => e.value).toList();
      expect(medValues, contains('Amoxicillin 500mg'));
      expect(medValues, contains('Lisinopril 10mg'));
    });

    test('extracts allergies from documented lines and keywords', () async {
      const text = '''
Patient Name: Alex Morgan
DOB: 1988-04-12
Allergies: Penicillin, Sulfa
''';
      final entities = await extractor.extractEntities(text);
      final allergyEntities = entities.where((e) => e.label == 'allergy').toList();

      expect(allergyEntities, isNotEmpty);
      final values = allergyEntities.map((e) => e.value).toList();
      expect(values, contains('Penicillin'));
      expect(values, contains('Sulfa'));
    });

    test('extracts comprehensive clinical document without duplication', () async {
      const text = '''
CLINICAL DISCHARGE SUMMARY
Hospital: General Medical
Patient Name: Alex Morgan
DOB: 1988-04-12
Rx: Amoxicillin 500mg
Allergies: Penicillin
''';
      final entities = await extractor.extractEntities(text);

      expect(entities.any((e) => e.label == 'name' && e.value == 'Alex Morgan'), isTrue);
      expect(entities.any((e) => e.label == 'first_name' && e.value == 'Alex'), isTrue);
      expect(entities.any((e) => e.label == 'last_name' && e.value == 'Morgan'), isTrue);
      expect(entities.any((e) => e.label == 'date_of_birth' && e.value == '1988-04-12'), isTrue);
      expect(entities.any((e) => e.label == 'medication' && e.value.contains('Amoxicillin 500mg')), isTrue);
      expect(entities.any((e) => e.label == 'allergy' && e.value.contains('Penicillin')), isTrue);
    });
  });
}
