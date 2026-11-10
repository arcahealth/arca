import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_repository.dart';

/// SharedPreferences persistence for [OnboardingRepository].
final class SharedPrefsOnboardingRepository([SharedPreferencesAsync? prefs])
    implements OnboardingRepository {
  this : _prefs = prefs ?? SharedPreferencesAsync();

  @visibleForTesting
  static const String initialOnboardingKey = 'arca_onboarded_initial';

  SharedPreferencesAsync _prefs;

  @override
  Future<bool> hasCompletedOnboarding() async {
    final val = await _prefs.getBool(initialOnboardingKey);
    return val ?? false;
  }

  @override
  Future<void> setCompletedOnboarding(bool completed) async {
    await _prefs.setBool(initialOnboardingKey, completed);
  }
}
