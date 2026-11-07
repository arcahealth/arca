import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/model_downloader/repositories/model_downloader_repository.dart';
import 'model_downloader_event.dart';
import 'model_downloader_state.dart';

class ModelDownloaderBloc
    extends Bloc<ModelDownloaderEvent, ModelDownloaderUIState> {
  ModelDownloaderBloc({required this.repository})
    : super(ModelDownloaderUIState(downloadState: repository.currentState)) {
    on<ModelDownloaderStarted>(_onStarted);
    on<ModelDownloaderStateUpdated>(_onStateUpdated);

    _subscription = repository.progressStream.listen((state) {
      add(ModelDownloaderStateUpdated(state));
    });
  }

  final ModelDownloaderRepository repository;
  StreamSubscription? _subscription;

  void _onStarted(
    ModelDownloaderStarted event,
    Emitter<ModelDownloaderUIState> emit,
  ) {
    emit(ModelDownloaderUIState(downloadState: repository.currentState));
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
