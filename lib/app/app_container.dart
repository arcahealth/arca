import 'package:arca/app/router/router.dart';
import 'package:arca/core/database/database_manager.dart';
import 'package:arca/core/database/database_service.dart';
import 'package:arca/core/onboarding/onboarding.dart';
import 'package:flutter/foundation.dart';
import 'package:kaisel/kaisel.dart';

enum ArcaContainerState { idle, init, ready, failure }

final class ArcaContainer({
  this._onboardingRepository,
  this._databaseService,
  this._routerConfig,
}) {
  OnboardingRepository? _onboardingRepository;
  DatabaseService? _databaseService;
  KaiselRouterConfig<ArcaRoute>? _routerConfig;

  final ValueNotifier<ArcaContainerState> _state = .new(.idle);
  ValueNotifier<ArcaContainerState> get state => _state;

  OnboardingRepository get onboardingRepository {
    _guardUninitialized();
    _guardNull('_onboardingRepository', _onboardingRepository);

    return _onboardingRepository!;
  }

  DatabaseService get databaseService {
    _guardUninitialized();
    _guardNull('_databaseService', _databaseService);

    return _databaseService!;
  }

  KaiselRouterConfig<ArcaRoute> get routerConfig {
    _guardUninitialized();
    _guardNull('_routerConfig', _routerConfig);

    return _routerConfig!;
  }

  Future<void> init() async {
    if (_state.value == .init || _state.value == .ready) {
      return;
    }

    _state.value = .init;

    _onboardingRepository ??= SharedPrefsOnboardingRepository();
    _databaseService ??= DatabaseManager();

    await (
      _onboardingRepository!.hasCompletedOnboarding(),
      _databaseService!.initialize(),
    ).wait;

    _routerConfig ??= createAppRouter(initial: const .onboarding());

    _state.value = .ready;
  }

  void _guardUninitialized() {
    if (state.value == .ready) return;

    throw StateError(
      "Tried to access property in `${_state.value.runtimeType}` state."
      "\n"
      "Make sure ArcaAppContainer is initialized via `init()` method and awaited properly.",
    );
  }

  void _guardNull<T>(String name, T? property) {
    if (property != null) return;

    throw StateError(
      "Access to $name property is not allowed in null state."
      "\n"
      "Make sure ArcaAppContainer is initialized via `init()` method and awaited properly.",
    );
  }

  void dispose() {
    _state.dispose();
  }
}
