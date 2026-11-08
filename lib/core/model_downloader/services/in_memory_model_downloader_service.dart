import 'dart:async';

import '../models/ai_model.dart';
import 'model_downloader_service.dart';

/// In-memory implementation of [ModelDownloaderService] with broadcast stream updates.
class InMemoryModelDownloaderService implements ModelDownloaderService {
  InMemoryModelDownloaderService({
    this.tickInterval = const Duration(milliseconds: 200),
    this.tickStep = 0.25,
    Map<AIKind, DownloadProgress<AIKind>>? initialDownloads,
  }) : _downloads = initialDownloads != null ? Map.from(initialDownloads) : {};

  final Duration tickInterval;
  final double tickStep;
  final Map<AIKind, DownloadProgress<AIKind>> _downloads;

  final StreamController<Map<AIKind, DownloadProgress<AIKind>>>
  _downloadsController =
      StreamController<Map<AIKind, DownloadProgress<AIKind>>>.broadcast();
  final Map<AIKind, Timer> _timers = {};

  @override
  Map<AIKind, DownloadProgress<AIKind>> get downloads =>
      Map.unmodifiable(_downloads);

  @override
  Stream<Map<AIKind, DownloadProgress<AIKind>>> get downloadsStream =>
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
  void queueDownloads(List<AIKind> kinds) {
    for (final kind in kinds) {
      _downloads[kind] = DownloadProgress<AIKind>(
        target: kind,
        status: .downloading,
        progress: 0.05,
      );
      _startSimulatedDownload(kind);
    }
    _emit();
  }

  @override
  void pauseDownload(AIKind kind) {
    _timers[kind]?.cancel();
    _timers.remove(kind);
    final current = _downloads[kind];
    if (current != null) {
      _downloads[kind] = current.copyWith(status: .paused);
      _emit();
    }
  }

  @override
  void resumeDownload(AIKind kind) {
    final current = _downloads[kind];
    if (current != null) {
      _downloads[kind] = current.copyWith(status: .downloading);
      _emit();
      _startSimulatedDownload(kind);
    }
  }

  void _startSimulatedDownload(AIKind kind) {
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
        _downloads[kind] = (current ?? DownloadProgress<AIKind>(target: kind))
            .copyWith(status: .downloading, progress: nextProgress);
        _emit();
      }
    });
  }

  void _finishDownload(AIKind kind) {
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
