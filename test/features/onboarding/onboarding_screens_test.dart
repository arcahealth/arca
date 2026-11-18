import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arca/features/onboarding/presentation/screens/screens.dart';

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void _setViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('WelcomeScreen Tests', () {
    testWidgets('renders display title and fires onStart/onSkip callbacks', (
      tester,
    ) async {
      _setViewport(tester);
      var startCalled = false;
      var skipCalled = false;

      await tester.pumpWidget(
        _wrap(
          WelcomeScreen(
            onStart: () => startCalled = true,
            onSkip: () => skipCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Arca'), findsOneWidget);
      expect(
        find.textContaining('Your private, offline-first health vault'),
        findsOneWidget,
      );

      final startBtn = find.text('Get Started →');
      await tester.ensureVisible(startBtn);
      await tester.tap(startBtn);
      expect(startCalled, isTrue);

      final skipBtn = find.text('Skip Setup');
      await tester.ensureVisible(skipBtn);
      await tester.tap(skipBtn);
      expect(skipCalled, isTrue);
    });
  });

  group('SetupChoiceScreen Tests', () {
    testWidgets(
      'renders fork options and fires onChooseAuto / onChooseManual',
      (tester) async {
        _setViewport(tester);
        var autoCalled = false;
        var manualCalled = false;
        var backCalled = false;

        await tester.pumpWidget(
          _wrap(
            SetupChoiceScreen(
              onChooseAuto: () => autoCalled = true,
              onChooseManual: () => manualCalled = true,
              onBack: () => backCalled = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Choose Setup Mode'), findsOneWidget);
        expect(find.text('Automatic Setup'), findsOneWidget);
        expect(find.text('Manual Setup'), findsOneWidget);

        final autoBtn = find.text('Scan Document →');
        await tester.ensureVisible(autoBtn);
        await tester.tap(autoBtn);
        expect(autoCalled, isTrue);

        final manualBtn = find.text('Enter Manually →');
        await tester.ensureVisible(manualBtn);
        await tester.tap(manualBtn);
        expect(manualCalled, isTrue);

        final backBtn = find.text('←');
        await tester.ensureVisible(backBtn);
        await tester.tap(backBtn);
        expect(backCalled, isTrue);
      },
    );
  });

  group('AiPrepScreen Tests', () {
    testWidgets('renders model status indicators and fires onReady', (
      tester,
    ) async {
      _setViewport(tester);
      var readyCalled = false;
      var backCalled = false;

      await tester.pumpWidget(
        _wrap(
          AiPrepScreen(
            onReady: () => readyCalled = true,
            onBack: () => backCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('On-Device Intelligence'), findsOneWidget);
      expect(find.text('Local OCR Engine'), findsOneWidget);
      expect(find.text('PII Sanitizer & Vault Redactor'), findsOneWidget);
      expect(find.text('Clinical Voice ASR'), findsOneWidget);

      final readyBtn = find.text('Proceed to Document Capture →');
      await tester.ensureVisible(readyBtn);
      await tester.tap(readyBtn);
      expect(readyCalled, isTrue);

      final backBtn = find.text('←');
      await tester.ensureVisible(backBtn);
      await tester.tap(backBtn);
      expect(backCalled, isTrue);
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

      final captureBtn = find.text('Capture & Extract Details →');
      await tester.ensureVisible(captureBtn);
      await tester.tap(captureBtn);
      expect(captureCalled, isTrue);

      final manualBtn = find.text('Enter Details Manually Instead');
      await tester.ensureVisible(manualBtn);
      await tester.tap(manualBtn);
      expect(manualCalled, isTrue);
    });
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

      expect(find.text('Review Profile'), findsOneWidget);
      expect(find.text('Alex Morgan'), findsOneWidget);
      expect(find.text('Amoxicillin 500mg'), findsOneWidget);
      expect(find.text('100% On-Device'), findsOneWidget);

      final confirmBtn = find.text('Confirm & Create Vault →');
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      expect(confirmCalled, isTrue);

      final editBtn = find.text('Adjust Manually');
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

      expect(find.text('Review Profile'), findsOneWidget);
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

        expect(find.text('What should Arca call you?'), findsOneWidget);

        final micFinder = find.bySemanticsLabel('Dictate name with voice');
        expect(micFinder, findsOneWidget);

        await tester.ensureVisible(micFinder);
        await tester.tap(micFinder);
        expect(voiceInputCalled, isTrue);

        final textField = find.byType(EditableText);
        await tester.enterText(textField, 'Jane Doe');
        await tester.pumpAndSettle();

        final continueBtn = find.text('Complete Setup & Create Vault →');
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

        final continueBtn = find.text('Complete Setup & Create Vault →');
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        expect(enteredName, 'Alex Morgan');
      },
    );
  });
}
