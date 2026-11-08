import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaisel/kaisel.dart';

import '../core/database/database_service.dart';
import '../core/design_system/tokens/tokens.dart';
import '../core/model_downloader/services/model_download_manager.dart';
import '../core/model_downloader/services/model_download_service.dart';
import '../core/onboarding/repositories/in_memory_onboarding_repository.dart';
import '../core/onboarding/repositories/onboarding_repository.dart';
import '../core/vault/repositories/in_memory_vault_repository.dart';
import '../core/vault/repositories/vault_repository.dart';
import '../features/journal/data/repositories/in_memory_journal_repository.dart';
import '../features/journal/domain/repositories/journal_repository.dart';
import '../features/journal/presentation/bloc/journal_bloc.dart';
import '../features/journal/presentation/bloc/journal_event.dart';
import '../features/model_downloader/presentation/bloc/model_downloader_bloc.dart';
import '../features/setup_wizard/presentation/bloc/setup_wizard_bloc.dart';
import '../features/vaults/presentation/bloc/vault_bloc.dart';
import '../features/vaults/presentation/bloc/vault_event.dart';
import 'router.dart';
import 'routes.dart';

/// Composition root for Arca.
///
/// Injects core domain repositories and feature BLoCs at the application edge.
class const ArcaApp({
  super.key,
  final JournalRepository? journalRepository,
  final VaultRepository? vaultRepository,
  final OnboardingRepository? onboardingRepository,
  final ModelDownloadService? modelDownloadService,
  final DatabaseService? databaseService,
  final KaiselRouterConfig<AppRoute>? routerConfig,
  final AppRoute? initialRoute,
}) extends StatefulWidget {
  @override
  State<ArcaApp> createState() => _ArcaAppState();
}

class _ArcaAppState extends State<ArcaApp> {
  late final JournalRepository _journalRepository;
  late final VaultRepository _vaultRepository;
  late final OnboardingRepository _onboardingRepository;
  late final ModelDownloadService _modelDownloadService;
  late final DatabaseService? _databaseService;
  late final KaiselRouterConfig<AppRoute> _routerConfig;

  @override
  void initState() {
    super.initState();
    _databaseService = widget.databaseService;
    _journalRepository =
        widget.journalRepository ?? InMemoryJournalRepository();
    _vaultRepository = widget.vaultRepository ?? InMemoryVaultRepository();
    _onboardingRepository =
        widget.onboardingRepository ??
        InMemoryOnboardingRepository(hasCompletedOnboarding: true);
    _modelDownloadService =
        widget.modelDownloadService ?? ModelDownloadManager();

    _routerConfig =
        widget.routerConfig ??
        createAppRouter(
          repository: _journalRepository,
          vaultRepository: _vaultRepository,
          onboardingRepository: _onboardingRepository,
          initial: widget.initialRoute ?? const JournalRoute(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        if (_databaseService != null)
          RepositoryProvider<DatabaseService>.value(value: _databaseService),
        RepositoryProvider<JournalRepository>.value(value: _journalRepository),
        RepositoryProvider<VaultRepository>.value(value: _vaultRepository),
        RepositoryProvider<OnboardingRepository>.value(
          value: _onboardingRepository,
        ),
        RepositoryProvider<ModelDownloadService>.value(
          value: _modelDownloadService,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<VaultBloc>(
            create: (_) =>
                VaultBloc(repository: _vaultRepository)
                  ..add(const VaultLoadRequested()),
          ),
          BlocProvider<JournalBloc>(
            create: (_) =>
                JournalBloc(repository: _journalRepository)
                  ..add(const JournalLoadRequested()),
          ),
          BlocProvider<SetupWizardBloc>(
            create: (_) => SetupWizardBloc(
              vaultRepository: _vaultRepository,
              onboardingRepository: _onboardingRepository,
              modelDownloadService: _modelDownloadService,
            ),
          ),
          BlocProvider<ModelDownloaderBloc>(
            create: (_) => ModelDownloaderBloc(service: _modelDownloadService),
          ),
        ],
        child: WidgetsApp.router(
          color: ArcaColors.primary,
          textStyle: ArcaTypography.bodyMedium,
          routerConfig: _routerConfig,
          title: 'Arca',
        ),
      ),
    );
  }
}
