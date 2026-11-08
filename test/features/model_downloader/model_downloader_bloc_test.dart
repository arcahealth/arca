import 'package:flutter_test/flutter_test.dart';
import 'package:arca/core/ai/models/ai_model.dart';
import 'package:arca/core/model_downloader/services/model_download_manager.dart';
import 'package:arca/core/model_downloader/services/model_download_service.dart';
import 'package:arca/features/model_downloader/presentation/bloc/model_downloader_bloc.dart';

void main() {
  group('ModelDownloaderBloc Tests', () {
    test('updates state reactively via service broadcast stream', () async {
      final ModelDownloadService service = ModelDownloadManager(
        tickInterval: const Duration(milliseconds: 20),
        tickStep: 0.5,
      );

      final bloc = ModelDownloaderBloc(service: service);
      expect(bloc.state.isDownloading, isFalse);

      service.queueDownloads([AIKind.ocr]);

      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (!bloc.state.allCompleted && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(bloc.state.allCompleted, isTrue);

      await bloc.close();
      service.dispose();
    });
  });
}
