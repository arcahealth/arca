import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_repository.dart';

/// SharedPreferences persistence for [OnboardingRepository].
class SharedPrefsOnboardingRepository implements OnboardingRepository {
  SharedPrefsOnboardingRepository({this.prefs});

  SharedPreferences? prefs;

  static const String _prefKey = 'arca_onboarding_completed';

  Future<SharedPreferences> _getPrefs() async {
    final cached = prefs;
    if (cached != null) return cached;
    final instance = await SharedPreferences.getInstance();
    prefs = instance;
    return instance;
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    final instance = await _getPrefs();
    return instance.getBool(_prefKey) ?? false;
  }

  @override
  Future<void> setCompletedOnboarding(bool completed) async {
    final instance = await _getPrefs();
    await instance.setBool(_prefKey, completed);
  }
}
