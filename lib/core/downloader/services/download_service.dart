import '../models/download_progress.dart';

/// Generic service managing asynchronous download lifecycles and reactive broadcast streams.
///
/// [K] is the unique key type for tracking downloads in the map.
/// [T] is the non-nullable target payload/item wrapped by [DownloadProgress].
abstract interface class DownloadService<K extends Object, T extends Object> {
  /// Map of currently tracked downloads keyed by [K].
  Map<K, DownloadProgress<T>> get downloads;

  /// Broadcast stream emitting updates to the downloads map.
  Stream<Map<K, DownloadProgress<T>>> get downloadsStream;

  /// Whether any download is actively transferring or queued.
  bool get isDownloading;

  /// Whether all tracked downloads have reached [DownloadStatus.ready].
  bool get allCompleted;

  /// Aggregate normalized progress (0.0 to 1.0) across all tracked downloads.
  double get totalProgress;

  /// Queues specified target items for download.
  void queue(List<T> items);

  /// Pauses an active download identified by [key].
  void pause(K key);

  /// Resumes a paused download identified by [key].
  void resume(K key);

  /// Releases stream controllers and timer resources.
  void dispose();
}
