import '../models/ai_model_capability.dart';

/// Core service managing edge AI neural weight downloads with reactive broadcast streams.
abstract interface class ModelDownloaderService {
  /// Broadcast stream emitting model download progress updates across features.
  Stream<ModelDownloadState> get progressStream;

  /// Current snapshot of download progress.
  ModelDownloadState get currentState;

  /// Queues specified model bundles for on-device download.
  void queueDownloads(List<AiModelCapabilityType> types);

  /// Pauses an active download.
  void pauseDownload(AiModelCapabilityType type);

  /// Resumes a paused download.
  void resumeDownload(AiModelCapabilityType type);

  /// Releases stream controllers and timer resources.
  void dispose();
}
