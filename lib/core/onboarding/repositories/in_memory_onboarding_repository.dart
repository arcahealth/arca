import 'onboarding_repository.dart';

/// In-memory implementation of [OnboardingRepository] for tests and previews.
class InMemoryOnboardingRepository({bool hasCompletedOnboarding = false})
    implements OnboardingRepository {
  bool _hasCompleted = hasCompletedOnboarding;

  @override
  Future<bool> hasCompletedOnboarding() async => _hasCompleted;

  @override
  Future<void> setCompletedOnboarding(bool completed) async {
    _hasCompleted = completed;
  }
}
