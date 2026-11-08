import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arca/core/ai/models/ai_model.dart';
import 'package:arca/core/model_downloader/models/download_progress.dart';
import 'package:arca/core/model_downloader/services/model_download_manager.dart';
import 'package:arca/core/model_downloader/services/model_download_service.dart';
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

      final ModelDownloadService service = ModelDownloadManager(
        initialDownloads: const {
          AIKind.ocr: DownloadProgress<AIKind>(
            target: AIKind.ocr,
            status: DownloadStatus.downloading,
            progress: 0.5,
          ),
        },
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
        final ModelDownloadService service = ModelDownloadManager(
          initialDownloads: const {
            AIKind.ocr: DownloadProgress<AIKind>(
              target: AIKind.ocr,
              status: DownloadStatus.downloading,
              progress: 0.45,
            ),
          },
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
