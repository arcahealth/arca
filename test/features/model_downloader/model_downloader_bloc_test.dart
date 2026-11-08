import 'package:flutter_test/flutter_test.dart';
import 'package:arca/core/model_downloader/models/ai_model_capability.dart';
import 'package:arca/core/model_downloader/repositories/in_memory_model_downloader_repository.dart';
import 'package:arca/core/model_downloader/repositories/model_downloader_repository.dart';
import 'package:arca/features/model_downloader/presentation/bloc/model_downloader_bloc.dart';

void main() {
  group('ModelDownloaderBloc Tests', () {
    test('updates state reactively via repository broadcast stream', () async {
      final ModelDownloaderRepository repo = InMemoryModelDownloaderRepository(
        tickInterval: const Duration(milliseconds: 20),
        tickStep: 0.5,
      );

      final bloc = ModelDownloaderBloc(repository: repo);
      expect(bloc.state.isDownloading, isFalse);

      repo.queueDownloads([AiModelCapabilityType.ocr]);

      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (!bloc.state.allCompleted && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(bloc.state.allCompleted, isTrue);

      await bloc.close();
      repo.dispose();
    });
  });
}
