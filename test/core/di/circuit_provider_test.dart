import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaisel/kaisel.dart';

import 'package:arca/app/app.dart';
import 'package:arca/app/router/router.dart';
import 'package:arca/core/design_system/arca_design_system.dart';
import 'package:arca/core/di/circuit_provider.dart';

final class _RepositoryA {
  final String name;
  const _RepositoryA([this.name = 'repo_a']);
}

final class _RepositoryB {
  final _RepositoryA a;
  const _RepositoryB(this.a);
}

final class _AsyncService {
  final String status;
  _AsyncService(this.status);
}

void main() {
  group('CircuitState Hierarchy', () {
    test('constructors and equality', () {
      const building1 = CircuitState.building();
      const building2 = CircuitBuilding();
      expect(building1, equals(building2));
      expect(building1.hashCode, equals(building2.hashCode));
      expect(building1.toString(), equals('CircuitBuilding()'));

      final exception = StateError('test error');
      final failure1 = CircuitState.failure(exception);
      final failure2 = CircuitFailure(exception);
      expect(failure1, equals(failure2));
      expect(failure1.hashCode, equals(failure2.hashCode));
      expect(failure1.toString(), contains('test error'));
    });

    test('CircuitReady equality is identity-based on Circuit', () async {
      final circuit1 = await Circuit.build([]);
      final circuit2 = await Circuit.build([]);
      addTearDown(() async {
        await circuit1.dispose();
        await circuit2.dispose();
      });

      final ready1 = CircuitState.ready(circuit1);
      final ready1Alias = CircuitReady(circuit1);
      final ready2 = CircuitState.ready(circuit2);

      expect(ready1, equals(ready1Alias));
      expect(ready1, isNot(equals(ready2)));
      expect(ready1.hashCode, equals(identityHashCode(circuit1)));
      expect(ready1.toString(), contains('CircuitReady'));
    });
  });

  group('CircuitProvider Async Compilation Lifecycle', () {
    testWidgets('starts in CircuitBuilding and transitions to CircuitReady', (
      tester,
    ) async {
      final completer = Completer<String>();
      final asyncWire = AsyncWire<_AsyncService>(() async {
        final status = await completer.future;
        return _AsyncService(status);
      });

      Circuit? resolvedCircuit;
      CircuitState? capturedState;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CircuitProvider(
            wires: [asyncWire],
            builder: (context, state) {
              capturedState = state;
              return switch (state) {
                CircuitBuilding() => const Text('Building'),
                CircuitReady(:final circuit) => Builder(
                  builder: (childContext) {
                    resolvedCircuit = CircuitProvider.of(childContext);
                    return Text(
                      'Ready: ${circuit.get<_AsyncService>().status}',
                    );
                  },
                ),
                CircuitFailure(:final error) => Text('Failure: $error'),
              };
            },
          ),
        ),
      );

      expect(find.text('Building'), findsOneWidget);
      expect(capturedState, isA<CircuitBuilding>());
      expect(resolvedCircuit, isNull);

      completer.complete('connected');
      await tester.pumpAndSettle();

      expect(find.text('Ready: connected'), findsOneWidget);
      expect(capturedState, isA<CircuitReady>());
      expect(resolvedCircuit, isNotNull);
      expect(resolvedCircuit!.isDisposed, isFalse);

      // Unmount widget and verify circuit is disposed
      await tester.pumpWidget(const SizedBox());
      expect(resolvedCircuit!.isDisposed, isTrue);
    });

    testWidgets(
      'unmounting while async build is in flight disposes resolved circuit immediately',
      (tester) async {
        final completer = Completer<_AsyncService>();
        var disposeCalled = false;

        final asyncWire = AsyncWire<_AsyncService>(
          () => completer.future,
          onDispose: (_) => disposeCalled = true,
        );

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CircuitProvider(
              wires: [asyncWire],
              builder: (context, state) => switch (state) {
                CircuitBuilding() => const Text('Building'),
                CircuitReady() => const Text('Ready'),
                CircuitFailure() => const Text('Failure'),
              },
            ),
          ),
        );

        expect(find.text('Building'), findsOneWidget);

        // Unmount before completion
        await tester.pumpWidget(const SizedBox());

        // Now complete the async factory
        final service = _AsyncService('abandoned');
        completer.complete(service);

        // Yield to allow microtask/future callbacks to run
        await tester.pump(Duration.zero);

        expect(disposeCalled, isTrue);
      },
    );

    testWidgets(
      'disposes active circuit and invokes onDispose hooks on unmount',
      (tester) async {
        final teardownLog = <String>[];

        final wireA = Wire<_RepositoryA>(
          () => const _RepositoryA(),
          onDispose: (_) => teardownLog.add('dispose:A'),
        );
        final wireB = Wire.takes<_RepositoryA>().to<_RepositoryB, Enum>(
          (_RepositoryA a) => _RepositoryB(a),
          onDispose: (_) => teardownLog.add('dispose:B'),
        );

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CircuitProvider(
              wires: [wireA, wireB],
              builder: (context, state) => switch (state) {
                CircuitReady(:final circuit) => Text(
                  'Initialized: ${circuit.get<_RepositoryB>().a.name}',
                ),
                _ => const Text('Loading'),
              },
            ),
          ),
        );

        await tester.pump();
        expect(find.text('Initialized: repo_a'), findsOneWidget);

        // Unmount
        await tester.pumpWidget(const SizedBox());

        // Reverse topological teardown: B before A
        expect(teardownLog, equals(['dispose:B', 'dispose:A']));
      },
    );

    testWidgets(
      'compiles successfully and transitions to ready when wires list is empty',
      (tester) async {
        Circuit? emptyCircuit;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CircuitProvider(
              wires: const [],
              builder: (context, state) => switch (state) {
                CircuitReady(:final circuit) => Builder(
                  builder: (childContext) {
                    emptyCircuit = circuit;
                    return const Text('Empty Ready');
                  },
                ),
                _ => const Text('Loading'),
              },
            ),
          ),
        );

        await tester.pump();
        expect(find.text('Empty Ready'), findsOneWidget);
        expect(emptyCircuit, isNotNull);
        expect(emptyCircuit!.isDisposed, isFalse);
      },
    );

    testWidgets(
      'recompiles and disposes previous circuit when wires list is updated',
      (tester) async {
        var disposeV1Called = false;
        final wireV1 = Wire<_RepositoryA>(
          () => const _RepositoryA('v1'),
          onDispose: (_) => disposeV1Called = true,
        );
        final wireV2 = Wire<_RepositoryA>(() => const _RepositoryA('v2'));

        var activeWires = [wireV1];
        late StateSetter updateTree;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              updateTree = setState;
              return Directionality(
                textDirection: TextDirection.ltr,
                child: CircuitProvider(
                  wires: activeWires,
                  builder: (context, state) => switch (state) {
                    CircuitReady(:final circuit) => Text(
                      'Ready: ${circuit.get<_RepositoryA>().name}',
                    ),
                    CircuitBuilding() => const Text('Building'),
                    CircuitFailure() => const Text('Failure'),
                  },
                ),
              );
            },
          ),
        );

        await tester.pump();
        expect(find.text('Ready: v1'), findsOneWidget);
        expect(disposeV1Called, isFalse);

        // Update wires to V2
        updateTree(() {
          activeWires = [wireV2];
        });
        await tester.pumpAndSettle();

        expect(find.text('Ready: v2'), findsOneWidget);
        expect(disposeV1Called, isTrue);
      },
    );

    testWidgets(
      'cancels and disposes in-flight compilation when wires change before completion',
      (tester) async {
        final completerV1 = Completer<String>();
        var disposeV1Called = false;
        final asyncWireV1 = AsyncWire<String>(
          () => completerV1.future,
          onDispose: (_) => disposeV1Called = true,
        );

        final asyncWireV2 = AsyncWire<String>(() async => 'v2_fast');

        var activeWires = <CircuitWire>[asyncWireV1];
        late StateSetter updateTree;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              updateTree = setState;
              return Directionality(
                textDirection: TextDirection.ltr,
                child: CircuitProvider(
                  wires: activeWires,
                  builder: (context, state) => switch (state) {
                    CircuitReady(:final circuit) => Text(
                      'Ready: ${circuit.get<String>()}',
                    ),
                    CircuitBuilding() => const Text('Building'),
                    CircuitFailure() => const Text('Failure'),
                  },
                ),
              );
            },
          ),
        );

        expect(find.text('Building'), findsOneWidget);

        // While V1 is in flight, update wires to V2
        updateTree(() {
          activeWires = [asyncWireV2];
        });
        await tester.pumpAndSettle();

        expect(find.text('Ready: v2_fast'), findsOneWidget);

        // Now V1 completes
        completerV1.complete('v1_stale');
        await tester.pump(Duration.zero);

        // Stale V1 completion should be ignored and disposed
        expect(find.text('Ready: v2_fast'), findsOneWidget);
        expect(disposeV1Called, isTrue);
      },
    );

    testWidgets(
      'does not recompile or dispose active circuit when wires list elements are identical',
      (tester) async {
        final wireA = Wire<_RepositoryA>(() => const _RepositoryA('stable'));
        Circuit? firstCircuit;
        Circuit? secondCircuit;
        late StateSetter updateTree;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              updateTree = setState;
              return Directionality(
                textDirection: TextDirection.ltr,
                child: CircuitProvider(
                  wires: [
                    wireA,
                  ], // Fresh list instance with same wire reference
                  builder: (context, state) => switch (state) {
                    CircuitReady(:final circuit) => Builder(
                      builder: (childContext) {
                        if (firstCircuit == null) {
                          firstCircuit = circuit;
                        } else {
                          secondCircuit = circuit;
                        }
                        return const Text('Ready');
                      },
                    ),
                    _ => const Text('Loading'),
                  },
                ),
              );
            },
          ),
        );

        await tester.pump();
        expect(find.text('Ready'), findsOneWidget);
        expect(firstCircuit, isNotNull);

        // Trigger rebuild with a new list instance holding the same wire
        updateTree(() {});
        await tester.pump();

        expect(secondCircuit, isNotNull);
        expect(identical(firstCircuit, secondCircuit), isTrue);
        expect(firstCircuit!.isDisposed, isFalse);
      },
    );
  });

  group('CircuitProvider Failure State', () {
    testWidgets(
      'transitions to CircuitFailure when missing dependency is detected',
      (tester) async {
        final wireB = Wire.takes<_RepositoryA>().to<_RepositoryB, Enum>(
          (_RepositoryA a) => _RepositoryB(a),
        );

        CircuitState? capturedState;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CircuitProvider(
              wires: [wireB], // Missing _RepositoryA wire
              builder: (context, state) {
                capturedState = state;
                return switch (state) {
                  CircuitFailure(:final error) => Text(
                    'Error: ${error.runtimeType}',
                  ),
                  CircuitReady() => const Text('Ready'),
                  CircuitBuilding() => const Text('Building'),
                };
              },
            ),
          ),
        );

        await tester.pump();

        expect(find.text('Error: MissingWireException'), findsOneWidget);
        expect(capturedState, isA<CircuitFailure>());
        final failure = capturedState as CircuitFailure;
        expect(failure.error, isA<MissingWireException>());
      },
    );

    testWidgets(
      'transitions to CircuitFailure when duplicate wire keys are registered',
      (tester) async {
        final wire1 = Wire<String>(() => 'first');
        final wire2 = Wire<String>(() => 'second');

        CircuitState? capturedState;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CircuitProvider(
              wires: [wire1, wire2],
              builder: (context, state) {
                capturedState = state;
                return switch (state) {
                  CircuitFailure(:final error) => Text(
                    'Error: ${error.runtimeType}',
                  ),
                  CircuitReady() => const Text('Ready'),
                  CircuitBuilding() => const Text('Building'),
                };
              },
            ),
          ),
        );

        await tester.pump();

        expect(find.text('Error: DuplicateWireException'), findsOneWidget);
        expect(capturedState, isA<CircuitFailure>());
        final failure = capturedState as CircuitFailure;
        expect(failure.error, isA<DuplicateWireException>());
      },
    );

    testWidgets(
      'transitions to CircuitFailure when circular dependency is detected',
      (tester) async {
        // Create cyclic wires: A depends on B, B depends on A
        final wireA = Wire.takes<_RepositoryB>().to<_RepositoryA, Enum>(
          (_) => const _RepositoryA(),
        );
        final wireB = Wire.takes<_RepositoryA>().to<_RepositoryB, Enum>(
          (a) => _RepositoryB(a),
        );

        CircuitState? capturedState;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CircuitProvider(
              wires: [wireA, wireB],
              builder: (context, state) {
                capturedState = state;
                return switch (state) {
                  CircuitFailure(:final error) => Text(
                    'Error: ${error.runtimeType}',
                  ),
                  CircuitReady() => const Text('Ready'),
                  CircuitBuilding() => const Text('Building'),
                };
              },
            ),
          ),
        );

        await tester.pump();

        expect(find.text('Error: CircularDependencyException'), findsOneWidget);
        expect(capturedState, isA<CircuitFailure>());
        final failure = capturedState as CircuitFailure;
        expect(failure.error, isA<CircularDependencyException>());
      },
    );

    testWidgets('transitions to CircuitFailure when AsyncWire factory throws', (
      tester,
    ) async {
      final failingWire = AsyncWire<String>(
        () async => throw StateError('database connection refused'),
      );

      CircuitState? capturedState;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CircuitProvider(
            wires: [failingWire],
            builder: (context, state) {
              capturedState = state;
              return switch (state) {
                CircuitFailure(:final error) => Text('Error: $error'),
                CircuitReady() => const Text('Ready'),
                CircuitBuilding() => const Text('Building'),
              };
            },
          ),
        ),
      );

      await tester.pump();

      expect(
        find.text('Error: Bad state: database connection refused'),
        findsOneWidget,
      );
      expect(capturedState, isA<CircuitFailure>());
      final failure = capturedState as CircuitFailure;
      expect(failure.error, isA<StateError>());
    });

    testWidgets(
      'CircuitProvider.maybeOf returns null and of throws in building/failure states',
      (tester) async {
        final failingWire = AsyncWire<String>(
          () async => throw StateError('fail'),
        );

        Circuit? maybeCircuitDuringFailure;
        Object? thrownErrorDuringFailure;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CircuitProvider(
              wires: [failingWire],
              builder: (context, state) {
                if (state is CircuitFailure) {
                  maybeCircuitDuringFailure = CircuitProvider.maybeOf(context);
                  try {
                    CircuitProvider.of(context);
                  } catch (e) {
                    thrownErrorDuringFailure = e;
                  }
                  return const Text('Handled Failure');
                }
                return const Text('Pending');
              },
            ),
          ),
        );

        await tester.pump();

        expect(find.text('Handled Failure'), findsOneWidget);
        expect(maybeCircuitDuringFailure, isNull);
        expect(thrownErrorDuringFailure, isA<StateError>());
      },
    );
  });

  group('CircuitProvider of(context) and maybeOf(context) Accessors', () {
    testWidgets(
      'retrieves active circuit in builder and across deeply nested descendants',
      (tester) async {
        final wireA = Wire<_RepositoryA>(() => const _RepositoryA('vault_db'));
        Circuit? inheritedCircuit;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CircuitProvider(
              wires: [wireA],
              builder: (context, state) => switch (state) {
                CircuitReady() => Builder(
                  builder: (childContext) {
                    inheritedCircuit = CircuitProvider.of(childContext);
                    return Text(
                      'Value: ${inheritedCircuit!.get<_RepositoryA>().name}',
                    );
                  },
                ),
                _ => const Text('Loading'),
              },
            ),
          ),
        );

        await tester.pump();

        expect(find.text('Value: vault_db'), findsOneWidget);
        expect(inheritedCircuit, isNotNull);
        expect(inheritedCircuit!.get<_RepositoryA>().name, equals('vault_db'));
      },
    );

    testWidgets(
      'maybeOf returns null and of throws StateError when outside CircuitProvider',
      (tester) async {
        Circuit? maybeCircuit;
        Object? thrownError;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                maybeCircuit = CircuitProvider.maybeOf(context);
                try {
                  CircuitProvider.of(context);
                } catch (e) {
                  thrownError = e;
                }
                return const Text('Isolated');
              },
            ),
          ),
        );

        expect(find.text('Isolated'), findsOneWidget);
        expect(maybeCircuit, isNull);
        expect(thrownError, isA<StateError>());
        expect(
          (thrownError as StateError).message,
          contains('No CircuitProvider found in context'),
        );
      },
    );
  });

  group('CircuitProvider.value Synchronous Injection', () {
    testWidgets(
      'immediately provides circuit without async compilation delay',
      (tester) async {
        final circuit = await Circuit.build([
          Wire<_RepositoryA>(() => const _RepositoryA('prebuilt')),
        ]);
        addTearDown(circuit.dispose);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CircuitProvider.value(
              value: circuit,
              child: Builder(
                builder: (context) {
                  final c = CircuitProvider.of(context);
                  return Text('Resolved: ${c.get<_RepositoryA>().name}');
                },
              ),
            ),
          ),
        );

        // Does not require pump/await: available on frame 1
        expect(find.text('Resolved: prebuilt'), findsOneWidget);
      },
    );

    testWidgets(
      'unmounting CircuitProvider.value does NOT dispose the injected circuit',
      (tester) async {
        final circuit = await Circuit.build([
          Wire<_RepositoryA>(() => const _RepositoryA('keep_alive')),
        ]);
        addTearDown(circuit.dispose);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CircuitProvider.value(
              value: circuit,
              child: const Text('Alive'),
            ),
          ),
        );

        expect(find.text('Alive'), findsOneWidget);
        expect(circuit.isDisposed, isFalse);

        // Unmount
        await tester.pumpWidget(const SizedBox());

        // Value provider does not own circuit: must remain active
        expect(circuit.isDisposed, isFalse);
        expect(circuit.get<_RepositoryA>().name, equals('keep_alive'));
      },
    );

    testWidgets(
      'updates descendants when value changes without disposing old circuit',
      (tester) async {
        final circuit1 = await Circuit.build([
          Wire<_RepositoryA>(() => const _RepositoryA('first_value')),
        ]);
        final circuit2 = await Circuit.build([
          Wire<_RepositoryA>(() => const _RepositoryA('second_value')),
        ]);
        addTearDown(() async {
          await circuit1.dispose();
          await circuit2.dispose();
        });

        var activeCircuit = circuit1;
        late StateSetter updateTree;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              updateTree = setState;
              return Directionality(
                textDirection: TextDirection.ltr,
                child: CircuitProvider.value(
                  value: activeCircuit,
                  child: Builder(
                    builder: (childContext) {
                      final c = CircuitProvider.of(childContext);
                      return Text('Active: ${c.get<_RepositoryA>().name}');
                    },
                  ),
                ),
              );
            },
          ),
        );

        expect(find.text('Active: first_value'), findsOneWidget);

        // Switch to circuit2
        updateTree(() {
          activeCircuit = circuit2;
        });
        await tester.pump();

        expect(find.text('Active: second_value'), findsOneWidget);
        expect(circuit1.isDisposed, isFalse);
        expect(circuit2.isDisposed, isFalse);
      },
    );
  });

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
