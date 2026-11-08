import '../../../../core/model_downloader/models/ai_model_capability.dart';

final class const ModelDownloaderUIState({
  final ModelDownloadState downloadState = const ModelDownloadState(),
}) {
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
