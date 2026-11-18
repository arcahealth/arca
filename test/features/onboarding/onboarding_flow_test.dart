import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaisel/kaisel.dart';

import 'package:arca/app/router/onboarding_routes.dart';
import 'package:arca/core/design_system/arca_design_system.dart';
import 'package:arca/core/onboarding/repositories/onboarding_repository.dart';

final class FakeOnboardingRepository implements OnboardingRepository {
  bool completed = false;

  @override
  Future<bool> hasCompletedOnboarding() async => completed;

  @override
  Future<void> setCompletedOnboarding(bool value) async {
    completed = value;
  }
}

Widget _buildOnboardingApp({
  required OnboardingRepository repo,
  VoidCallback? onCompleted,
}) {
  final module = OnboardingModule(
    onboardingRepo: repo,
    onCompleted: onCompleted,
  );

  final routerConfig = KaiselRouterConfig<OnboardingRoute>(
    initial: const OnboardingWelcome(),
    builder: (context, route) => module.buildPage(context, route),
  );

  return WidgetsApp.router(
    color: ArcaColors.primary,
    routerConfig: routerConfig,
  );
}

void _setViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding Flow Navigation Tests', () {
    testWidgets(
      'navigates through inverted automatic scan flow to completion',
      (tester) async {
        _setViewport(tester);
        final repo = FakeOnboardingRepository();
        var completedCalled = false;

        await tester.pumpWidget(
          _buildOnboardingApp(
            repo: repo,
            onCompleted: () => completedCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        // Screen 1: Welcome Screen
        expect(find.text('Welcome to Arca'), findsOneWidget);
        final startBtn = find.text('Get Started →');
        await tester.ensureVisible(startBtn);
        await tester.tap(startBtn);
        await tester.pumpAndSettle();

        // Screen 2: Setup Choice Screen
        expect(find.text('Choose Setup Mode'), findsOneWidget);
        final scanBtn = find.text('Scan Document →');
        await tester.ensureVisible(scanBtn);
        await tester.tap(scanBtn);
        await tester.pumpAndSettle();

        // Screen 3A: AI Preparation Screen
        expect(find.text('On-Device Intelligence'), findsOneWidget);
        final proceedBtn = find.text('Proceed to Document Capture →');
        await tester.ensureVisible(proceedBtn);
        await tester.tap(proceedBtn);
        await tester.pumpAndSettle();

        // Screen 4A: Document Scan Screen
        expect(find.text('Scan Document'), findsOneWidget);
        final captureBtn = find.text('Capture & Extract Details →');
        await tester.ensureVisible(captureBtn);
        await tester.tap(captureBtn);
        await tester.pumpAndSettle();

        // Screen 5A: Extracted Review Screen
        expect(find.text('Review Profile'), findsOneWidget);
        expect(find.text('Alex Morgan'), findsOneWidget);
        final confirmBtn = find.text('Confirm & Create Vault →');
        await tester.ensureVisible(confirmBtn);
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        expect(repo.completed, isTrue);
        expect(completedCalled, isTrue);
      },
    );

    testWidgets('navigates through manual flow with text/voice to completion', (
      tester,
    ) async {
      _setViewport(tester);
      final repo = FakeOnboardingRepository();
      var completedCalled = false;

      await tester.pumpWidget(
        _buildOnboardingApp(
          repo: repo,
          onCompleted: () => completedCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      // Screen 1: Welcome Screen
      final startBtn = find.text('Get Started →');
      await tester.ensureVisible(startBtn);
      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      // Screen 2: Setup Choice Screen
      expect(find.text('Choose Setup Mode'), findsOneWidget);
      final manualBtn = find.text('Enter Manually →');
      await tester.ensureVisible(manualBtn);
      await tester.tap(manualBtn);
      await tester.pumpAndSettle();

      // Screen 3B: Manual Name Screen
      expect(find.text('What should Arca call you?'), findsOneWidget);
      final micFinder = find.bySemanticsLabel('Dictate name with voice');
      await tester.ensureVisible(micFinder);
      await tester.tap(micFinder);
      await tester.pumpAndSettle();

      final continueBtn = find.text('Continue →');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Screen 4B: Manual Vitals Screen
      expect(find.text('Basic Vitals'), findsOneWidget);
      final finishBtn = find.text('Complete Setup & Create Vault →');
      await tester.ensureVisible(finishBtn);
      await tester.tap(finishBtn);
      await tester.pumpAndSettle();

      expect(repo.completed, isTrue);
      expect(completedCalled, isTrue);
    });
  });
}
