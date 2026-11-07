/// Core repository contract managing user onboarding state.
abstract interface class OnboardingRepository {
  /// Returns whether the initial onboarding flow has been completed.
  Future<bool> hasCompletedOnboarding();

  /// Persists the onboarding completion status.
  Future<void> setCompletedOnboarding(bool completed);
}
