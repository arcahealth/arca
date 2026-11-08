import 'package:flutter_test/flutter_test.dart';
import 'package:arca/core/ai/models/ai_model.dart';
import 'package:arca/core/downloader/models/download_progress.dart';
import 'package:arca/core/downloader/services/download_manager.dart';
import 'package:arca/core/downloader/services/downloader_service.dart';

void main() {
  group('DownloaderService Tests', () {
    test(
      'broadcasts progress updates across listeners for generic targets',
      () async {
        final DownloaderService<AIKind, AIKind> service =
            DownloadManager<AIKind, AIKind>(
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
      },
    );

    test('supports custom key extractor for distinct K and T types', () async {
      final DownloaderService<String, AIModel> service =
          DownloadManager<String, AIModel>(
            keyOf: (model) => model.id,
            tickInterval: const Duration(milliseconds: 50),
            tickStep: 0.5,
          );

      service.queueDownloads([defaultAIModels.first]);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(service.downloads['ocr']?.status, DownloadStatus.ready);
      expect(
        service.downloads['ocr']?.target.name,
        'Clinical Lab & Prescription OCR',
      );
      service.dispose();
    });
  });
}
