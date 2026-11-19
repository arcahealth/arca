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
  final module = OnboardingModule(repo, onCompleted);

  final routerConfig = KaiselRouterConfig<OnboardingRoute>(
    initial: const OnboardingRoute.welcome(),
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
      'navigates through streamlined scan flow with bundled AI to overview and completion',
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
        expect(find.text('ARCA'), findsOneWidget);
        expect(
          find.text('Your medical records.\nEncrypted on your device.'),
          findsOneWidget,
        );
        final scanBtn = find.text('Scan Document');
        await tester.ensureVisible(scanBtn);
        await tester.tap(scanBtn);
        await tester.pumpAndSettle();

        // Screen 2: Document Scan Screen (Bundled RapidOCR)
        expect(find.text('Scan Document'), findsOneWidget);
        expect(find.text('Bundled RapidOCR'), findsOneWidget);
        final captureBtn = find.text('Capture & Extract Details');
        await tester.ensureVisible(captureBtn);
        await tester.tap(captureBtn);
        await tester.pumpAndSettle();

        // Screen 3: Overview Screen (with edit and confirm)
        expect(find.text('Profile Overview'), findsOneWidget);
        expect(find.text('100% On-Device'), findsOneWidget);
        final confirmBtn = find.text('Confirm & Create Vault');
        await tester.ensureVisible(confirmBtn);
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        expect(repo.completed, isTrue);
        expect(completedCalled, isTrue);
      },
    );

    testWidgets(
      'navigates through manual flow with text/voice to overview and completion',
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
        final manualBtn = find.text('Enter Manually');
        await tester.ensureVisible(manualBtn);
        await tester.tap(manualBtn);
        await tester.pumpAndSettle();

        // Screen 2: User Name Screen (Information gathering)
        expect(find.text('Personal Identity'), findsOneWidget);
        final micFinder = find.bySemanticsLabel('Dictate name with voice');
        await tester.ensureVisible(micFinder);
        await tester.tap(micFinder);
        await tester.pumpAndSettle();

        final continueBtn = find.text('Continue to Overview');
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        // Screen 3: Overview Screen
        expect(find.text('Profile Overview'), findsOneWidget);
        expect(find.text('Alex Morgan'), findsOneWidget);

        final confirmBtn = find.text('Confirm & Create Vault');
        await tester.ensureVisible(confirmBtn);
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        expect(repo.completed, isTrue);
        expect(completedCalled, isTrue);
      },
    );

    testWidgets('allows editing details from overview back to manual entry', (
      tester,
    ) async {
      _setViewport(tester);
      final repo = FakeOnboardingRepository();

      await tester.pumpWidget(_buildOnboardingApp(repo: repo));
      await tester.pumpAndSettle();

      // Welcome -> Scan -> Overview
      final scanBtn = find.text('Scan Document');
      await tester.ensureVisible(scanBtn);
      await tester.tap(scanBtn);
      await tester.pumpAndSettle();

      final captureBtn = find.text('Capture & Extract Details');
      await tester.ensureVisible(captureBtn);
      await tester.tap(captureBtn);
      await tester.pumpAndSettle();

      expect(find.text('Profile Overview'), findsOneWidget);

      // Tap Edit Details Manually
      final editBtn = find.text('Edit Details Manually');
      await tester.ensureVisible(editBtn);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Should open manual entry with prefilled name
      expect(find.text('Personal Identity'), findsOneWidget);
      expect(find.text('Alex Morgan'), findsOneWidget);
    });
  });
}
