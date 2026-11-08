import 'package:flutter_test/flutter_test.dart';
import 'package:arca/core/model_downloader/models/ai_model_capability.dart';
import 'package:arca/core/model_downloader/services/in_memory_model_downloader_service.dart';
import 'package:arca/core/model_downloader/services/model_downloader_service.dart';

void main() {
  group('ModelDownloaderService Tests', () {
    test('broadcasts progress updates across listeners', () async {
      final ModelDownloaderService service = InMemoryModelDownloaderService(
        tickInterval: const Duration(milliseconds: 50),
        tickStep: 0.5,
      );

      final emissions = <ModelDownloadState>[];
      final sub = service.progressStream.listen(emissions.add);

      service.queueDownloads([AiModelCapabilityType.ocr]);

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(emissions, isNotEmpty);
      expect(
        service.currentState.capabilities[AiModelCapabilityType.ocr]?.status,
        AiModelStatus.ready,
      );

      await sub.cancel();
      service.dispose();
    });
  });
}
