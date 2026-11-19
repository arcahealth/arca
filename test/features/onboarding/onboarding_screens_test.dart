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

      final captureBtn = find.text('Capture & Extract Details');
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
