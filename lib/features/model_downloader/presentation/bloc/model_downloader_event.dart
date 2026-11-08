import '../../../../core/model_downloader/models/ai_model_capability.dart';

sealed class const ModelDownloaderEvent();

final class const ModelDownloaderStarted() extends ModelDownloaderEvent;

final class const ModelDownloaderStateUpdated(final ModelDownloadState state)
    extends ModelDownloaderEvent;
