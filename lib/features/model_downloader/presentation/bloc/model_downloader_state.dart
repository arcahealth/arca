import 'package:collection/collection.dart';

import '../../../../core/ai/models/ai_model.dart';
import '../../../../core/downloader/models/download_progress.dart';

final class const ModelDownloaderUIState({
  final Map<AIKind, DownloadProgress<AIKind>> downloads = const {},
}) {
  bool get isDownloading => downloads.values.any(
    (d) => d.status == .downloading || d.status == .queued,
  );

  bool get allCompleted =>
      downloads.isNotEmpty && downloads.values.every((d) => d.status == .ready);

  double get totalProgress {
    if (downloads.isEmpty) return 0.0;
    final total = downloads.values.fold<double>(
      0.0,
      (acc, d) => acc + d.progress,
    );
    return total / downloads.length;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelDownloaderUIState &&
          runtimeType == other.runtimeType &&
          const MapEquality<AIKind, DownloadProgress<AIKind>>().equals(
            downloads,
            other.downloads,
          );

  @override
  int get hashCode =>
      const MapEquality<AIKind, DownloadProgress<AIKind>>().hash(downloads);
}
