/// Identifiers for on-device AI capabilities supported by Arca.
enum AIKind { ocr, asr }

/// Pure data class representing an AI model package and its metadata.
final class const AIModel({
  required final String id,
  required final AIKind kind,
  required final String name,
  required final String description,
  required final String estimatedSize,
}) {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          kind == other.kind &&
          name == other.name &&
          description == other.description &&
          estimatedSize == other.estimatedSize;

  @override
  int get hashCode => Object.hash(id, kind, name, description, estimatedSize);
}

/// Default mock models for offline development, onboarding, and tests.
const defaultAIModels = [
  AIModel(
    id: 'ocr',
    kind: .ocr,
    name: 'Clinical Lab & Prescription OCR',
    description: 'On-device vision model extracting structured lab values, reference intervals, and prescriptions from scans.',
    estimatedSize: '45 MB',
  ),
  AIModel(
    id: 'asr',
    kind: .asr,
    name: 'Clinical Speech & Dictation (ASR)',
    description: 'Whisper-based local speech recognition for doctor appointments, consultations, and verbal symptom logs.',
    estimatedSize: '78 MB',
  ),
];
