import '../../../../core/model_downloader/models/ai_model_capability.dart';

sealed class ModelDownloaderEvent {
  const ModelDownloaderEvent();
}

final class ModelDownloaderStarted extends ModelDownloaderEvent {
  const ModelDownloaderStarted();
}

final class ModelDownloaderStateUpdated extends ModelDownloaderEvent {
  const ModelDownloaderStateUpdated(this.state);
  final ModelDownloadState state;
}
