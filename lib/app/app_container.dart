import 'package:arca/app/router/router.dart';
import 'package:arca/core/database/database_manager.dart';
import 'package:arca/core/database/database_service.dart';
import 'package:arca/core/onboarding/onboarding.dart';
import 'package:flutter/foundation.dart';
import 'package:kaisel/kaisel.dart';

enum ArcaContainerState { idle, preparing, ready, failure }

final class ArcaContainer({
  this._onboardingRepository,
  this._databaseService,
  this._routerConfig,
}) {
  OnboardingRepository? _onboardingRepository;
  DatabaseService? _databaseService;
  KaiselRouterConfig<ArcaRoute>? _routerConfig;

  final ValueNotifier<ArcaContainerState> _state = .new(.idle);
  ValueListenable<ArcaContainerState> get state => _state;

  OnboardingRepository get onboardingRepository {
    _guardUninitialized();

    return _onboardingRepository!;
  }

  DatabaseService get databaseService {
    _guardUninitialized();

    return _databaseService!;
  }

  KaiselRouterConfig<ArcaRoute> get routerConfig {
    _guardUninitialized();

    return _routerConfig!;
  }

  Future<void> init() async {
    if (_state.value == .preparing || _state.value == .ready) {
      return;
    }

    _state.value = .preparing;

    try {
      _onboardingRepository ??= SharedPrefsOnboardingRepository();
      _databaseService ??= DatabaseManager();

      await (
        _onboardingRepository!.hasCompletedOnboarding(),
        _databaseService!.initialize(),
      ).wait;

      _routerConfig ??= createAppRouter(initial: const .onboarding());

      _state.value = .ready;
    } catch (_) {
      _state.value = .failure;
    }
  }

  void _guardUninitialized() {
    if (_state.value == .ready) return;

    throw StateError(
      "Tried to access property in `${_state.value}` state."
      "\n"
      "Make sure ArcaContainer is initialized via `init()` method and awaited properly.",
    );
  }

  void dispose() {
    _state.dispose();
  }
}
