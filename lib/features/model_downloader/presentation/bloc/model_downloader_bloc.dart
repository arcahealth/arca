import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/model_downloader/services/model_downloader_service.dart';
import 'model_downloader_event.dart';
import 'model_downloader_state.dart';

class ModelDownloaderBloc
    extends Bloc<ModelDownloaderEvent, ModelDownloaderUIState> {
  ModelDownloaderBloc({required this.service})
    : super(ModelDownloaderUIState(downloadState: service.currentState)) {
    on<ModelDownloaderStarted>(_onStarted);
    on<ModelDownloaderStateUpdated>(_onStateUpdated);

    _subscription = service.progressStream.listen((state) {
      add(ModelDownloaderStateUpdated(state));
    });
  }

  final ModelDownloaderService service;
  StreamSubscription? _subscription;

  void _onStarted(
    ModelDownloaderStarted event,
    Emitter<ModelDownloaderUIState> emit,
  ) {
    emit(ModelDownloaderUIState(downloadState: service.currentState));
  }

  void _onStateUpdated(
    ModelDownloaderStateUpdated event,
    Emitter<ModelDownloaderUIState> emit,
  ) {
    emit(ModelDownloaderUIState(downloadState: event.state));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
