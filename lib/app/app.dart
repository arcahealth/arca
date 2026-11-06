import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaisel/kaisel.dart';

import '../core/design_system/tokens/tokens.dart';
import '../features/journal/data/repositories/in_memory_journal_repository.dart';
import '../features/journal/domain/repositories/journal_repository.dart';
import '../features/journal/presentation/bloc/journal_bloc.dart';
import '../features/journal/presentation/bloc/journal_event.dart';
import 'router.dart';
import 'routes.dart';

/// Composition root for Arca.
///
/// Injects domain repositories and BLoCs at the edge and wraps the app with
/// a decoupled [WidgetsApp.router], deliberately avoiding monolithic Material
/// and Cupertino framework dependencies.
class ArcaApp extends StatefulWidget {
  const ArcaApp({super.key, this.journalRepository, this.routerConfig});

  final JournalRepository? journalRepository;
  final KaiselRouterConfig<AppRoute>? routerConfig;

  @override
  State<ArcaApp> createState() => _ArcaAppState();
}

class _ArcaAppState extends State<ArcaApp> {
  late final JournalRepository _repository;
  late final KaiselRouterConfig<AppRoute> _routerConfig;

  @override
  void initState() {
    super.initState();
    _repository = widget.journalRepository ?? InMemoryJournalRepository();
    _routerConfig =
        widget.routerConfig ?? createAppRouter(repository: _repository);
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<JournalRepository>.value(
      value: _repository,
      child: BlocProvider<JournalBloc>(
        create: (_) =>
            JournalBloc(repository: _repository)
              ..add(const JournalLoadRequested()),
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
