import 'package:arca/app/router/router.dart';
import 'package:arca/core/onboarding/repositories/onboarding_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeOnboardingRepository implements OnboardingRepository {
  bool completed;
  _FakeOnboardingRepository({this.completed = false});

  @override
  Future<bool> hasCompletedOnboarding() async => completed;

  @override
  Future<void> setCompletedOnboarding(bool completed) async {
    this.completed = completed;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ArcaRouteGuards', () {
    test('allows OnboardingMount when onboarding is incomplete', () async {
      final repo = _FakeOnboardingRepository(completed: false);
      final guard = ArcaRouteGuards.onboarding(repo);

      final result = await guard([], const [OnboardingMount()]);
      expect(result, equals(const [OnboardingMount()]));
    });

    test('allows navigation when onboarding is complete', () async {
      final repo = _FakeOnboardingRepository(completed: true);
      final guard = ArcaRouteGuards.onboarding(repo);

      final result = await guard([], const [OnboardingMount()]);
      expect(result, equals(const [OnboardingMount()]));
    });

    test('ArcaRouter.create builds with onboarding guard wired', () {
      final repo = _FakeOnboardingRepository(completed: false);
      final config = ArcaRouter.create(repo);

      expect(config, isNotNull);
      expect(config.router.stack, equals(const [OnboardingMount()]));
    });
  });
}
