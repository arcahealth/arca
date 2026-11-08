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
