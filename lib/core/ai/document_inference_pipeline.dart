import 'package:circuitry_flutter/circuitry_flutter.dart';

import 'models/models.dart';
import 'ocr_engine.dart';
import 'pii_extractor.dart';

/// Abstract interface for the end-to-end on-device document AI inference pipeline.
abstract interface class DocumentInferencePipeline {
  /// Extracts structured clinical and profile records from the given document [filePaths].
  Future<DocumentInferenceResult> processDocuments(List<String> filePaths);

  /// Declarative Circuitry Wire recipe for DAG dependency resolution.
  static CircuitWire get wire => Wire<DocumentInferencePipeline>(DefaultDocumentInferencePipeline.new);
}

/// Production implementation of [DocumentInferencePipeline] combining [OcrEngine]
/// text recognition with [PiiExtractor] clinical entity classification.
final class DefaultDocumentInferencePipeline implements DocumentInferencePipeline {
  DefaultDocumentInferencePipeline({
    OcrEngine? ocrEngine,
    PiiExtractor? piiExtractor,
  }) : _ocrEngine = ocrEngine ?? DefaultOcrEngine(),
       _piiExtractor = piiExtractor ?? DefaultPiiExtractor();

  final OcrEngine _ocrEngine;
  final PiiExtractor _piiExtractor;

  @override
  Future<DocumentInferenceResult> processDocuments(
    List<String> filePaths,
  ) async {
    if (filePaths.isEmpty) {
      return const DocumentInferenceFailure(
        'No document files provided for inference.',
      );
    }

    // Validate that document files have supported formats
    for (final path in filePaths) {
      if (!OcrEngine.isSupported(path)) {
        final fileName = path.split('/').last;
        return DocumentInferenceFailure(
          'Unsupported document format for "$fileName". Supported formats: ${OcrEngine.supportedExtensions.map((e) => '.$e').join(', ')}.',
        );
      }
    }

    try {
      // 1. Optical Character Recognition (OCR) step
      final recognizedText = await _ocrEngine.recognizeAll(filePaths);
      final cleanText = recognizedText.trim();

      if (cleanText.isEmpty) {
        return const DocumentInferenceFailure(
          'No readable clinical text could be extracted from the document.',
        );
      }

      // 2. Personally Identifiable Information (PII) and clinical extraction step
      final entities = await _piiExtractor.extractEntities(cleanText);

      // 3. Synthesize extracted profile data
      final profile = _synthesizeProfile(cleanText, entities);

      if (profile.isEmpty) {
        return const DocumentInferenceFailure(
          'No clinical profile details (name, date of birth, medications, or allergies) could be found in the document.',
        );
      }

      return DocumentInferenceSuccess(profile);
    } catch (e) {
      return DocumentInferenceFailure(
        'Failed to extract document details: ${e.toString()}',
        e,
      );
    }
  }

  /// Synthesizes structured profile data from recognized text and classified entities.
  ExtractedProfileData _synthesizeProfile(
    String rawText,
    List<ExtractedEntity> entities,
  ) {
    String? firstName;
    String? middleName;
    String? lastName;
    String? dateOfBirth;
    final medications = <String>[];
    final allergies = <String>[];

    for (final entity in entities) {
      if (entity.label == 'first_name' && firstName == null) {
        firstName = entity.value;
      } else if (entity.label == 'middle_name' && middleName == null) {
        middleName = entity.value;
      } else if (entity.label == 'last_name' && lastName == null) {
        lastName = entity.value;
      } else if (entity.label == 'date_of_birth' && dateOfBirth == null) {
        dateOfBirth = entity.value;
      } else if (entity.label == 'medication') {
        if (!medications.contains(entity.value)) {
          medications.add(entity.value);
        }
      } else if (entity.label == 'allergy') {
        if (!allergies.contains(entity.value)) {
          allergies.add(entity.value);
        }
      }
    }

    // Fallback: If individual name components were not found, decompose full name entity
    if (firstName == null && lastName == null) {
      final fullName = entities
          .where(
            (e) => e.label == 'name' || e.label == 'patient_name' || e.label == 'user_name',
          )
          .map((e) => e.value)
          .firstOrNull;

      if (fullName != null) {
        final parts = fullName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
        if (parts.length == 1) {
          firstName = parts.first;
        } else if (parts.length == 2) {
          firstName = parts[0];
          lastName = parts[1];
        } else if (parts.length == 3) {
          firstName = parts[0];
          middleName = parts[1];
          lastName = parts[2];
        } else if (parts.length > 3) {
          firstName = parts[0];
          middleName = parts.sublist(1, parts.length - 1).join(' ');
          lastName = parts.last;
        }
      }
    }

    // If no clinical profile details or name components were detected, return empty singleton
    if (firstName == null &&
        middleName == null &&
        lastName == null &&
        dateOfBirth == null &&
        medications.isEmpty &&
        allergies.isEmpty) {
      return ExtractedProfileData.empty;
    }

    // Compute overall extraction confidence
    final confidence = entities.isEmpty
        ? 0.0
        : entities.map((e) => e.confidence).reduce((a, b) => a + b) / entities.length;

    return ExtractedProfileData(
      firstName: firstName ?? '',
      middleName: middleName ?? '',
      lastName: lastName ?? '',
      dateOfBirth: dateOfBirth ?? '',
      medications: List.unmodifiable(medications),
      allergies: List.unmodifiable(allergies),
      rawText: rawText,
      entities: List.unmodifiable(entities),
      confidence: confidence,
    );
  }
}
