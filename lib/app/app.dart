import 'package:arca/core/di/di.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:arca/core/design_system/arca_design_system.dart';
import 'package:kaisel/kaisel.dart';

/// Composition root for Arca.
///
/// Injects core dependencies at the application edge.
final class const ArcaApp({super.key, final List<CircuitWire> wires = const []})
    extends StatefulWidget {
  @override
  State<ArcaApp> createState() => _ArcaAppState();
}

class _ArcaAppState extends State<ArcaApp> {
  late final Future<Circuit> _circuitBuilder;

  @override
  void initState() {
    super.initState();

    _circuitBuilder = Circuit.build(widget.wires);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Circuit>(
      future: _circuitBuilder,
      builder: (context, snapshot) => switch (snapshot) {
        AsyncSnapshot<Circuit>(connectionState: .done, data: final circuit?) =>
          MultiRepositoryProvider(
            providers: [RepositoryProvider<Circuit>.value(value: circuit)],
            child: WidgetsApp.router(
              color: ArcaColors.primary,
              textStyle: ArcaTypography.bodyMedium,
              routerConfig: circuit.get<KaiselRouterConfig>(),
              title: 'Arca',
            ),
          ),
        // // TODO: Handle this case.
        // AsyncSnapshot(:final error?) => throw UnimplementedError(),
        // The Builder child is built lazily: wires are only
        // valid once the Circuit is validated and built.
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
    );
  }
}
