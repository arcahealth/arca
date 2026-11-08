import 'dart:async';

import '../models/download_progress.dart';
import 'download_service.dart';

R _defaultKeyOf<R, T>(T target) => target as R;

/// Generic implementation of [DownloadService] managing download lifecycles and broadcast streams.
class DownloadManager<K extends Object, T extends Object>({
  K Function(T target)? keyOf,
  final Duration tickInterval = const Duration(milliseconds: 200),
  final double tickStep = 0.25,
  Map<K, DownloadProgress<T>>? initialDownloads,
}) implements DownloadService<K, T> {
  final K Function(T target) keyOf = keyOf ?? _defaultKeyOf;
  final Map<K, DownloadProgress<T>> _downloads = Map.from(
    initialDownloads ?? const {},
  );

  final StreamController<Map<K, DownloadProgress<T>>> _downloadsController =
      StreamController<Map<K, DownloadProgress<T>>>.broadcast();
  final Map<K, Timer> _timers = {};

  @override
  Map<K, DownloadProgress<T>> get downloads => .unmodifiable(_downloads);

  @override
  Stream<Map<K, DownloadProgress<T>>> get downloadsStream =>
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
  void queue(List<T> items) {
    for (final item in items) {
      final key = keyOf(item);
      _downloads[key] = DownloadProgress<T>(
        target: item,
        status: .downloading,
        progress: 0.05,
      );
      _startSimulatedDownload(key);
    }
    _emit();
  }

  @override
  void pause(K key) {
    _timers[key]?.cancel();
    _timers.remove(key);
    final current = _downloads[key];
    if (current != null) {
      _downloads[key] = current.copyWith(status: .paused);
      _emit();
    }
  }

  @override
  void resume(K key) {
    final current = _downloads[key];
    if (current != null) {
      _downloads[key] = current.copyWith(status: .downloading);
      _emit();
      _startSimulatedDownload(key);
    }
  }

  void _startSimulatedDownload(K key) {
    _timers[key]?.cancel();
    if (tickInterval == Duration.zero) {
      _finishDownload(key);
      return;
    }

    _timers[key] = Timer.periodic(tickInterval, (timer) {
      final current = _downloads[key];
      if (current == null) return;
      final currentProgress = current.progress;
      final nextProgress = currentProgress + tickStep;
      if (nextProgress >= 1.0) {
        timer.cancel();
        _timers.remove(key);
        _finishDownload(key);
      } else {
        _downloads[key] = current.copyWith(
          status: .downloading,
          progress: nextProgress,
        );
        _emit();
      }
    });
  }

  void _finishDownload(K key) {
    final current = _downloads[key];
    if (current != null) {
      _downloads[key] = current.copyWith(status: .ready, progress: 1.0);
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
