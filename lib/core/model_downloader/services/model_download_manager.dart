import 'dart:async';

import '../models/ai_model.dart';
import 'model_download_service.dart';

/// Implementation of [ModelDownloadService] managing model download lifecycles and broadcast streams.
class ModelDownloadManager implements ModelDownloadService {
  ModelDownloadManager({
    this.tickInterval = const Duration(milliseconds: 200),
    this.tickStep = 0.25,
    Map<ModelKind, DownloadProgress<ModelKind>>? initialDownloads,
  }) : _downloads = initialDownloads != null ? Map.from(initialDownloads) : {};

  final Duration tickInterval;
  final double tickStep;
  final Map<ModelKind, DownloadProgress<ModelKind>> _downloads;

  final StreamController<Map<ModelKind, DownloadProgress<ModelKind>>>
  _downloadsController =
      StreamController<Map<ModelKind, DownloadProgress<ModelKind>>>.broadcast();
  final Map<ModelKind, Timer> _timers = {};

  @override
  Map<ModelKind, DownloadProgress<ModelKind>> get downloads =>
      Map.unmodifiable(_downloads);

  @override
  Stream<Map<ModelKind, DownloadProgress<ModelKind>>> get downloadsStream =>
      _downloadsController.stream;

  @override
  bool get isDownloading => _downloads.values.any(
    (d) => d.status == .downloading || d.status == .queued,
  );

  @override
  bool get allCompleted =>
      _downloads.isNotEmpty &&
      _downloads.values.every((d) => d.status == .ready);

  @override
  double get totalProgress {
    if (_downloads.isEmpty) return 0.0;
    final total = _downloads.values.fold<double>(
      0.0,
      (acc, d) => acc + d.progress,
    );
    return total / _downloads.length;
  }

  @override
  void queueDownloads(List<ModelKind> kinds) {
    for (final kind in kinds) {
      _downloads[kind] = DownloadProgress<ModelKind>(
        target: kind,
        status: .downloading,
        progress: 0.05,
      );
      _startSimulatedDownload(kind);
    }
    _emit();
  }

  @override
  void pauseDownload(ModelKind kind) {
    _timers[kind]?.cancel();
    _timers.remove(kind);
    final current = _downloads[kind];
    if (current != null) {
      _downloads[kind] = current.copyWith(status: .paused);
      _emit();
    }
  }

  @override
  void resumeDownload(ModelKind kind) {
    final current = _downloads[kind];
    if (current != null) {
      _downloads[kind] = current.copyWith(status: .downloading);
      _emit();
      _startSimulatedDownload(kind);
    }
  }

  void _startSimulatedDownload(ModelKind kind) {
    _timers[kind]?.cancel();
    if (tickInterval == Duration.zero) {
      _finishDownload(kind);
      return;
    }

    _timers[kind] = Timer.periodic(tickInterval, (timer) {
      final current = _downloads[kind];
      final currentProgress = current?.progress ?? 0.0;
      final nextProgress = currentProgress + tickStep;
      if (nextProgress >= 1.0) {
        timer.cancel();
        _timers.remove(kind);
        _finishDownload(kind);
      } else {
        _downloads[kind] =
            (current ?? DownloadProgress<ModelKind>(target: kind)).copyWith(
              status: .downloading,
              progress: nextProgress,
            );
        _emit();
      }
    });
  }

  void _finishDownload(ModelKind kind) {
    final current = _downloads[kind];
    if (current != null) {
      _downloads[kind] = current.copyWith(status: .ready, progress: 1.0);
      _emit();
    }
  }

  void _emit() {
    if (!_downloadsController.isClosed) {
      _downloadsController.add(Map.unmodifiable(_downloads));
    }
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _downloadsController.close();
  }
}
