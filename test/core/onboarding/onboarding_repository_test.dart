import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arca/core/onboarding/repositories/onboarding_repository.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../test_utils/shared_preferences.dart';

void main() {
  group('OnboardingRepository Tests', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance = MockSharedPreferencesAsync();
    });

    tearDown(() {
      SharedPreferencesAsyncPlatform.instance = null;
    });

    test(
      'SharedPrefsOnboardingRepository defaults to false and updates',
      () async {
        final OnboardingRepository repo = SharedPrefsOnboardingRepository();
        expect(await repo.hasCompletedOnboarding(), isFalse);

        await repo.setCompletedOnboarding(true);
        expect(await repo.hasCompletedOnboarding(), isTrue);

        expect(SharedPreferencesAsyncPlatform.instance, isNotNull);
        expect(
          SharedPreferencesAsyncPlatform.instance,
          isA<MockSharedPreferencesAsync>(),
        );
        expect(
          (SharedPreferencesAsyncPlatform.instance
                  as MockSharedPreferencesAsync)
              .log,
          orderedEquals(<Matcher>[
            isMethodCall(
              'getBool',
              arguments: [SharedPrefsOnboardingRepository.initialOnboardingKey],
            ),
            isMethodCall(
              'setBool',
              arguments: [
                SharedPrefsOnboardingRepository.initialOnboardingKey,
                true,
              ],
            ),
            isMethodCall(
              'getBool',
              arguments: [SharedPrefsOnboardingRepository.initialOnboardingKey],
            ),
          ]),
        );
      },
    );

    test(
      'SharedPrefsOnboardingRepository persists completion in preferences',
      () async {
        final OnboardingRepository repo = SharedPrefsOnboardingRepository();
        final prefs = SharedPreferencesAsync();

        expect(await repo.hasCompletedOnboarding(), isFalse);

        await repo.setCompletedOnboarding(true);
        final (repoOnboarding, prefsOnboarding) = await (
          repo.hasCompletedOnboarding(),
          prefs.getBool(SharedPrefsOnboardingRepository.initialOnboardingKey),
        ).wait;

        expect(repoOnboarding, equals(prefsOnboarding));
        expect(SharedPreferencesAsyncPlatform.instance, isNotNull);
        expect(
          SharedPreferencesAsyncPlatform.instance,
          isA<MockSharedPreferencesAsync>(),
        );
        expect(
          (SharedPreferencesAsyncPlatform.instance
                  as MockSharedPreferencesAsync)
              .log,
          orderedEquals(<Matcher>[
            isMethodCall(
              'getBool',
              arguments: [SharedPrefsOnboardingRepository.initialOnboardingKey],
            ),
            isMethodCall(
              'setBool',
              arguments: [
                SharedPrefsOnboardingRepository.initialOnboardingKey,
                true,
              ],
            ),
            isMethodCall(
              'getBool',
              arguments: [SharedPrefsOnboardingRepository.initialOnboardingKey],
            ),
            isMethodCall(
              'getBool',
              arguments: [SharedPrefsOnboardingRepository.initialOnboardingKey],
            ),
          ]),
        );
      },
    );
  });
}
