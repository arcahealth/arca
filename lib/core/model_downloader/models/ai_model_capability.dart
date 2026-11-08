enum const AiModelCapabilityType({
  required final String id,
  required final String name,
  required final String description,
  required final String estimatedSize,
}) {
  ocr(
    id: 'ocr',
    name: 'Clinical Lab & Prescription OCR',
    description: 'On-device vision model extracting structured lab values, reference intervals, and prescriptions from scans.',
    estimatedSize: '45 MB',
  ),
  asr(
    id: 'asr',
    name: 'Clinical Speech & Dictation (ASR)',
    description: 'Whisper-based local speech recognition for doctor appointments, consultations, and verbal symptom logs.',
    estimatedSize: '78 MB',
  ),
  clinicalNer(
    id: 'clinical_ner',
    name: 'Medical Entity Recognition (NER)',
    description: 'Quantized on-device classifier identifying clinical entities, drug interactions, and dosage metrics.',
    estimatedSize: '32 MB',
  ),
}

enum AiModelStatus { notInstalled, queued, downloading, ready, paused, failed }

/// Representation of an on-device AI capability and runtime model bundle.
final class const AiModelCapability({
  required final AiModelCapabilityType type,
  final AiModelStatus status = .notInstalled,
  final double progress = 0.0,
}) {
  AiModelCapability copyWith({AiModelStatus? status, double? progress}) {
    return AiModelCapability(
      type: type,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiModelCapability &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          status == other.status &&
          progress == other.progress;

  @override
  int get hashCode => Object.hash(type, status, progress);
}

/// Snapshot of all active and installed AI model capabilities.
final class const ModelDownloadState({
  final Map<AiModelCapabilityType, AiModelCapability> capabilities = const {},
}) {
  bool get isDownloading => capabilities.values.any(
    (c) => c.status == .downloading || c.status == .queued,
  );

  bool get allCompleted =>
      capabilities.isNotEmpty &&
      capabilities.values.every((c) => c.status == .ready);

  double get totalProgress {
    if (capabilities.isEmpty) return 0.0;
    final total = capabilities.values.fold<double>(
      0.0,
      (acc, c) => acc + c.progress,
    );
    return total / capabilities.length;
  }

  ModelDownloadState copyWith({
    Map<AiModelCapabilityType, AiModelCapability>? capabilities,
  }) {
    return ModelDownloadState(capabilities: capabilities ?? this.capabilities);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelDownloadState &&
          runtimeType == other.runtimeType &&
          capabilities.length == other.capabilities.length &&
          capabilities.entries.every(
            (e) => other.capabilities[e.key] == e.value,
          );

  @override
  int get hashCode => Object.hashAll(capabilities.entries);
}
