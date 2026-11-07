import 'package:flutter_test/flutter_test.dart';
import 'package:arca/core/model_downloader/models/ai_model_capability.dart';
import 'package:arca/core/model_downloader/repositories/in_memory_model_downloader_repository.dart';
import 'package:arca/core/model_downloader/repositories/model_downloader_repository.dart';

void main() {
  group('ModelDownloaderRepository Tests', () {
    test('broadcasts progress updates across listeners', () async {
      final ModelDownloaderRepository repo = InMemoryModelDownloaderRepository(
        tickInterval: const Duration(milliseconds: 50),
        tickStep: 0.5,
      );

      final emissions = <ModelDownloadState>[];
      final sub = repo.progressStream.listen(emissions.add);

      repo.queueDownloads([AiModelCapabilityType.ocr]);

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(emissions, isNotEmpty);
      expect(
        repo.currentState.capabilities[AiModelCapabilityType.ocr]?.status,
        AiModelStatus.ready,
      );

      await sub.cancel();
      repo.dispose();
    });
  });
}
