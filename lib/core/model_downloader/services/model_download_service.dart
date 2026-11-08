import '../models/ai_model.dart';

/// Core service managing edge AI neural weight downloads with reactive broadcast streams.
abstract interface class ModelDownloadService {
  /// Map of currently tracked downloads by AI model kind.
  Map<ModelKind, DownloadProgress<ModelKind>> get downloads;

  /// Broadcast stream emitting updates to the downloads map.
  Stream<Map<ModelKind, DownloadProgress<ModelKind>>> get downloadsStream;

  /// Whether any download is actively transferring or queued.
  bool get isDownloading;

  /// Whether all tracked downloads have reached [DownloadStatus.ready].
  bool get allCompleted;

  /// Aggregate normalized progress (0.0 to 1.0) across all tracked downloads.
  double get totalProgress;

  /// Queues specified model kinds for on-device download.
  void queueDownloads(List<ModelKind> kinds);

  /// Pauses an active download.
  void pauseDownload(ModelKind kind);

  /// Resumes a paused download.
  void resumeDownload(ModelKind kind);

  /// Releases stream controllers and timer resources.
  void dispose();
}
