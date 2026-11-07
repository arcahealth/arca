import '../../../../core/model_downloader/models/ai_model_capability.dart';

final class ModelDownloaderUIState {
  const ModelDownloaderUIState({
    this.downloadState = const ModelDownloadState(),
  });

  final ModelDownloadState downloadState;

  bool get isDownloading => downloadState.isDownloading;
  bool get allCompleted => downloadState.allCompleted;
  double get totalProgress => downloadState.totalProgress;
  Map<AiModelCapabilityType, AiModelCapability> get capabilities =>
      downloadState.capabilities;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelDownloaderUIState &&
          runtimeType == other.runtimeType &&
          downloadState == other.downloadState;

  @override
  int get hashCode => downloadState.hashCode;
}
