import 'package:flutter_test/flutter_test.dart';
import 'package:arca/core/model_downloader/models/ai_model.dart';
import 'package:arca/core/model_downloader/services/in_memory_model_downloader_service.dart';
import 'package:arca/core/model_downloader/services/model_downloader_service.dart';

void main() {
  group('ModelDownloaderService Tests', () {
    test('broadcasts progress updates across listeners', () async {
      final ModelDownloaderService service = InMemoryModelDownloaderService(
        tickInterval: const Duration(milliseconds: 50),
        tickStep: 0.5,
      );

      final emissions = <Map<AIKind, DownloadProgress<AIKind>>>[];
      final sub = service.downloadsStream.listen(emissions.add);

      service.queueDownloads([AIKind.ocr]);

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(emissions, isNotEmpty);
      expect(service.downloads[AIKind.ocr]?.status, DownloadStatus.ready);
      expect(service.downloads[AIKind.ocr]?.progress, 1.0);

      await sub.cancel();
      service.dispose();
    });
  });
}
