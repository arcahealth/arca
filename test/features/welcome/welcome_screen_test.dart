import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arca/features/welcome/presentation/screens/welcome_screen.dart';

void main() {
  group('WelcomeScreen Tests', () {
    testWidgets(
      'renders value pillars and triggers constructor callbacks on CTA tap',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        var startSetupCalled = false;
        var skipCalled = false;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: WelcomeScreen(
              onStartSetup: () => startSetupCalled = true,
              onSkip: () => skipCalled = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Welcome to Arca'), findsOneWidget);
        expect(find.text('100% On-Device & Private'), findsOneWidget);
        expect(find.text('Isolated Family Health Vaults'), findsOneWidget);
        expect(find.text('Edge AI Intelligence'), findsOneWidget);

        final startButton = find.text('Start Setup Wizard →');
        await tester.ensureVisible(startButton);
        await tester.tap(startButton);
        expect(startSetupCalled, isTrue);

        final skipButton = find.text('Skip Setup & Quick Start');
        await tester.ensureVisible(skipButton);
        await tester.tap(skipButton);
        expect(skipCalled, isTrue);
      },
    );
  });
}
