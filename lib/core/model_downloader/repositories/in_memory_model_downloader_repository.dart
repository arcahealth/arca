import 'dart:async';

import '../models/ai_model_capability.dart';
import 'model_downloader_repository.dart';

/// In-memory implementation of [ModelDownloaderRepository] with broadcast stream updates.
class InMemoryModelDownloaderRepository implements ModelDownloaderRepository {
  InMemoryModelDownloaderRepository({
    this.tickInterval = const Duration(milliseconds: 200),
    this.tickStep = 0.25,
    ModelDownloadState? initialState,
  }) : _state = initialState ?? const ModelDownloadState();

  final Duration tickInterval;
  final double tickStep;
  ModelDownloadState _state;

  final StreamController<ModelDownloadState> _progressController =
      StreamController<ModelDownloadState>.broadcast();
  final Map<AiModelCapabilityType, Timer> _timers = {};

  @override
  Stream<ModelDownloadState> get progressStream => _progressController.stream;

  @override
  ModelDownloadState get currentState => _state;

  @override
  void queueDownloads(List<AiModelCapabilityType> types) {
    final updated = Map<AiModelCapabilityType, AiModelCapability>.from(
      _state.capabilities,
    );
    for (final type in types) {
      updated[type] = AiModelCapability(
        type: type,
        status: AiModelStatus.downloading,
        progress: 0.05,
      );
      _startSimulatedDownload(type);
    }
    _emitState(_state.copyWith(capabilities: updated));
  }

  @override
  void pauseDownload(AiModelCapabilityType type) {
    _timers[type]?.cancel();
    _timers.remove(type);
    final updated = Map<AiModelCapabilityType, AiModelCapability>.from(
      _state.capabilities,
    );
    final current = updated[type];
    if (current != null) {
      updated[type] = current.copyWith(status: AiModelStatus.paused);
      _emitState(_state.copyWith(capabilities: updated));
    }
  }

  @override
  void resumeDownload(AiModelCapabilityType type) {
    final updated = Map<AiModelCapabilityType, AiModelCapability>.from(
      _state.capabilities,
    );
    final current = updated[type];
    if (current != null) {
      updated[type] = current.copyWith(status: AiModelStatus.downloading);
      _emitState(_state.copyWith(capabilities: updated));
      _startSimulatedDownload(type);
    }
  }

  void _startSimulatedDownload(AiModelCapabilityType type) {
    _timers[type]?.cancel();
    if (tickInterval == Duration.zero) {
      _finishDownload(type);
      return;
    }

    _timers[type] = Timer.periodic(tickInterval, (timer) {
      final cap = _state.capabilities[type];
      final currentProgress = cap?.progress ?? 0.0;
      final nextProgress = currentProgress + tickStep;
      if (nextProgress >= 1.0) {
        timer.cancel();
        _timers.remove(type);
        _finishDownload(type);
      } else {
        final updated = Map<AiModelCapabilityType, AiModelCapability>.from(
          _state.capabilities,
        );
        updated[type] = (cap ?? AiModelCapability(type: type)).copyWith(
          status: AiModelStatus.downloading,
          progress: nextProgress,
        );
        _emitState(_state.copyWith(capabilities: updated));
      }
    });
  }

  void _finishDownload(AiModelCapabilityType type) {
    final updated = Map<AiModelCapabilityType, AiModelCapability>.from(
      _state.capabilities,
    );
    final current = updated[type];
    if (current != null) {
      updated[type] = current.copyWith(
        status: AiModelStatus.ready,
        progress: 1.0,
      );
      _emitState(_state.copyWith(capabilities: updated));
    }
  }

  void _emitState(ModelDownloadState next) {
    _state = next;
    if (!_progressController.isClosed) {
      _progressController.add(next);
    }
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _progressController.close();
  }
}
