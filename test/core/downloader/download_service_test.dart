import 'package:flutter_test/flutter_test.dart';
import 'package:arca/core/ai/models/ai_model.dart';
import 'package:arca/core/downloader/models/download_progress.dart';
import 'package:arca/core/downloader/services/download_manager.dart';
import 'package:arca/core/downloader/services/download_service.dart';

void main() {
  group('DownloadService Tests', () {
    test(
      'broadcasts progress updates across listeners for generic targets',
      () async {
        final DownloadService<AIKind, AIKind> service =
            DownloadManager<AIKind, AIKind>(
              tickInterval: const Duration(milliseconds: 50),
              tickStep: 0.5,
            );

        final emissions = <Map<AIKind, DownloadProgress<AIKind>>>[];
        final sub = service.downloadsStream.listen(emissions.add);

        service.queue([AIKind.ocr]);

        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(emissions, isNotEmpty);
        expect(service.downloads[AIKind.ocr]?.status, DownloadStatus.ready);
        expect(service.downloads[AIKind.ocr]?.progress, 1.0);

        await sub.cancel();
        service.dispose();
      },
    );

    test('supports custom key extractor for distinct K and T types', () async {
      final DownloadService<String, AIModel> service =
          DownloadManager<String, AIModel>(
            keyOf: (model) => model.id,
            tickInterval: const Duration(milliseconds: 50),
            tickStep: 0.5,
          );

      service.queue([defaultAIModels.first]);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(service.downloads['ocr']?.status, DownloadStatus.ready);
      expect(
        service.downloads['ocr']?.target.name,
        'Clinical Lab & Prescription OCR',
      );
      service.dispose();
    });

    test('supports pausing and resuming active downloads', () async {
      final DownloadService<AIKind, AIKind> service =
          DownloadManager<AIKind, AIKind>(
            tickInterval: const Duration(milliseconds: 100),
            tickStep: 0.1,
          );

      service.queue([AIKind.ocr]);
      expect(service.downloads[AIKind.ocr]?.status, DownloadStatus.downloading);

      service.pause(AIKind.ocr);
      expect(service.downloads[AIKind.ocr]?.status, DownloadStatus.paused);

      service.resume(AIKind.ocr);
      expect(service.downloads[AIKind.ocr]?.status, DownloadStatus.downloading);

      service.dispose();
    });
  });
}
