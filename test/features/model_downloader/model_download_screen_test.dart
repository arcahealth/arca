import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arca/core/model_downloader/models/ai_model_capability.dart';
import 'package:arca/core/model_downloader/services/in_memory_model_downloader_service.dart';
import 'package:arca/core/model_downloader/services/model_downloader_service.dart';
import 'package:arca/features/model_downloader/presentation/bloc/model_downloader_bloc.dart';
import 'package:arca/features/model_downloader/presentation/screens/model_download_screen.dart';
import 'package:arca/features/model_downloader/presentation/widgets/model_download_indicator_bar.dart';

void main() {
  group('ModelDownloader Screen & Indicator Tests', () {
    testWidgets('renders progress bars and calls onContinue on CTA tap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final ModelDownloaderService service = InMemoryModelDownloaderService(
        initialState: const ModelDownloadState(
          capabilities: {
            AiModelCapabilityType.ocr: AiModelCapability(
              type: AiModelCapabilityType.ocr,
              status: AiModelStatus.downloading,
              progress: 0.5,
            ),
          },
        ),
      );

      var continueCalled = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BlocProvider<ModelDownloaderBloc>(
            create: (_) => ModelDownloaderBloc(service: service),
            child: ModelDownloadScreen(
              selectedCapabilityIds: const ['ocr'],
              onContinue: () => continueCalled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Downloading Edge AI'), findsOneWidget);
      expect(find.text('Overall Progress'), findsOneWidget);

      final continueButton = find.text(
        'Continue to App (Background Download) →',
      );
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      expect(continueCalled, isTrue);

      service.dispose();
    });

    testWidgets(
      'ModelDownloadIndicatorBar renders when active and calls onTap',
      (tester) async {
        final ModelDownloaderService service = InMemoryModelDownloaderService(
          initialState: const ModelDownloadState(
            capabilities: {
              AiModelCapabilityType.ocr: AiModelCapability(
                type: AiModelCapabilityType.ocr,
                status: AiModelStatus.downloading,
                progress: 0.45,
              ),
            },
          ),
        );

        var tapped = false;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: BlocProvider<ModelDownloaderBloc>(
              create: (_) => ModelDownloaderBloc(service: service),
              child: ModelDownloadIndicatorBar(onTap: () => tapped = true),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Background AI Download'), findsOneWidget);
        await tester.tap(find.byType(ModelDownloadIndicatorBar));
        expect(tapped, isTrue);

        service.dispose();
      },
    );
  });
}
