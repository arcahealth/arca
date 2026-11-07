import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arca/core/onboarding/repositories/in_memory_onboarding_repository.dart';
import 'package:arca/core/onboarding/repositories/onboarding_repository.dart';
import 'package:arca/core/onboarding/repositories/shared_prefs_onboarding_repository.dart';

void main() {
  group('OnboardingRepository Tests', () {
    test(
      'InMemoryOnboardingRepository defaults to false and updates',
      () async {
        final OnboardingRepository repo = InMemoryOnboardingRepository();
        expect(await repo.hasCompletedOnboarding(), isFalse);

        await repo.setCompletedOnboarding(true);
        expect(await repo.hasCompletedOnboarding(), isTrue);
      },
    );

    test(
      'SharedPrefsOnboardingRepository persists completion in preferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final OnboardingRepository repo = SharedPrefsOnboardingRepository(
          prefs: prefs,
        );

        expect(await repo.hasCompletedOnboarding(), isFalse);

        await repo.setCompletedOnboarding(true);
        expect(await repo.hasCompletedOnboarding(), isTrue);
        expect(prefs.getBool('arca_onboarding_completed'), isTrue);
      },
    );
  });
}
