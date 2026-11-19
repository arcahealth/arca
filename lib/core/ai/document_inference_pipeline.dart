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

    try {
      // 1. Optical Character Recognition (OCR) step
      final recognizedText = await _ocrEngine.recognizeAll(filePaths);
      final cleanText = recognizedText.trim();

      if (cleanText.isEmpty) {
        return const DocumentInferenceSuccess(ExtractedProfileData.empty());
      }

      // 2. Personally Identifiable Information (PII) and clinical extraction step
      final entities = await _piiExtractor.extractEntities(cleanText);

      // 3. Synthesize extracted profile data
      final profile = _synthesizeProfile(cleanText, entities);

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
    String? patientName;
    String? dateOfBirth;
    final medications = <String>[];
    final allergies = <String>[];

    // Check explicit patient_name entity first
    for (final entity in entities) {
      if (entity.label == 'patient_name' && patientName == null) {
        patientName = entity.value;
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

    // Fallback: Combine first_name and last_name PII entities if patient_name was missing
    if (patientName == null) {
      final firstName = entities.where((e) => e.label == 'first_name').map((e) => e.value).firstOrNull;
      final lastName = entities.where((e) => e.label == 'last_name').map((e) => e.value).firstOrNull;

      if (firstName != null && lastName != null) {
        patientName = '$firstName $lastName';
      } else if (firstName != null) {
        patientName = firstName;
      } else {
        final userName = entities.where((e) => e.label == 'user_name').map((e) => e.value).firstOrNull;
        if (userName != null) {
          patientName = userName;
        }
      }
    }

    // Compute overall extraction confidence
    final confidence = entities.isEmpty
        ? 0.0
        : entities.map((e) => e.confidence).reduce((a, b) => a + b) / entities.length;

    return ExtractedProfileData(
      patientName: patientName ?? '',
      dateOfBirth: dateOfBirth ?? '',
      medications: List.unmodifiable(medications),
      allergies: List.unmodifiable(allergies),
      rawText: rawText,
      entities: List.unmodifiable(entities),
      confidence: confidence,
    );
  }
}
