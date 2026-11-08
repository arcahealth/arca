/// Identifiers for on-device AI capabilities supported by Arca.
enum ModelKind { ocr, asr }

/// Generic download lifecycle states.
enum DownloadStatus { queued, downloading, paused, ready, failed }

/// Generic container tracking progress and status for any non-nullable download target.
final class const DownloadProgress<T extends Object>({
  required final T target,
  final DownloadStatus status = .queued,
  final double progress = 0.0,
}) {
  DownloadProgress<T> copyWith({
    T? target,
    DownloadStatus? status,
    double? progress,
  }) {
    return DownloadProgress<T>(
      target: target ?? this.target,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadProgress<T> &&
          runtimeType == other.runtimeType &&
          target == other.target &&
          status == other.status &&
          progress == other.progress;

  @override
  int get hashCode => Object.hash(target, status, progress);
}

/// Pure data class representing an AI model package and its metadata.
final class const AIModel({
  required final String id,
  required final ModelKind kind,
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
