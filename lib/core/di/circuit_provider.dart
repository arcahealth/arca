import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'di.dart';

export 'di.dart';

/// Sealed hierarchy representing the compilation and readiness state of a [Circuit].
sealed class CircuitState {
  const CircuitState();

  /// Represents a circuit that is currently resolving and compiling asynchronous wires.
  const factory CircuitState.building() = CircuitBuilding;

  /// Represents a successfully built and verified circuit ready for dependency injection.
  const factory CircuitState.ready(Circuit circuit) = CircuitReady;

  /// Represents a failure encountered during circuit validation or asynchronous wire resolution.
  const factory CircuitState.failure(Object error, [StackTrace? stackTrace]) =
      CircuitFailure;
}

/// State emitted while the circuit's dependency graph is validating and resolving.
final class CircuitBuilding extends CircuitState {
  const CircuitBuilding();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CircuitBuilding;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'CircuitBuilding()';
}

/// State emitted when the circuit has completed all asynchronous wire resolutions and is ready.
final class CircuitReady extends CircuitState {
  final Circuit circuit;

  const CircuitReady(this.circuit);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CircuitReady && identical(circuit, other.circuit);

  @override
  int get hashCode => identityHashCode(circuit);

  @override
  String toString() => 'CircuitReady($circuit)';
}

/// State emitted when circuit construction or wire resolution throws an error.
final class CircuitFailure extends CircuitState {
  final Object error;
  final StackTrace? stackTrace;

  const CircuitFailure(this.error, [this.stackTrace]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CircuitFailure &&
          error == other.error &&
          stackTrace == other.stackTrace;

  @override
  int get hashCode => Object.hash(error, stackTrace);

  @override
  String toString() => 'CircuitFailure($error)';
}

/// Flutter bridge providing a [Circuit] container to the widget tree.
///
/// Use the default constructor to compile a list of [CircuitWire] recipes asynchronously:
/// ```dart
/// CircuitProvider(
///   wires: [myWire1, myWire2],
///   builder: (context, state) => switch (state) {
///     CircuitReady(:final circuit) => MyHomeScreen(),
///     CircuitBuilding() => const LoadingScreen(),
///     CircuitFailure(:final error) => const ErrorScreen(),
///   },
/// );
/// ```
///
/// Use [CircuitProvider.value] to provide an already-built [Circuit] synchronously:
/// ```dart
/// CircuitProvider.value(
///   value: existingCircuit,
///   child: MyHomeScreen(),
/// );
/// ```
sealed class CircuitProvider extends StatelessWidget {
  const CircuitProvider._({super.key});

  /// Asynchronously builds a [Circuit] from [wires] and executes [builder] with reactive [CircuitState].
  ///
  /// Disposes the resolved [Circuit] automatically when removed from the widget tree.
  const factory CircuitProvider({
    Key? key,
    required List<CircuitWire> wires,
    required Widget Function(BuildContext context, CircuitState state) builder,
  }) = CircuitWireProvider;

  /// Injects an already existing [Circuit] into the widget subtree without managing its lifecycle.
  const factory CircuitProvider.value({
    Key? key,
    required Circuit value,
    required Widget child,
  }) = CircuitValueProvider;

  /// Retrieves the nearest [Circuit] ancestor from [context].
  ///
  /// Throws a [StateError] if no [CircuitProvider] is found in [context] or if the circuit is not yet ready.
  static Circuit of(BuildContext context) {
    final circuit = maybeOf(context);
    if (circuit == null) {
      throw StateError(
        'No CircuitProvider found in context. Ensure that CircuitProvider or '
        'CircuitProvider.value wraps this widget tree and that the circuit is ready.',
      );
    }
    return circuit;
  }

  /// Retrieves the nearest [Circuit] ancestor from [context], or `null` if none exists or the circuit is not ready.
  static Circuit? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_CircuitScope>()?.circuit;
  }
}

/// A [CircuitProvider] variant that synchronously injects an already resolved [Circuit] value.
///
/// Does not track state, execute asynchronous builds, or dispose the [Circuit] when unmounted.
final class CircuitValueProvider extends CircuitProvider {
  final Circuit value;
  final Widget child;

  const CircuitValueProvider({
    super.key,
    required this.value,
    required this.child,
  }) : super._();

  @override
  Widget build(BuildContext context) {
    return _CircuitScope(circuit: value, child: child);
  }
}

/// A [CircuitProvider] variant that manages the asynchronous build lifecycle of a list of [CircuitWire]s.
final class CircuitWireProvider extends CircuitProvider {
  final List<CircuitWire> wires;
  final Widget Function(BuildContext context, CircuitState state) builder;

  const CircuitWireProvider({
    super.key,
    required this.wires,
    required this.builder,
  }) : super._();

  @override
  Widget build(BuildContext context) {
    return _CircuitWireStateful(wires: wires, builder: builder);
  }
}

final class _CircuitWireStateful extends StatefulWidget {
  final List<CircuitWire> wires;
  final Widget Function(BuildContext context, CircuitState state) builder;

  const _CircuitWireStateful({required this.wires, required this.builder});

  @override
  State<_CircuitWireStateful> createState() => _CircuitWireStatefulState();
}

class _CircuitWireStatefulState extends State<_CircuitWireStateful> {
  CircuitState _state = const CircuitState.building();
  Circuit? _circuit;
  int _compilationEpoch = 0;

  @override
  void initState() {
    super.initState();
    _startCompilation();
  }

  @override
  void didUpdateWidget(covariant _CircuitWireStateful oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.wires, oldWidget.wires)) {
      _compilationEpoch++;
      _circuit?.dispose().ignore();
      _circuit = null;
      setState(() {
        _state = const CircuitState.building();
      });
      _startCompilation();
    }
  }

  void _startCompilation() {
    final currentEpoch = ++_compilationEpoch;
    Circuit.build(widget.wires).then(
      (circuit) {
        if (!mounted || currentEpoch != _compilationEpoch) {
          circuit.dispose().ignore();
          return;
        }
        _circuit = circuit;
        setState(() {
          _state = CircuitState.ready(circuit);
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted || currentEpoch != _compilationEpoch) return;
        setState(() {
          _state = CircuitState.failure(error, stackTrace);
        });
      },
    );
  }

  @override
  void dispose() {
    _compilationEpoch++;
    _circuit?.dispose().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      CircuitReady(:final circuit) => _CircuitScope(
        circuit: circuit,
        child: Builder(builder: (context) => widget.builder(context, _state)),
      ),
      _ => widget.builder(context, _state),
    };
  }
}

/// Internal [InheritedWidget] carrying the [Circuit] instance through the widget tree.
final class _CircuitScope extends InheritedWidget {
  final Circuit circuit;

  const _CircuitScope({required this.circuit, required super.child});

  @override
  bool updateShouldNotify(_CircuitScope oldWidget) =>
      circuit != oldWidget.circuit;
}
