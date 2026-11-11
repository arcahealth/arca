import 'dart:async';

import 'package:arca/app/app_container.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:arca/core/design_system/arca_design_system.dart';

/// Composition root for Arca.
///
/// Injects core dependencies at the application edge.
final class const ArcaApp({super.key, final ArcaContainer? appContainer})
    extends StatefulWidget {
  @override
  State<ArcaApp> createState() => _ArcaAppState();
}

class _ArcaAppState extends State<ArcaApp> {
  late final ArcaContainer _appContainer;

  @override
  void initState() {
    super.initState();

    _appContainer = widget.appContainer ?? ArcaContainer();
    unawaited(_appContainer.init());
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ArcaContainerState>(
      valueListenable: _appContainer.state,
      builder: (context, state, child) => switch (state) {
        // The Builder child is built lazily: _appContainer.routerConfig is
        // only valid once the container reaches .ready.
        .ready when child != null => child,
        _ => WidgetsApp(
          color: ArcaColors.primary,
          textStyle: ArcaTypography.bodyMedium,
          pageRouteBuilder:
              <T>(RouteSettings settings, WidgetBuilder builder) =>
                  PageRouteBuilder(
                    settings: settings,
                    pageBuilder: (context, _, _) => builder(context),
                  ),
          home: const ArcaScaffold(
            body: Center(child: Text("Arca", style: ArcaTypography.display)),
          ),
        ),
      },
      child: Builder(
        builder: (context) {
          return MultiRepositoryProvider(
            providers: [
              RepositoryProvider<ArcaContainer>.value(value: _appContainer),
            ],
            child: WidgetsApp.router(
              color: ArcaColors.primary,
              textStyle: ArcaTypography.bodyMedium,
              routerConfig: _appContainer.routerConfig,
              title: 'Arca',
            ),
          );
        },
      ),
    );
  }
}
