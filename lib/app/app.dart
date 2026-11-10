import 'package:arca/core/database/database_manager.dart';
import 'package:arca/core/design_system/arca_design_system.dart';
import 'package:arca/core/onboarding/repositories/shared_prefs_onboarding_repository.dart';
import 'package:arca/core/vault/repositories/sqlite_vault_repository.dart';
import 'package:arca/features/journal/data/repositories/sqlite_journal_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaisel/kaisel.dart';

import '../core/ai/models/ai_model.dart';
import '../core/database/database_service.dart';
import '../core/downloader/services/download_manager.dart';
import '../core/downloader/services/download_service.dart';
import '../core/onboarding/repositories/onboarding_repository.dart';
import '../core/vault/repositories/vault_repository.dart';
import '../features/journal/domain/repositories/journal_repository.dart';
import '../features/journal/presentation/bloc/journal_bloc.dart';
import '../features/journal/presentation/bloc/journal_event.dart';
import '../features/model_downloader/presentation/bloc/model_downloader_bloc.dart';
import '../features/setup_wizard/presentation/bloc/setup_wizard_bloc.dart';
import '../features/vaults/presentation/bloc/vault_bloc.dart';
import '../features/vaults/presentation/bloc/vault_event.dart';
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
  this._vaultRepository,
  this._journalRepository,
  this._modelDownloadService,
  this._databaseService,
  this._routerConfig,
}) {
  OnboardingRepository? _onboardingRepository;
  DownloadService<AIKind, AIKind>? _modelDownloadService;
  DatabaseService? _databaseService;
  VaultRepository? _vaultRepository;
  JournalRepository? _journalRepository;
  KaiselRouterConfig<AppRoute>? _routerConfig;

  final ValueNotifier<ArcaAppContainerState> _state = .new(.idle());
  ValueNotifier<ArcaAppContainerState> get state => _state;

  OnboardingRepository get onboardingRepository {
    _guardUninitialized();
    _guardNull('_onboardingRepository', _onboardingRepository);

    return _onboardingRepository!;
  }

  VaultRepository get vaultRepository {
    _guardUninitialized();
    _guardNull('_vaultRepository', _vaultRepository);

    return _vaultRepository!;
  }

  JournalRepository get journalRepository {
    _guardUninitialized();
    _guardNull('_journalRepository', _journalRepository);

    return _journalRepository!;
  }

  DatabaseService get databaseService {
    _guardUninitialized();
    _guardNull('_databaseService', _databaseService);

    return _databaseService!;
  }

  DownloadService<AIKind, AIKind> get modelDownloadService {
    _guardUninitialized();
    _guardNull('_modelDownloadService', _modelDownloadService);

    return _modelDownloadService!;
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
    _modelDownloadService ??= DownloadManager();
    _databaseService ??= DatabaseManager();

    final (completedOnboarding, _) = await (
      _onboardingRepository!.hasCompletedOnboarding(),
      _databaseService!.initialize(),
    ).wait;

    // Initialize dependent repositories and services
    final db = _databaseService!.db;

    _vaultRepository ??= SqliteVaultRepository(db: db);
    _journalRepository ??= SqliteJournalRepository(db: db);

    final initialRoute = switch (completedOnboarding) {
      true => const JournalRoute(),
      false => const WelcomeRoute(),
    };

    _routerConfig ??= createAppRouter(
      journalRepository: _journalRepository!,
      vaultRepository: _vaultRepository!,
      onboardingRepository: _onboardingRepository!,
      initial: initialRoute,
    );

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
/// Injects core domain repositories and feature BLoCs at the application edge.
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
            home: ArcaScaffold(body: Center(child: Text("Arca"))),
          ),
        };
      },
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ArcaAppContainer>.value(value: _appContainer),
          RepositoryProvider<DatabaseService>.value(
            value: _appContainer.databaseService,
          ),
          RepositoryProvider<JournalRepository>.value(
            value: _appContainer.journalRepository,
          ),
          RepositoryProvider<VaultRepository>.value(
            value: _appContainer.vaultRepository,
          ),
          RepositoryProvider<OnboardingRepository>.value(
            value: _appContainer.onboardingRepository,
          ),
          RepositoryProvider<DownloadService<AIKind, AIKind>>.value(
            value: _appContainer.modelDownloadService,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<VaultBloc>(
              create: (_) =>
                  VaultBloc(repository: _appContainer.vaultRepository)
                    ..add(const VaultLoadRequested()),
            ),
            BlocProvider<JournalBloc>(
              create: (_) =>
                  JournalBloc(repository: _appContainer.journalRepository)
                    ..add(const JournalLoadRequested()),
            ),
            BlocProvider<SetupWizardBloc>(
              create: (_) => SetupWizardBloc(
                vaultRepository: _appContainer.vaultRepository,
                onboardingRepository: _appContainer.onboardingRepository,
                modelDownloadService: _appContainer.modelDownloadService,
              ),
            ),
            BlocProvider<ModelDownloaderBloc>(
              create: (_) => ModelDownloaderBloc(
                service: _appContainer.modelDownloadService,
              ),
            ),
          ],
          child: WidgetsApp.router(
            color: ArcaColors.primary,
            textStyle: ArcaTypography.bodyMedium,
            routerConfig: _appContainer.routerConfig,
            title: 'Arca',
          ),
        ),
      ),
    );
  }
}
