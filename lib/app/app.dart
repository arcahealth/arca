import 'package:flutter/widgets.dart';
import 'package:kaisel/kaisel.dart';

import 'package:arca/app/router/router.dart';
import 'package:arca/core/capture/capture.dart';
import 'package:arca/core/database/database_service.dart';
import 'package:arca/core/design_system/arca_design_system.dart';
import 'package:circuitry_flutter/circuitry_flutter.dart';
import 'package:arca/core/onboarding/onboarding.dart';

/// Composition root for Arca.
///
/// Injects core dependencies at the application edge via [CircuitProvider].
final class const ArcaApp({super.key, final List<CircuitWire> wires = const []}) extends StatelessWidget {
  static final _defaultWires = [
    DatabaseConfig.wire,
    DatabaseService.wire,
    OnboardingRepository.wire,
    DocumentCaptureService.wire,
    ArcaRouter.wire,
  ];

  static Widget _fallbackApp(Widget home) => WidgetsApp(
    color: ArcaColors.primary,
    textStyle: ArcaTypography.bodyMedium,
    pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) => PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, _, _) => builder(context),
    ),
    home: home,
  );

  @override
  Widget build(BuildContext context) {
    final effectiveWires = wires.isNotEmpty ? wires : _defaultWires;

    return CircuitProvider(
      wires: effectiveWires,
      builder: (context, state) => switch (state) {
        CircuitBuilding() => _fallbackApp(
          const ArcaScaffold(
            body: Center(child: Text("Arca", style: ArcaTypography.display)),
          ),
        ),
        CircuitReady(:final circuit) => WidgetsApp.router(
          color: ArcaColors.primary,
          textStyle: ArcaTypography.bodyMedium,
          routerConfig: circuit.get<KaiselRouterConfig<ArcaRoute>>(),
          title: 'Arca',
        ),
        CircuitFailure(:final error) => _fallbackApp(
          ArcaScaffold(
            key: ValueKey(error),
            body: const Center(child: Text("Failed to build vault")),
          ),
        ),
      },
    );
  }
}
