library;

import 'dart:async';

/// A record tuple uniquely identifying a wire in a circuit.
///
/// Untagged wires have a key of `(T, null)`.
/// Tagged wires have a key of `(T, tag)` where `tag is Enum`.
typedef WireKey = (Type type, Enum? tag);

/// Base sealed class representing a dependency recipe in a circuit.
sealed class CircuitWire {
  /// Unique key identifying this wire in the circuit.
  WireKey get key;

  /// The keys of all dependencies required by this wire.
  List<WireKey> get dependencies;

  /// Whether this wire must be resolved asynchronously during circuit build.
  bool get isAsync;

  /// Invoked when disposing an active instance of this wire.
  FutureOr<void> disposeInstance(Object? instance);
}

/// A synchronous dependency recipe representing a lazy singleton.
final class Wire<T> extends CircuitWire {
  @override
  final WireKey key;

  @override
  final List<WireKey> dependencies;

  @override
  bool get isAsync => false;

  /// Optional disposal callback invoked when the circuit is disposed.
  final FutureOr<void> Function(T instance)? onDispose;

  final T Function(Circuit circuit) _create;

  /// Creates an untagged synchronous wire with no dependencies.
  Wire(T Function() create, {this.onDispose})
    : key = (T, null),
      dependencies = const [],
      _create = ((_) => create());

  /// Creates a tagged synchronous wire with no dependencies.
  static Wire<T> tag<T, K extends Enum>(
    T Function() create, {
    required K tag,
    FutureOr<void> Function(T instance)? onDispose,
  }) {
    return Wire<T>._(
      key: (T, tag),
      dependencies: const [],
      create: (_) => create(),
      onDispose: onDispose,
    );
  }

  Wire._({
    required this.key,
    required this.dependencies,
    required this._create,
    this.onDispose,
  });

  /// Starts building a synchronous wire that depends on an untagged dependency of type [A].
  static WireBuilder<A> takes<A>() =>
      WireBuilder<A>._([(A, null)], (c) => c.get<A>());

  /// Starts building a synchronous wire that depends on a tagged dependency of type [A] with [tag].
  static WireBuilder<A> takesTagged<A, K extends Enum>(K tag) =>
      WireBuilder<A>._([(A, tag)], (c) => c.getTagged<A, K>(tag));

  @override
  FutureOr<void> disposeInstance(Object? instance) {
    if (instance is T && onDispose != null) {
      return onDispose!(instance);
    }
  }

  T _createInstance(Circuit circuit) => _create(circuit);
}

/// An asynchronous dependency recipe resolved in parallel topological waves during circuit build.
final class AsyncWire<T> extends CircuitWire {
  @override
  final WireKey key;

  @override
  final List<WireKey> dependencies;

  @override
  bool get isAsync => true;

  /// Optional disposal callback invoked when the circuit is disposed.
  final FutureOr<void> Function(T instance)? onDispose;

  final Future<T> Function(Circuit circuit) _create;

  /// Creates an untagged asynchronous wire with no dependencies.
  AsyncWire(Future<T> Function() create, {this.onDispose})
    : key = (T, null),
      dependencies = const [],
      _create = ((_) => create());

  /// Creates a tagged asynchronous wire with no dependencies.
  static AsyncWire<T> tag<T, K extends Enum>(
    Future<T> Function() create, {
    required K tag,
    FutureOr<void> Function(T instance)? onDispose,
  }) {
    return AsyncWire<T>._(
      key: (T, tag),
      dependencies: const [],
      create: (_) => create(),
      onDispose: onDispose,
    );
  }

  AsyncWire._({
    required this.key,
    required this.dependencies,
    required this._create,
    this.onDispose,
  });

  /// Starts building an asynchronous wire that depends on an untagged dependency of type [A].
  static AsyncWireBuilder<A> takes<A>() =>
      AsyncWireBuilder<A>._([(A, null)], (c) => c.get<A>());

  /// Starts building an asynchronous wire that depends on a tagged dependency of type [A] with [tag].
  static AsyncWireBuilder<A> takesTagged<A, K extends Enum>(K tag) =>
      AsyncWireBuilder<A>._([(A, tag)], (c) => c.getTagged<A, K>(tag));

  @override
  FutureOr<void> disposeInstance(Object? instance) {
    if (instance is T && onDispose != null) {
      return onDispose!(instance);
    }
  }

  Future<T> _createInstance(Circuit circuit) => _create(circuit);
}

/// Accumulator-based chaining builder for synchronous [Wire]s.
final class WireBuilder<Acc> {
  final List<WireKey> _dependencies;
  final Acc Function(Circuit circuit) _resolveDeps;

  WireBuilder._(this._dependencies, this._resolveDeps);

  /// Appends an untagged dependency of type [Next] to the dependency accumulator.
  WireBuilder<(Acc, Next)> takes<Next>() {
    return WireBuilder<(Acc, Next)>._([
      ..._dependencies,
      (Next, null),
    ], (c) => (_resolveDeps(c), c.get<Next>()));
  }

  /// Appends a tagged dependency of type [Next] with [tag] to the dependency accumulator.
  WireBuilder<(Acc, Next)> takesTagged<Next, K extends Enum>(K tag) {
    return WireBuilder<(Acc, Next)>._([
      ..._dependencies,
      (Next, tag),
    ], (c) => (_resolveDeps(c), c.getTagged<Next, K>(tag)));
  }

  /// Completes the builder by defining the factory [create] that receives the accumulated dependencies.
  Wire<T> to<T, K extends Enum>(
    T Function(Acc deps) create, {
    K? tag,
    FutureOr<void> Function(T instance)? onDispose,
  }) {
    return Wire<T>._(
      key: (T, tag),
      dependencies: List.unmodifiable(_dependencies),
      create: (c) => create(_resolveDeps(c)),
      onDispose: onDispose,
    );
  }
}

/// Accumulator-based chaining builder for asynchronous [AsyncWire]s.
final class AsyncWireBuilder<Acc> {
  final List<WireKey> _dependencies;
  final Acc Function(Circuit circuit) _resolveDeps;

  AsyncWireBuilder._(this._dependencies, this._resolveDeps);

  /// Appends an untagged dependency of type [Next] to the dependency accumulator.
  AsyncWireBuilder<(Acc, Next)> takes<Next>() {
    return AsyncWireBuilder<(Acc, Next)>._([
      ..._dependencies,
      (Next, null),
    ], (c) => (_resolveDeps(c), c.get<Next>()));
  }

  /// Appends a tagged dependency of type [Next] with [tag] to the dependency accumulator.
  AsyncWireBuilder<(Acc, Next)> takesTagged<Next, K extends Enum>(K tag) {
    return AsyncWireBuilder<(Acc, Next)>._([
      ..._dependencies,
      (Next, tag),
    ], (c) => (_resolveDeps(c), c.getTagged<Next, K>(tag)));
  }

  /// Completes the builder by defining the asynchronous factory [create] that receives the accumulated dependencies.
  AsyncWire<T> to<T, K extends Enum>(
    Future<T> Function(Acc deps) create, {
    K? tag,
    FutureOr<void> Function(T instance)? onDispose,
  }) {
    return AsyncWire<T>._(
      key: (T, tag),
      dependencies: List.unmodifiable(_dependencies),
      create: (c) => create(_resolveDeps(c)),
      onDispose: onDispose,
    );
  }
}

/// Base exception for all circuit-related errors.
sealed class CircuitException implements Exception {
  final String message;

  const CircuitException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when multiple wires are registered with the same [WireKey].
final class DuplicateWireException extends CircuitException {
  final WireKey key;

  DuplicateWireException(super.message, {required this.key});
}

/// Thrown when a wire requires a dependency that was not provided to the circuit.
final class MissingWireException extends CircuitException {
  final WireKey missingKey;
  final WireKey? requiredBy;

  MissingWireException(
    super.message, {
    required this.missingKey,
    this.requiredBy,
  });
}

/// Thrown when a dependency cycle is detected in the circuit graph.
final class CircularDependencyException extends CircuitException {
  final List<WireKey> cycle;

  CircularDependencyException(super.message, {required this.cycle});
}

/// Thrown when looking up a wire that does not exist in the circuit.
final class WireNotFoundException extends CircuitException {
  final WireKey key;

  WireNotFoundException(super.message, {required this.key});
}

/// Thrown when attempting to resolve dependencies on a disposed [Circuit].
final class DisposedCircuitException extends CircuitException {
  const DisposedCircuitException([
    super.message = 'The Circuit has been disposed and cannot be used.',
  ]);
}

/// Thrown when one or more disposal callbacks throw during circuit shutdown.
final class DisposalException extends CircuitException {
  final List<Object> errors;
  final List<StackTrace> stackTraces;

  DisposalException(
    super.message, {
    required this.errors,
    required this.stackTraces,
  });
}

/// A dependency injection container managing lazy synchronous singletons
/// and asynchronously resolved dependencies backed by a Directed Acyclic Graph (DAG).
final class Circuit {
  final Map<WireKey, CircuitWire> _wires;
  final Map<WireKey, Object?> _instances;
  final Map<WireKey, int> _levels;
  final int _maxLevel;

  final Set<WireKey> _creating = {};
  bool _isDisposed = false;
  Future<void>? _disposeFuture;

  Circuit._({
    required this._wires,
    required this._instances,
    required this._levels,
    required this._maxLevel,
  });

  /// Whether this circuit has been shut down via [dispose].
  bool get isDisposed => _isDisposed;

  /// Whether the wire for [key] has been instantiated on an active circuit.
  bool isKeyInitialized(WireKey key) =>
      !_isDisposed && _instances.containsKey(key);

  /// Whether the untagged wire of type [T] has been instantiated.
  bool isInitialized<T>() => isKeyInitialized((T, null));

  /// Whether the tagged wire of type [T] with [tag] has been instantiated.
  bool isInitializedTagged<T, K extends Enum>(K tag) =>
      isKeyInitialized((T, tag));

  /// Builds a [Circuit] from the provided [wires].
  ///
  /// Validates the dependency graph for:
  /// - Duplicate keys -> throws [DuplicateWireException]
  /// - Missing dependencies -> throws [MissingWireException]
  /// - Circular dependencies -> throws [CircularDependencyException]
  ///
  /// Once validated, all [AsyncWire]s are resolved in parallel topological waves
  /// using [Future.wait].
  static Future<Circuit> build(List<CircuitWire> wires) async {
    // 1. Duplicate wire detection
    final wireMap = <WireKey, CircuitWire>{};
    for (final wire in wires) {
      if (wireMap.containsKey(wire.key)) {
        throw DuplicateWireException(
          'Duplicate wire registered for key ${_formatKey(wire.key)}.',
          key: wire.key,
        );
      }
      wireMap[wire.key] = wire;
    }

    // 2. Missing dependency validation
    for (final wire in wires) {
      for (final depKey in wire.dependencies) {
        if (!wireMap.containsKey(depKey)) {
          throw MissingWireException(
            'Missing wire for dependency ${_formatKey(depKey)} required by ${_formatKey(wire.key)}.',
            missingKey: depKey,
            requiredBy: wire.key,
          );
        }
      }
    }

    // 3. Cycle detection (DFS with recursion stack tracking)
    final visitState =
        <WireKey, int>{}; // 0 = unvisited, 1 = visiting, 2 = visited
    final recursionStack = <WireKey>[];

    void checkCycle(WireKey current) {
      visitState[current] = 1;
      recursionStack.add(current);

      final currentWire = wireMap[current]!;
      for (final depKey in currentWire.dependencies) {
        final state = visitState[depKey] ?? 0;
        if (state == 1) {
          final cycleStartIndex = recursionStack.indexOf(depKey);
          final cycle = [...recursionStack.sublist(cycleStartIndex), depKey];
          throw CircularDependencyException(
            'Circular dependency detected: ${cycle.map(_formatKey).join(' -> ')}',
            cycle: List.unmodifiable(cycle),
          );
        } else if (state == 0) {
          checkCycle(depKey);
        }
      }

      recursionStack.removeLast();
      visitState[current] = 2;
    }

    for (final key in wireMap.keys) {
      if ((visitState[key] ?? 0) == 0) {
        checkCycle(key);
      }
    }

    // 4. Compute topological levels
    final levels = <WireKey, int>{};
    int computeLevel(WireKey key) {
      if (levels.containsKey(key)) {
        return levels[key]!;
      }
      final wire = wireMap[key]!;
      if (wire.dependencies.isEmpty) {
        levels[key] = 0;
        return 0;
      }
      var maxDep = 0;
      for (final depKey in wire.dependencies) {
        final depLevel = computeLevel(depKey);
        if (depLevel > maxDep) {
          maxDep = depLevel;
        }
      }
      final level = maxDep + 1;
      levels[key] = level;
      return level;
    }

    var maxLevel = 0;
    for (final key in wireMap.keys) {
      final lvl = computeLevel(key);
      if (lvl > maxLevel) {
        maxLevel = lvl;
      }
    }

    final instances = <WireKey, Object?>{};
    final circuit = Circuit._(
      wires: Map.unmodifiable(wireMap),
      instances: instances,
      levels: Map.unmodifiable(levels),
      maxLevel: maxLevel,
    );

    // 5. Resolve AsyncWires in parallel topological waves
    try {
      for (var i = 0; i <= maxLevel; i++) {
        final asyncWiresAtLevel = wireMap.values
            .where((w) => w.isAsync && levels[w.key] == i)
            .cast<AsyncWire<Object?>>()
            .toList();

        if (asyncWiresAtLevel.isNotEmpty) {
          await Future.wait(
            asyncWiresAtLevel.map((wire) async {
              final instance = await wire._createInstance(circuit);
              instances[wire.key] = instance;
            }),
          );
        }
      }
    } catch (error, stackTrace) {
      try {
        await circuit.dispose();
      } catch (_) {
        // Suppress secondary disposal errors so original build failure is preserved.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }

    return circuit;
  }

  /// Synchronously retrieves the untagged dependency instance of type [T].
  ///
  /// Throws [DisposedCircuitException] if this circuit has been disposed.
  /// Throws [WireNotFoundException] if no wire is registered for [T].
  T get<T>() {
    _checkNotDisposed();
    return _getByKey((T, null)) as T;
  }

  /// Synchronously retrieves the tagged dependency instance of type [T] with [tag].
  ///
  /// Throws [DisposedCircuitException] if this circuit has been disposed.
  /// Throws [WireNotFoundException] if no wire is registered for [T] with [tag].
  T getTagged<T, K extends Enum>(K tag) {
    _checkNotDisposed();
    return _getByKey((T, tag)) as T;
  }

  Object? _getByKey(WireKey key) {
    _checkNotDisposed();

    if (_instances.containsKey(key)) {
      return _instances[key];
    }

    final wire = _wires[key];
    if (wire == null) {
      throw WireNotFoundException(
        'Wire for key ${_formatKey(key)} not found in circuit.',
        key: key,
      );
    }

    if (wire is! Wire) {
      throw StateError(
        'Async wire ${_formatKey(key)} was not resolved during circuit build.',
      );
    }

    if (_creating.contains(key)) {
      throw CircularDependencyException(
        'Circular dependency detected while creating ${_formatKey(key)}.',
        cycle: [..._creating, key],
      );
    }

    _creating.add(key);
    try {
      final instance = wire._createInstance(this);
      _instances[key] = instance;
      return instance;
    } finally {
      _creating.remove(key);
    }
  }

  /// Disposes this circuit in idempotent reverse topological waves (leaves -> roots),
  /// awaiting [onDispose] callbacks in parallel waves.
  ///
  /// Aggregates all disposal failures into a [DisposalException].
  /// Repeated calls after completion are safe no-ops.
  Future<void> dispose() async {
    if (_disposeFuture != null) {
      try {
        await _disposeFuture;
      } catch (_) {
        // If already disposed, subsequent calls are safe no-ops.
      }
      return;
    }
    return _disposeFuture = _performDispose();
  }

  Future<void> _performDispose() async {
    _isDisposed = true;

    final errors = <Object>[];
    final stackTraces = <StackTrace>[];

    try {
      for (var i = _maxLevel; i >= 0; i--) {
        final wiresAtLevel = _wires.values
            .where((w) => _levels[w.key] == i && _instances.containsKey(w.key))
            .toList();

        if (wiresAtLevel.isEmpty) continue;

        await Future.wait(
          wiresAtLevel.map((wire) async {
            try {
              final instance = _instances[wire.key];
              await wire.disposeInstance(instance);
            } catch (error, stackTrace) {
              errors.add(error);
              stackTraces.add(stackTrace);
            }
          }),
        );
      }
    } finally {
      _instances.clear();
    }

    if (errors.isNotEmpty) {
      throw DisposalException(
        'Circuit disposal encountered ${errors.length} error(s).',
        errors: List.unmodifiable(errors),
        stackTraces: List.unmodifiable(stackTraces),
      );
    }
  }

  void _checkNotDisposed() {
    if (_isDisposed) {
      throw const DisposedCircuitException(
        'The Circuit has been disposed and cannot be used.',
      );
    }
  }

  static String _formatKey(WireKey key) {
    final typeName = key.$1.toString();
    if (key.$2 == null) {
      return typeName;
    }
    return '$typeName#${key.$2}';
  }
}
