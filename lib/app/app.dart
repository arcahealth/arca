import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaisel/kaisel.dart';

import '../core/database/database_manager.dart';
import '../core/database/database_service.dart';
import '../core/design_system/arca_design_system.dart';
import '../core/onboarding/repositories/onboarding_repository.dart';
import '../core/onboarding/repositories/shared_prefs_onboarding_repository.dart';
import 'router.dart';
import 'routes.dart';

sealed class const ArcaAppContainerState() {
  factory idle() = ArcaAppContainerIdle;
  factory init() = ArcaAppContainerInit;
  factory ready() = ArcaAppContainerReady;
  factory failure(String message) = ArcaAppContainerFailure;
}

final class const ArcaAppContainerIdle() extends ArcaAppContainerState;
final class const ArcaAppContainerInit() extends ArcaAppContainerState;
final class const ArcaAppContainerReady() extends ArcaAppContainerState;
final class const ArcaAppContainerFailure(final String message)
    extends ArcaAppContainerState;

final class ArcaAppContainer({
  this._onboardingRepository,
  this._databaseService,
  this._routerConfig,
}) {
  OnboardingRepository? _onboardingRepository;
  DatabaseService? _databaseService;
  KaiselRouterConfig<AppRoute>? _routerConfig;

  final ValueNotifier<ArcaAppContainerState> _state = .new(.idle());
  ValueNotifier<ArcaAppContainerState> get state => _state;

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

  KaiselRouterConfig<AppRoute> get routerConfig {
    _guardUninitialized();
    _guardNull('_routerConfig', _routerConfig);

    return _routerConfig!;
  }

  Future<void> init() async {
    if (_state.value is ArcaAppContainerInit ||
        _state.value is ArcaAppContainerReady) {
      return;
    }

    _state.value = .init();

    _onboardingRepository ??= SharedPrefsOnboardingRepository();
    _databaseService ??= DatabaseManager();

    await (
      _onboardingRepository!.hasCompletedOnboarding(),
      _databaseService!.initialize(),
    ).wait;

    _routerConfig ??= createAppRouter(initial: const WelcomeRoute());

    _state.value = .ready();
  }

  void _guardUninitialized() {
    if (_state.value is ArcaAppContainerIdle ||
        _state.value is ArcaAppContainerInit) {
      throw StateError(
        "Tried to access property in `${_state.value.runtimeType}` state."
        "\n"
        "Make sure ArcaAppContainer is initialized via `init()` method and awaited properly.",
      );
    } else if (_state.value is ArcaAppContainerFailure) {
      _state.value = .failure(
        "App failed to setup and launch dependencies properly.",
      );
    }
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

/// Composition root for Arca.
///
/// Injects core dependencies at the application edge.
final class const ArcaApp({super.key, final ArcaAppContainer? appContainer})
    extends StatefulWidget {
  @override
  State<ArcaApp> createState() => _ArcaAppState();
}

class _ArcaAppState extends State<ArcaApp> {
  late final ArcaAppContainer _appContainer;

  @override
  void initState() {
    super.initState();

    _appContainer = widget.appContainer ?? ArcaAppContainer();

    _appContainer.init();
  }

  @override
  void dispose() {
    _appContainer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ArcaAppContainerState>(
      valueListenable: _appContainer.state,
      builder: (context, state, child) {
        return switch (state) {
          ArcaAppContainerReady _ when child != null => child,
          _ => WidgetsApp(
            color: ArcaColors.primary,
            textStyle: ArcaTypography.bodyMedium,
            pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, _, _) => builder(context),
            ),
            home: const ArcaScaffold(body: Center(child: Text("Arca"))),
          ),
        };
      },
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ArcaAppContainer>.value(value: _appContainer),
          RepositoryProvider<DatabaseService>.value(
            value: _appContainer.databaseService,
          ),
          RepositoryProvider<OnboardingRepository>.value(
            value: _appContainer.onboardingRepository,
          ),
        ],
        child: WidgetsApp.router(
          color: ArcaColors.primary,
          textStyle: ArcaTypography.bodyMedium,
          routerConfig: _appContainer.routerConfig,
          title: 'Arca',
        ),
      ),
    );
  }
}
