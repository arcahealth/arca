import '../../../../core/ai/models/ai_model.dart';
import '../../../../core/model_downloader/models/download_progress.dart';

sealed class const ModelDownloaderEvent();

final class const ModelDownloaderStarted() extends ModelDownloaderEvent;

final class const ModelDownloaderStateUpdated(
  final Map<AIKind, DownloadProgress<AIKind>> downloads,
) extends ModelDownloaderEvent;
