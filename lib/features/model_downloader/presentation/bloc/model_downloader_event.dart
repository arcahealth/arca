import '../../../../core/model_downloader/models/ai_model.dart';

sealed class const ModelDownloaderEvent();

final class const ModelDownloaderStarted() extends ModelDownloaderEvent;

final class const ModelDownloaderStateUpdated(
  final Map<AIKind, DownloadProgress<AIKind>> downloads,
) extends ModelDownloaderEvent;
