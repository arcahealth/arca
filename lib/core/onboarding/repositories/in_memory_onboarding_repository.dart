import 'onboarding_repository.dart';

/// In-memory implementation of [OnboardingRepository] for tests and previews.
class InMemoryOnboardingRepository implements OnboardingRepository {
  InMemoryOnboardingRepository({bool hasCompletedOnboarding = false})
    : _hasCompleted = hasCompletedOnboarding;

  bool _hasCompleted;

  @override
  Future<bool> hasCompletedOnboarding() async => _hasCompleted;

  @override
  Future<void> setCompletedOnboarding(bool completed) async {
    _hasCompleted = completed;
  }
}
