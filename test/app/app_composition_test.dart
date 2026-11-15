import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaisel/kaisel.dart';

import 'package:arca/app/app.dart';
import 'package:arca/app/router/router.dart';
import 'package:arca/core/design_system/arca_design_system.dart';
import 'package:circuitry_flutter/circuitry_flutter.dart';

void main() {
  group('ArcaApp Composition Root Integration', () {
    testWidgets(
      'ArcaApp displays splash scaffold on initial frame and transitions to router',
      (tester) async {
        final testRouterWire = Wire<KaiselRouterConfig<ArcaRoute>>(
          () => KaiselRouterConfig<ArcaRoute>(
            initial: const OnboardingMount(),
            builder: (context, route) => const Text('Router Active'),
          ),
        );

        await tester.pumpWidget(ArcaApp(wires: [testRouterWire]));

        // Initial frame is building: splash screen
        expect(find.text('Arca'), findsOneWidget);
        expect(find.byType(ArcaScaffold), findsOneWidget);

        // Complete compilation
        await tester.pumpAndSettle();

        // Router takes over
        expect(find.text('Router Active'), findsOneWidget);
      },
    );

    testWidgets(
      'ArcaApp displays error screen when circuit compilation fails',
      (tester) async {
        final failingWire = AsyncWire<String>(
          () async => throw StateError('disk corruption'),
        );

        await tester.pumpWidget(ArcaApp(wires: [failingWire]));

        await tester.pumpAndSettle();

        expect(find.text('Failed to build vault'), findsOneWidget);
        expect(find.byType(ArcaScaffold), findsOneWidget);
      },
    );
  });
}
