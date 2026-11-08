import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ai/models/ai_model.dart';
import '../../../../core/downloader/services/download_service.dart';
import 'model_downloader_event.dart';
import 'model_downloader_state.dart';

class ModelDownloaderBloc
    extends Bloc<ModelDownloaderEvent, ModelDownloaderUIState> {
  ModelDownloaderBloc({required this.service})
    : super(ModelDownloaderUIState(downloads: service.downloads)) {
    on<ModelDownloaderStarted>(_onStarted);
    on<ModelDownloaderStateUpdated>(_onStateUpdated);

    _subscription = service.downloadsStream.listen((downloads) {
      add(ModelDownloaderStateUpdated(downloads));
    });
  }

  final DownloadService<AIKind, AIKind> service;
  StreamSubscription? _subscription;

  void _onStarted(
    ModelDownloaderStarted event,
    Emitter<ModelDownloaderUIState> emit,
  ) {
    emit(ModelDownloaderUIState(downloads: service.downloads));
  }

  void _onStateUpdated(
    ModelDownloaderStateUpdated event,
    Emitter<ModelDownloaderUIState> emit,
  ) {
    emit(ModelDownloaderUIState(downloads: event.downloads));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
