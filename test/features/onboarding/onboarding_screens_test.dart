import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arca/core/ai/ai.dart';
import 'package:arca/core/capture/capture.dart';
import 'package:arca/features/onboarding/presentation/screens/screens.dart';

import '../../test_utils/fake_document_capture_service.dart';
import '../../test_utils/fake_document_inference_pipeline.dart';

Widget _wrap(Widget child) => Directionality(textDirection: TextDirection.ltr, child: child);

void _setViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('WelcomeScreen Tests', () {
    testWidgets(
      'renders display title and fires onScan, onManualEntry, and onSkip callbacks',
      (tester) async {
        _setViewport(tester);
        var scanCalled = false;
        var manualCalled = false;
        var skipCalled = false;

        await tester.pumpWidget(
          _wrap(
            WelcomeScreen(
              onScan: () => scanCalled = true,
              onManualEntry: () => manualCalled = true,
              onSkip: () => skipCalled = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('ARCA'), findsOneWidget);
        expect(find.textContaining('Your medical records'), findsOneWidget);

        final scanBtn = find.text('Scan Document');
        await tester.ensureVisible(scanBtn);
        await tester.tap(scanBtn);
        expect(scanCalled, isTrue);

        final manualBtn = find.text('Enter Manually');
        await tester.ensureVisible(manualBtn);
        await tester.tap(manualBtn);
        expect(manualCalled, isTrue);

        final skipBtn = find.text('Skip Setup');
        await tester.ensureVisible(skipBtn);
        await tester.tap(skipBtn);
        expect(skipCalled, isTrue);
      },
    );

    testWidgets('renders Get Started when only onStart provided', (
      tester,
    ) async {
      _setViewport(tester);
      var startCalled = false;

      await tester.pumpWidget(
        _wrap(WelcomeScreen(onStart: () => startCalled = true)),
      );
      await tester.pumpAndSettle();

      final startBtn = find.text('Get Started');
      await tester.ensureVisible(startBtn);
      await tester.tap(startBtn);
      expect(startCalled, isTrue);
    });
  });

  group('DocumentScanScreen Tests', () {
    testWidgets('renders viewfinder and fires onCapture / onSwitchToManual', (
      tester,
    ) async {
      _setViewport(tester);
      var captureCalled = false;
      var manualCalled = false;

      await tester.pumpWidget(
        _wrap(
          DocumentScanScreen(
            onCapture: () => captureCalled = true,
            onSwitchToManual: () => manualCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Scan Document'), findsOneWidget);
      expect(find.text('Align document within frame'), findsOneWidget);
      expect(find.text('Bundled RapidOCR'), findsOneWidget);
      expect(find.text('Start Document Scan'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Photo Gallery'), findsOneWidget);
      expect(find.text('Import PDF or Document File'), findsOneWidget);

      final captureBtn = find.text('Capture & Extract Details');
      await tester.ensureVisible(captureBtn);
      await tester.tap(captureBtn);
      expect(captureCalled, isTrue);

      final manualBtn = find.text('Enter Details Manually Instead');
      await tester.ensureVisible(manualBtn);
      await tester.tap(manualBtn);
      expect(manualCalled, isTrue);
    });

    testWidgets(
      'Start Document Scan invokes captureService and updates UI with captured pages',
      (tester) async {
        _setViewport(tester);
        final fakeService = FakeDocumentCaptureService(
          scanResult: const DocumentCaptureResult.success([
            '/tmp/prescription_page1.jpg',
            '/tmp/prescription_page2.jpg',
          ]),
        );
        List<String>? capturedImages;

        await tester.pumpWidget(
          _wrap(
            DocumentScanScreen(
              captureService: fakeService,
              onImagesCaptured: (images) => capturedImages = images,
              onCapture: () {},
              onSwitchToManual: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scanBtn = find.text('Start Document Scan');
        await tester.ensureVisible(scanBtn);
        await tester.tap(scanBtn);
        await tester.pumpAndSettle();

        expect(fakeService.scanCalls, 1);
        expect(capturedImages, [
          '/tmp/prescription_page1.jpg',
          '/tmp/prescription_page2.jpg',
        ]);
        expect(
          find.text('2 Document File(s) Selected'),
          findsOneWidget,
        );
        expect(find.text('prescription_page1.jpg'), findsOneWidget);
        expect(find.text('Ready for OCR'), findsOneWidget);
        expect(find.text('Proceed to Review'), findsOneWidget);
      },
    );

    testWidgets(
      'Take Photo invokes captureService photo and fires onImagesCaptured',
      (tester) async {
        _setViewport(tester);
        final fakeService = FakeDocumentCaptureService(
          photoResult: const DocumentCaptureResult.success([
            '/tmp/rx_snapshot.jpg',
          ]),
        );
        List<String>? capturedImages;

        await tester.pumpWidget(
          _wrap(
            DocumentScanScreen(
              captureService: fakeService,
              onImagesCaptured: (images) => capturedImages = images,
              onCapture: () {},
              onSwitchToManual: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        final photoBtn = find.text('Take Photo');
        await tester.ensureVisible(photoBtn);
        await tester.tap(photoBtn);
        await tester.pumpAndSettle();

        expect(fakeService.photoCalls, 1);
        expect(capturedImages, ['/tmp/rx_snapshot.jpg']);
        expect(find.text('1 Document File(s) Selected'), findsOneWidget);
        expect(find.text('rx_snapshot.jpg'), findsOneWidget);
      },
    );

    testWidgets(
      'Photo Gallery invokes captureService gallery and fires onImagesCaptured',
      (tester) async {
        _setViewport(tester);
        final fakeService = FakeDocumentCaptureService(
          pickResult: const DocumentCaptureResult.success([
            '/tmp/lab_report_gallery.png',
          ]),
        );
        List<String>? capturedImages;

        await tester.pumpWidget(
          _wrap(
            DocumentScanScreen(
              captureService: fakeService,
              onImagesCaptured: (images) => capturedImages = images,
              onCapture: () {},
              onSwitchToManual: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        final galleryBtn = find.text('Photo Gallery');
        await tester.ensureVisible(galleryBtn);
        await tester.tap(galleryBtn);
        await tester.pumpAndSettle();

        expect(fakeService.pickCalls, 1);
        expect(capturedImages, ['/tmp/lab_report_gallery.png']);
        expect(find.text('1 Document File(s) Selected'), findsOneWidget);
      },
    );

    testWidgets(
      'Import PDF or Document File invokes captureService files and fires onImagesCaptured',
      (tester) async {
        _setViewport(tester);
        final fakeService = FakeDocumentCaptureService(
          filesResult: const DocumentCaptureResult.success([
            '/tmp/clinical_summary.pdf',
          ]),
        );
        List<String>? capturedImages;

        await tester.pumpWidget(
          _wrap(
            DocumentScanScreen(
              captureService: fakeService,
              onImagesCaptured: (images) => capturedImages = images,
              onCapture: () {},
              onSwitchToManual: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        final fileBtn = find.text('Import PDF or Document File');
        await tester.ensureVisible(fileBtn);
        await tester.tap(fileBtn);
        await tester.pumpAndSettle();

        expect(fakeService.filesCalls, 1);
        expect(capturedImages, ['/tmp/clinical_summary.pdf']);
        expect(find.text('1 Document File(s) Selected'), findsOneWidget);
      },
    );

    testWidgets(
      'displays warning card and message when camera permission is denied',
      (tester) async {
        _setViewport(tester);
        final fakeService = FakeDocumentCaptureService(
          scanResult: const DocumentCaptureResult.failure(
            DocumentCaptureFailure.permissionDenied(
              'Camera access was denied by user.',
            ),
          ),
        );

        await tester.pumpWidget(
          _wrap(
            DocumentScanScreen(
              captureService: fakeService,
              onCapture: () {},
              onSwitchToManual: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scanBtn = find.text('Start Document Scan');
        await tester.ensureVisible(scanBtn);
        await tester.tap(scanBtn);
        await tester.pumpAndSettle();

        expect(find.text('Action Required'), findsOneWidget);
        expect(
          find.text('Camera access was denied by user.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'handles user cancellation cleanly without showing error card',
      (tester) async {
        _setViewport(tester);
        final fakeService = FakeDocumentCaptureService(
          scanResult: const DocumentCaptureResult.canceled(),
        );

        await tester.pumpWidget(
          _wrap(
            DocumentScanScreen(
              captureService: fakeService,
              onCapture: () {},
              onSwitchToManual: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scanBtn = find.text('Start Document Scan');
        await tester.ensureVisible(scanBtn);
        await tester.tap(scanBtn);
        await tester.pumpAndSettle();

        expect(find.text('Action Required'), findsNothing);
        expect(find.text('Align document within frame'), findsOneWidget);
      },
    );

    testWidgets(
      'Proceed to Review triggers inferencePipeline and fires onExtractionComplete with extracted profile',
      (tester) async {
        _setViewport(tester);
        final fakeCapture = FakeDocumentCaptureService(
          scanResult: const DocumentCaptureResult.success(['/tmp/doc.jpg']),
        );
        final fakeInference = FakeDocumentInferencePipeline(
          result: const DocumentInferenceResult.success(
            ExtractedProfileData(
              firstName: 'Alex',
              lastName: 'Morgan',
              dateOfBirth: '1988-04-12',
              medications: ['Amoxicillin 500mg'],
              allergies: ['Penicillin'],
            ),
          ),
        );
        ExtractedProfileData? extractedData;

        await tester.pumpWidget(
          _wrap(
            DocumentScanScreen(
              captureService: fakeCapture,
              inferencePipeline: fakeInference,
              onExtractionComplete: (data) => extractedData = data,
              onCapture: () {},
              onSwitchToManual: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Scan document
        final scanBtn = find.text('Start Document Scan');
        await tester.ensureVisible(scanBtn);
        await tester.tap(scanBtn);
        await tester.pumpAndSettle();

        expect(find.text('Ready for OCR'), findsOneWidget);

        // 2. Tap Proceed to Review
        final proceedBtn = find.text('Proceed to Review');
        await tester.ensureVisible(proceedBtn);
        await tester.tap(proceedBtn);
        await tester.pumpAndSettle();

        expect(fakeInference.processCalls, 1);
        expect(fakeInference.lastProcessedFiles, ['/tmp/doc.jpg']);
        expect(extractedData?.name, 'Alex Morgan');
        expect(extractedData?.firstName, 'Alex');
        expect(extractedData?.lastName, 'Morgan');
        expect(extractedData?.medications, ['Amoxicillin 500mg']);
      },
    );

    testWidgets(
      'displays error card when inference fails during document extraction',
      (tester) async {
        _setViewport(tester);
        final fakeCapture = FakeDocumentCaptureService(
          scanResult: const DocumentCaptureResult.success(['/tmp/corrupted.jpg']),
        );
        final fakeInference = FakeDocumentInferencePipeline(
          result: const DocumentInferenceResult.failure(
            'Failed to decode model tensors.',
          ),
        );

        await tester.pumpWidget(
          _wrap(
            DocumentScanScreen(
              captureService: fakeCapture,
              inferencePipeline: fakeInference,
              onCapture: () {},
              onSwitchToManual: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Scan document
        final scanBtn = find.text('Start Document Scan');
        await tester.ensureVisible(scanBtn);
        await tester.tap(scanBtn);
        await tester.pumpAndSettle();

        // Proceed to Review
        final proceedBtn = find.text('Proceed to Review');
        await tester.ensureVisible(proceedBtn);
        await tester.tap(proceedBtn);
        await tester.pumpAndSettle();

        expect(fakeInference.processCalls, 1);
        expect(find.text('Action Required'), findsOneWidget);
        expect(find.text('Failed to decode model tensors.'), findsOneWidget);
      },
    );

    testWidgets(
      'displays error card and does not navigate when extracted data is empty',
      (tester) async {
        _setViewport(tester);
        final fakeCapture = FakeDocumentCaptureService(
          scanResult: const DocumentCaptureResult.success(['/tmp/blank.txt']),
        );
        final fakeInference = FakeDocumentInferencePipeline(
          result: const DocumentInferenceResult.success(ExtractedProfileData.empty),
        );
        var extractionCompleteCalled = false;

        await tester.pumpWidget(
          _wrap(
            DocumentScanScreen(
              captureService: fakeCapture,
              inferencePipeline: fakeInference,
              onExtractionComplete: (_) => extractionCompleteCalled = true,
              onCapture: () {},
              onSwitchToManual: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Scan document
        final scanBtn = find.text('Start Document Scan');
        await tester.ensureVisible(scanBtn);
        await tester.tap(scanBtn);
        await tester.pumpAndSettle();

        // Proceed to Review
        final proceedBtn = find.text('Proceed to Review');
        await tester.ensureVisible(proceedBtn);
        await tester.tap(proceedBtn);
        await tester.pumpAndSettle();

        expect(fakeInference.processCalls, 1);
        expect(extractionCompleteCalled, isFalse);
        expect(find.text('Action Required'), findsOneWidget);
        expect(
          find.text(
            'No clinical details could be identified in the document. Please try another document or enter details manually.',
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('ExtractedReviewScreen Tests', () {
    testWidgets('renders extracted profile card and fires confirm/edit', (
      tester,
    ) async {
      _setViewport(tester);
      var confirmCalled = false;
      var editCalled = false;

      await tester.pumpWidget(
        _wrap(
          ExtractedReviewScreen(
            extractedName: 'Alex Morgan',
            extractedDob: '1988-04-12',
            extractedMedication: 'Amoxicillin 500mg',
            extractedAllergy: 'Penicillin',
            onConfirm: () => confirmCalled = true,
            onEditManually: () => editCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile Overview'), findsOneWidget);
      expect(find.text('Alex Morgan'), findsOneWidget);
      expect(find.text('Amoxicillin 500mg'), findsOneWidget);
      expect(find.text('100% On-Device'), findsOneWidget);

      final confirmBtn = find.text('Confirm & Create Vault');
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      expect(confirmCalled, isTrue);

      final editBtn = find.text('Edit Details Manually');
      await tester.ensureVisible(editBtn);
      await tester.tap(editBtn);
      expect(editCalled, isTrue);
    });

    testWidgets('renders empty defaults when extracted data omitted', (
      tester,
    ) async {
      _setViewport(tester);

      await tester.pumpWidget(
        _wrap(ExtractedReviewScreen(onConfirm: () {}, onEditManually: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile Overview'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Date of Birth'), findsOneWidget);
    });
  });

  group('UserNameScreen Tests', () {
    testWidgets(
      'renders text field with microphone button and fires onContinue',
      (tester) async {
        _setViewport(tester);
        String? enteredName;
        var voiceInputCalled = false;

        await tester.pumpWidget(
          _wrap(
            UserNameScreen(
              onContinue: (name) => enteredName = name,
              onVoiceInput: () => voiceInputCalled = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Personal Identity'), findsOneWidget);

        final micFinder = find.bySemanticsLabel('Dictate name with voice');
        expect(micFinder, findsOneWidget);

        await tester.ensureVisible(micFinder);
        await tester.tap(micFinder);
        expect(voiceInputCalled, isTrue);

        final textField = find.byType(EditableText);
        await tester.enterText(textField, 'Jane Doe');
        await tester.pumpAndSettle();

        final continueBtn = find.text('Continue to Overview');
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        expect(enteredName, 'Jane Doe');
      },
    );

    testWidgets(
      'fallback voice simulation sets default name when onVoiceInput is null',
      (tester) async {
        _setViewport(tester);
        String? enteredName;

        await tester.pumpWidget(
          _wrap(UserNameScreen(onContinue: (name) => enteredName = name)),
        );
        await tester.pumpAndSettle();

        final micFinder = find.bySemanticsLabel('Dictate name with voice');
        await tester.ensureVisible(micFinder);
        await tester.tap(micFinder);
        await tester.pumpAndSettle();

        expect(find.text('Alex Morgan'), findsOneWidget);

        final continueBtn = find.text('Continue to Overview');
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        expect(enteredName, 'Alex Morgan');
      },
    );
  });
}
