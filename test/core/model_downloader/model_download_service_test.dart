import 'package:flutter_test/flutter_test.dart';
import 'package:arca/core/model_downloader/models/ai_model.dart';
import 'package:arca/core/model_downloader/services/model_download_manager.dart';
import 'package:arca/core/model_downloader/services/model_download_service.dart';

void main() {
  group('ModelDownloadService Tests', () {
    test('broadcasts progress updates across listeners', () async {
      final ModelDownloadService service = ModelDownloadManager(
        tickInterval: const Duration(milliseconds: 50),
        tickStep: 0.5,
      );

      final emissions = <Map<ModelKind, DownloadProgress<ModelKind>>>[];
      final sub = service.downloadsStream.listen(emissions.add);

      service.queueDownloads([ModelKind.ocr]);

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(emissions, isNotEmpty);
      expect(service.downloads[ModelKind.ocr]?.status, DownloadStatus.ready);
      expect(service.downloads[ModelKind.ocr]?.progress, 1.0);

      await sub.cancel();
      service.dispose();
    });
  });
}
