import 'package:arca/app/router/router.dart';
import 'package:arca/core/design_system/arca_design_system.dart';
import 'package:arca/core/onboarding/repositories/onboarding_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeOnboardingRepository implements OnboardingRepository {
  bool completed = false;

  @override
  Future<bool> hasCompletedOnboarding() async => completed;

  @override
  Future<void> setCompletedOnboarding(bool completed) async {
    this.completed = completed;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'ArcaRouter.create mounts OnboardingModule without rebuild loop and navigates',
    (tester) async {
      final repo = _FakeOnboardingRepository();
      final routerConfig = ArcaRouter.create(repo);

      await tester.pumpWidget(
        WidgetsApp.router(
          color: ArcaColors.primary,
          routerConfig: routerConfig,
        ),
      );

      // Must settle cleanly without microtask infinite loop
      await tester.pumpAndSettle();

      expect(find.text('ARCA'), findsOneWidget);
      expect(
        find.text('Your medical records.\nEncrypted on your device.'),
        findsOneWidget,
      );

      final startBtn = find.text('Get Started');
      expect(startBtn, findsOneWidget);
      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      expect(find.text('Choose Setup Mode'), findsOneWidget);
    },
  );
}
