import '../models/ai_model.dart';

/// Core service managing edge AI neural weight downloads with reactive broadcast streams.
abstract interface class ModelDownloaderService {
  /// Map of currently tracked downloads by AI capability kind.
  Map<AIKind, DownloadProgress<AIKind>> get downloads;

  /// Broadcast stream emitting updates to the downloads map.
  Stream<Map<AIKind, DownloadProgress<AIKind>>> get downloadsStream;

  /// Whether any download is actively transferring or queued.
  bool get isDownloading;

  /// Whether all tracked downloads have reached [DownloadStatus.ready].
  bool get allCompleted;

  /// Aggregate normalized progress (0.0 to 1.0) across all tracked downloads.
  double get totalProgress;

  /// Queues specified model kinds for on-device download.
  void queueDownloads(List<AIKind> kinds);

  /// Pauses an active download.
  void pauseDownload(AIKind kind);

  /// Resumes a paused download.
  void resumeDownload(AIKind kind);

  /// Releases stream controllers and timer resources.
  void dispose();
}
