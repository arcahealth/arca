library;

import 'dart:async';

/// Represents a uniquely typed dependency token in the dependency graph.
///
/// Tokens are identified by object identity (default reference equality).
/// Multiple tokens may have the same underlying type [T], allowing distinct
/// registrations of the same Dart type without collisions.
final class Dependency<T extends Object> {
  final String name;

  const Dependency(this.name);

  Type get type => T;

  @override
  String toString() => 'Dependency<$T>($name)';
}

/// Abstract interface for factory-scoped dependency resolution.
///
/// Only dependencies explicitly declared in the provider's `requires` list
/// can be requested. Any attempt to request an undeclared dependency throws
/// an [UndeclaredDependencyException].
abstract interface class Dependencies {
  /// Synchronously retrieves the declared [dependency].
  ///
  /// Throws [UndeclaredDependencyException] if [dependency] was not declared.
  /// Throws [UnsupportedError] if called inside a synchronous factory for an
  /// asynchronous dependency.
  T require<T extends Object>(Dependency<T> dependency);

  /// Asynchronously retrieves the declared [dependency].
  ///
  /// Throws [UndeclaredDependencyException] if [dependency] was not declared.
  /// Throws [UnsupportedError] if called inside a synchronous factory.
  Future<T> requireAsync<T extends Object>(Dependency<T> dependency);
}

/// A handle representing external ownership of an active dependency instance.
abstract interface class DependencyHandle<T extends Object> {
  /// The active dependency instance.
  ///
  /// Throws [StateError] if this handle has been released or the owning graph
  /// has been disposed.
  T get value;

  /// Whether this handle has been released.
  bool get isReleased;

  /// Whether this handle represents permanent ownership intent.
  bool get isPermanent;

  /// The dependency token this handle manages.
  Dependency<T> get dependency;

  /// Releases this ownership claim.
  ///
  /// Decrements the external reference count of the target dependency instance.
  /// If the reference count drops to zero and no other instances retain it,
  /// the instance is deterministically disposed.
  ///
  /// Calling [release] on an already released handle is a no-op.
  void release();
}

/// Lifecycle states of a provider instance in the runtime graph.
enum InstanceState { uninitialized, initializing, initialized, disposing }

/// Base exception for all dependency graph errors.
sealed class DependencyException implements Exception {
  final String message;

  const DependencyException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when attempting to register a token that is already registered.
final class DuplicateDependencyException extends DependencyException {
  final Dependency<Object> dependency;

  DuplicateDependencyException(super.message, {required this.dependency});
}

/// Thrown when a declared dependency does not exist in the registry during compilation.
final class MissingDependencyException extends DependencyException {
  final Dependency<Object> dependency;
  final Dependency<Object>? requiredBy;

  MissingDependencyException(
    super.message, {
    required this.dependency,
    this.requiredBy,
  });
}

/// Thrown when a circular dependency is detected in the graph during compilation.
final class DependencyCycleException extends DependencyException {
  final List<Dependency<Object>> cycle;

  DependencyCycleException(super.message, {required this.cycle});
}

/// Thrown when a synchronous provider depends directly or transitively on an
/// asynchronous provider, or when attempting synchronous resolution on an async provider.
final class AsyncDependencyException extends DependencyException {
  final List<Dependency<Object>> path;

  AsyncDependencyException(super.message, {required this.path});
}

/// Thrown when a provider factory attempts to access a dependency not declared in its `requires`.
final class UndeclaredDependencyException extends DependencyException {
  final Dependency<Object> requested;
  final Dependency<Object> requestingProvider;
  final Set<Dependency<Object>> declaredDependencies;

  UndeclaredDependencyException(
    super.message, {
    required this.requested,
    required this.requestingProvider,
    required this.declaredDependencies,
  });
}

/// Thrown when performing operations on an already disposed [DependencyGraph].
final class DisposedGraphException extends DependencyException {
  const DisposedGraphException([
    super.message = 'The DependencyGraph has been disposed and cannot be used.',
  ]);
}

/// Thrown when factory execution throws during instance resolution.
final class DependencyResolutionException extends DependencyException {
  final Dependency<Object> dependency;
  final Object cause;
  final StackTrace stackTrace;

  DependencyResolutionException(
    super.message, {
    required this.dependency,
    required this.cause,
    required this.stackTrace,
  });
}

/// Thrown when one or more disposal callbacks throw during graph shutdown or cleanup.
final class DisposalAggregateException extends DependencyException {
  final List<Object> errors;
  final List<StackTrace> stackTraces;

  DisposalAggregateException(
    super.message, {
    required this.errors,
    required this.stackTraces,
  });
}

/// Signature for synchronous provider factories.
typedef Factory<T extends Object> = T Function(Dependencies deps);

/// Signature for asynchronous provider factories.
typedef AsyncFactory<T extends Object> = Future<T> Function(Dependencies deps);

/// Signature for disposal callbacks.
typedef DisposeCallback<T extends Object> = FutureOr<void> Function(T instance);

/// Internal representation of a provider definition before compilation.
sealed class _ProviderDefinition<T extends Object> {
  final Dependency<T> dependency;
  final List<Dependency<Object>> requires;
  final FutureOr<void> Function(Object instance)? dispose;
  final bool isAsync;

  const _ProviderDefinition({
    required this.dependency,
    required this.requires,
    required this.dispose,
    required this.isAsync,
  });
}

final class _SyncProviderDefinition<T extends Object>
    extends _ProviderDefinition<T> {
  final Factory<T> factory;

  _SyncProviderDefinition({
    required super.dependency,
    required this.factory,
    required super.requires,
    super.dispose,
  }) : super(isAsync: false);
}

final class _AsyncProviderDefinition<T extends Object>
    extends _ProviderDefinition<T> {
  final AsyncFactory<T> factory;

  _AsyncProviderDefinition({
    required super.dependency,
    required this.factory,
    required super.requires,
    super.dispose,
  }) : super(isAsync: true);
}

/// Mutable registry for registering providers and compiling them into an immutable [DependencyGraph].
final class DependencyRegistry {
  final Map<Dependency<Object>, _ProviderDefinition<Object>> _definitions = {};

  /// Defines a synchronous provider for [dependency].
  ///
  /// [factory] receives a restricted [Dependencies] resolver containing only
  /// declared dependencies specified in [requires].
  /// [dispose] is invoked when the instance reference count drops to zero or
  /// during graph shutdown.
  void define<T extends Object>(
    Dependency<T> dependency,
    Factory<T> factory, {
    Iterable<Dependency<Object>> requires = const [],
    DisposeCallback<T>? dispose,
  }) {
    _register(
      _SyncProviderDefinition<T>(
        dependency: dependency,
        factory: factory,
        requires: List.unmodifiable(requires),
        dispose: dispose == null ? null : (Object inst) => dispose(inst as T),
      ),
    );
  }

  /// Defines an asynchronous provider for [dependency].
  ///
  /// [factory] returns a [Future] of [T] and receives a restricted [Dependencies]
  /// resolver containing only declared dependencies specified in [requires].
  /// [dispose] is invoked when the instance reference count drops to zero or
  /// during graph shutdown.
  void defineAsync<T extends Object>(
    Dependency<T> dependency,
    AsyncFactory<T> factory, {
    Iterable<Dependency<Object>> requires = const [],
    DisposeCallback<T>? dispose,
  }) {
    _register(
      _AsyncProviderDefinition<T>(
        dependency: dependency,
        factory: factory,
        requires: List.unmodifiable(requires),
        dispose: dispose == null ? null : (Object inst) => dispose(inst as T),
      ),
    );
  }

  void _register<T extends Object>(_ProviderDefinition<T> definition) {
    if (_definitions.containsKey(definition.dependency)) {
      throw DuplicateDependencyException(
        'Duplicate registration for ${definition.dependency}. Tokens must be unique.',
        dependency: definition.dependency,
      );
    }
    _definitions[definition.dependency] = definition;
  }

  /// Compiles registered provider definitions into an immutable [DependencyGraph].
  ///
  /// Validates dependency existence, detects circular dependencies, and validates
  /// sync/async compatibility. No provider instances are constructed during compilation.
  DependencyGraph compile() {
    return _GraphCompiler.compile(Map.unmodifiable(_definitions));
  }
}

/// An immutable compiled graph node.
final class _CompiledNode {
  final Dependency<Object> dependency;
  final _ProviderDefinition<Object> definition;
  final Set<Dependency<Object>> requires;
  final Set<Dependency<Object>> dependents;
  final bool isAsync;
  final bool transitivelyAsync;

  _CompiledNode({
    required this.dependency,
    required this.definition,
    required this.requires,
    required this.dependents,
    required this.isAsync,
    required this.transitivelyAsync,
  });
}

/// Internal compiler responsible for graph validation and building immutable topology.
abstract final class _GraphCompiler {
  static DependencyGraph compile(
    Map<Dependency<Object>, _ProviderDefinition<Object>> definitions,
  ) {
    // 1. Missing dependency validation
    for (final entry in definitions.entries) {
      final node = entry.value;
      for (final req in node.requires) {
        if (!definitions.containsKey(req)) {
          throw MissingDependencyException(
            'Missing dependency $req required by ${node.dependency}.',
            dependency: req,
            requiredBy: node.dependency,
          );
        }
      }
    }

    // 2. Cycle detection (Tarjan/DFS with path tracking)
    final visited = <Dependency<Object>>{};
    final recursionStack = <Dependency<Object>>[];
    final inStack = <Dependency<Object>>{};

    void checkCycle(Dependency<Object> current) {
      visited.add(current);
      recursionStack.add(current);
      inStack.add(current);

      final def = definitions[current]!;
      for (final req in def.requires) {
        if (!visited.contains(req)) {
          checkCycle(req);
        } else if (inStack.contains(req)) {
          final cycleStartIndex = recursionStack.indexOf(req);
          final cycle = [...recursionStack.sublist(cycleStartIndex), req];
          throw DependencyCycleException(
            'Circular dependency detected: ${cycle.map((d) => d.toString()).join(' -> ')}',
            cycle: List.unmodifiable(cycle),
          );
        }
      }

      inStack.remove(current);
      recursionStack.removeLast();
    }

    for (final token in definitions.keys) {
      if (!visited.contains(token)) {
        checkCycle(token);
      }
    }

    // 3. Sync/Async compatibility & transitive async detection
    List<Dependency<Object>>? findPathToAsync(
      Dependency<Object> start,
      Set<Dependency<Object>> seen,
    ) {
      seen.add(start);
      final def = definitions[start]!;
      for (final req in def.requires) {
        final reqDef = definitions[req]!;
        if (reqDef.isAsync) {
          return [start, req];
        }
        if (!seen.contains(req)) {
          final subPath = findPathToAsync(req, seen);
          if (subPath != null) {
            return [start, ...subPath];
          }
        }
      }
      return null;
    }

    final transitivelyAsyncMap = <Dependency<Object>, bool>{};
    for (final entry in definitions.entries) {
      final token = entry.key;
      final def = entry.value;
      final pathToAsync = findPathToAsync(token, <Dependency<Object>>{});
      final isTransAsync = def.isAsync || pathToAsync != null;
      transitivelyAsyncMap[token] = isTransAsync;

      if (!def.isAsync && pathToAsync != null) {
        throw AsyncDependencyException(
          'Synchronous provider $token cannot depend directly or transitively on asynchronous provider ${pathToAsync.last}. '
          'Path: ${pathToAsync.map((d) => d.toString()).join(' -> ')}',
          path: List.unmodifiable(pathToAsync),
        );
      }
    }

    // 4. Build dependents (reverse edges)
    final dependentsMap = <Dependency<Object>, Set<Dependency<Object>>>{};
    for (final token in definitions.keys) {
      dependentsMap[token] = <Dependency<Object>>{};
    }
    for (final entry in definitions.entries) {
      for (final req in entry.value.requires) {
        dependentsMap[req]!.add(entry.key);
      }
    }

    // 5. Build immutable compiled nodes
    final compiledNodes = <Dependency<Object>, _CompiledNode>{};
    for (final entry in definitions.entries) {
      final token = entry.key;
      final def = entry.value;
      compiledNodes[token] = _CompiledNode(
        dependency: token,
        definition: def,
        requires: Set.unmodifiable(def.requires),
        dependents: Set.unmodifiable(dependentsMap[token]!),
        isAsync: def.isAsync,
        transitivelyAsync: transitivelyAsyncMap[token]!,
      );
    }

    return DependencyGraph._(Map.unmodifiable(compiledNodes));
  }
}

/// Runtime state container for a specific compiled node.
final class _NodeRuntime {
  final _CompiledNode node;

  InstanceState state = InstanceState.uninitialized;
  Object? instance;
  Future<void>? inFlightFuture;

  bool isGraphRetained = false;
  int externalRefCount = 0;
  int internalRefCount = 0;
  int get totalRefCount =>
      (isGraphRetained ? 1 : 0) + externalRefCount + internalRefCount;

  final Set<Dependency<Object>> retainedDependencies = {};
  final Set<_DependencyHandleImpl<Object>> activeHandles = {};

  _NodeRuntime(this.node);
}

/// Restricted dependency resolver for synchronous provider factories.
final class _RestrictedSyncDependencies implements Dependencies {
  final Dependency<Object> requestingProvider;
  final Set<Dependency<Object>> allowedDependencies;
  final Map<Dependency<Object>, _NodeRuntime> runtimes;

  _RestrictedSyncDependencies({
    required this.requestingProvider,
    required this.allowedDependencies,
    required this.runtimes,
  });

  @override
  T require<T extends Object>(Dependency<T> dependency) {
    if (!allowedDependencies.contains(dependency)) {
      throw UndeclaredDependencyException(
        'Provider $requestingProvider attempted to access undeclared dependency $dependency. Declare it in `requires`.',
        requested: dependency,
        requestingProvider: requestingProvider,
        declaredDependencies: allowedDependencies,
      );
    }
    final runtime = runtimes[dependency]!;
    if (runtime.state != InstanceState.initialized) {
      throw StateError(
        'Dependency $dependency is not in initialized state (state: ${runtime.state}).',
      );
    }
    return runtime.instance as T;
  }

  @override
  Future<T> requireAsync<T extends Object>(Dependency<T> dependency) {
    if (!allowedDependencies.contains(dependency)) {
      throw UndeclaredDependencyException(
        'Provider $requestingProvider attempted to access undeclared dependency $dependency. Declare it in `requires`.',
        requested: dependency,
        requestingProvider: requestingProvider,
        declaredDependencies: allowedDependencies,
      );
    }
    throw AsyncDependencyException(
      'Cannot call requireAsync inside a synchronous provider factory for $requestingProvider.',
      path: [requestingProvider, dependency],
    );
  }
}

/// Restricted dependency resolver for asynchronous provider factories.
final class _RestrictedAsyncDependencies implements Dependencies {
  final Dependency<Object> requestingProvider;
  final Set<Dependency<Object>> allowedDependencies;
  final Map<Dependency<Object>, _NodeRuntime> runtimes;

  _RestrictedAsyncDependencies({
    required this.requestingProvider,
    required this.allowedDependencies,
    required this.runtimes,
  });

  @override
  T require<T extends Object>(Dependency<T> dependency) {
    if (!allowedDependencies.contains(dependency)) {
      throw UndeclaredDependencyException(
        'Provider $requestingProvider attempted to access undeclared dependency $dependency. Declare it in `requires`.',
        requested: dependency,
        requestingProvider: requestingProvider,
        declaredDependencies: allowedDependencies,
      );
    }
    final runtime = runtimes[dependency]!;
    if (runtime.state != InstanceState.initialized) {
      throw StateError(
        'Dependency $dependency is not in initialized state (state: ${runtime.state}).',
      );
    }
    return runtime.instance as T;
  }

  @override
  Future<T> requireAsync<T extends Object>(Dependency<T> dependency) async {
    return require<T>(dependency);
  }
}

/// Concrete implementation of [DependencyHandle].
final class _DependencyHandleImpl<T extends Object>
    implements DependencyHandle<T> {
  @override
  final Dependency<T> dependency;
  @override
  final bool isPermanent;

  final _NodeRuntime runtime;
  final DependencyGraph graph;

  bool _isReleased = false;

  _DependencyHandleImpl({
    required this.dependency,
    required this.runtime,
    required this.graph,
    required this.isPermanent,
  });

  @override
  bool get isReleased => _isReleased;

  @override
  T get value {
    if (_isReleased || graph.isDisposed) {
      throw StateError(
        'Cannot access value of released handle or disposed graph for $dependency.',
      );
    }
    final inst = runtime.instance;
    if (inst == null) {
      throw StateError('Instance for $dependency is not available.');
    }
    return inst as T;
  }

  @override
  void release() {
    if (_isReleased) return;
    _isReleased = true;
    graph._onHandleReleased(this);
  }

  void _markInvalidated() {
    _isReleased = true;
  }
}

/// Read-only diagnostics and introspection interface for [DependencyGraph].
abstract interface class DependencyGraphDiagnostics {
  /// All registered dependency tokens.
  List<Dependency<Object>> get registeredTokens;

  /// Root tokens (tokens that no other provider in the graph depends on).
  List<Dependency<Object>> get rootTokens;

  /// Leaf tokens (tokens that have no dependencies).
  List<Dependency<Object>> get leafTokens;

  /// Direct declared dependencies of [dependency].
  List<Dependency<Object>> dependenciesOf(Dependency<Object> dependency);

  /// Direct dependents of [dependency] (providers that declare [dependency] in requires).
  List<Dependency<Object>> dependentsOf(Dependency<Object> dependency);

  /// Whether [dependency] is declared as an asynchronous provider.
  bool isAsync(Dependency<Object> dependency);

  /// Whether [dependency] depends directly or transitively on an asynchronous provider.
  bool isTransitivelyAsync(Dependency<Object> dependency);

  /// Whether [dependency] is retained permanently under the graph caching policy via [resolve].
  bool isGraphRetained(Dependency<Object> dependency);

  /// Current runtime state of [dependency].
  InstanceState stateOf(Dependency<Object> dependency);

  /// External reference count of [dependency] (active handles).
  int externalRefCountOf(Dependency<Object> dependency);

  /// Internal reference count of [dependency] (initialized dependent instances).
  int internalRefCountOf(Dependency<Object> dependency);

  /// Total reference count of [dependency].
  int totalRefCountOf(Dependency<Object> dependency);

  /// Chronological construction order of currently and previously initialized instances.
  List<Dependency<Object>> get constructionOrder;

  /// Chronological disposal order of disposed instances.
  List<Dependency<Object>> get disposalOrder;

  /// Formatted diagnostic dump of graph topology and runtime state.
  String dump();
}

final class _DependencyGraphDiagnosticsImpl
    implements DependencyGraphDiagnostics {
  final DependencyGraph _graph;

  _DependencyGraphDiagnosticsImpl(this._graph);

  @override
  List<Dependency<Object>> get registeredTokens =>
      _graph._compiledNodes.keys.toList();

  @override
  List<Dependency<Object>> get rootTokens => _graph._compiledNodes.values
      .where((node) => node.dependents.isEmpty)
      .map((node) => node.dependency)
      .toList();

  @override
  List<Dependency<Object>> get leafTokens => _graph._compiledNodes.values
      .where((node) => node.requires.isEmpty)
      .map((node) => node.dependency)
      .toList();

  @override
  List<Dependency<Object>> dependenciesOf(Dependency<Object> dependency) {
    return _graph._getNode(dependency).requires.toList();
  }

  @override
  List<Dependency<Object>> dependentsOf(Dependency<Object> dependency) {
    return _graph._getNode(dependency).dependents.toList();
  }

  @override
  bool isAsync(Dependency<Object> dependency) {
    return _graph._getNode(dependency).isAsync;
  }

  @override
  bool isTransitivelyAsync(Dependency<Object> dependency) {
    return _graph._getNode(dependency).transitivelyAsync;
  }

  @override
  bool isGraphRetained(Dependency<Object> dependency) {
    return _graph._getRuntime(dependency).isGraphRetained;
  }

  @override
  InstanceState stateOf(Dependency<Object> dependency) {
    return _graph._getRuntime(dependency).state;
  }

  @override
  int externalRefCountOf(Dependency<Object> dependency) {
    return _graph._getRuntime(dependency).externalRefCount;
  }

  @override
  int internalRefCountOf(Dependency<Object> dependency) {
    return _graph._getRuntime(dependency).internalRefCount;
  }

  @override
  int totalRefCountOf(Dependency<Object> dependency) {
    return _graph._getRuntime(dependency).totalRefCount;
  }

  @override
  List<Dependency<Object>> get constructionOrder =>
      List.unmodifiable(_graph._constructionOrder);

  @override
  List<Dependency<Object>> get disposalOrder =>
      List.unmodifiable(_graph._disposalOrder);

  @override
  String dump() {
    final buffer = StringBuffer('DependencyGraph Diagnostics Dump:\n');
    buffer.writeln('Disposed: ${_graph.isDisposed}');
    buffer.writeln('Nodes (${_graph._compiledNodes.length}):');
    for (final node in _graph._compiledNodes.values) {
      final runtime = _graph._runtimes[node.dependency]!;
      buffer.writeln(
        '  - ${node.dependency} [${node.isAsync ? "async" : "sync"}, state: ${runtime.state.name}, '
        'refCount: ${runtime.totalRefCount} (graph: ${runtime.isGraphRetained}, ext: ${runtime.externalRefCount}, int: ${runtime.internalRefCount})]',
      );
      buffer.writeln(
        '      requires: [${node.requires.map((d) => d.name).join(", ")}]',
      );
      buffer.writeln(
        '      dependents: [${node.dependents.map((d) => d.name).join(", ")}]',
      );
    }
    buffer.writeln('Roots: [${rootTokens.map((d) => d.name).join(", ")}]');
    buffer.writeln('Leaves: [${leafTokens.map((d) => d.name).join(", ")}]');
    buffer.writeln(
      'Construction Order: [${_graph._constructionOrder.map((d) => d.name).join(" -> ")}]',
    );
    buffer.writeln(
      'Disposal Order: [${_graph._disposalOrder.map((d) => d.name).join(" -> ")}]',
    );
    return buffer.toString();
  }
}

/// An immutable dependency graph providing lazy, reference-counted resolution.
///
/// Created by calling [DependencyRegistry.compile].
final class DependencyGraph {
  final Map<Dependency<Object>, _CompiledNode> _compiledNodes;
  final Map<Dependency<Object>, _NodeRuntime> _runtimes;

  final List<Dependency<Object>> _constructionOrder = [];
  final List<Dependency<Object>> _disposalOrder = [];

  bool _isDisposed = false;
  late final DependencyGraphDiagnostics _diagnostics;

  DependencyGraph._(this._compiledNodes)
    : _runtimes = {
        for (final entry in _compiledNodes.entries)
          entry.key: _NodeRuntime(entry.value),
      } {
    _diagnostics = _DependencyGraphDiagnosticsImpl(this);
  }

  /// Whether this graph has been shut down via [dispose].
  bool get isDisposed => _isDisposed;

  /// Read-only diagnostics for graph topology and runtime state.
  DependencyGraphDiagnostics get diagnostics => _diagnostics;

  /// Resolves [dependency] under the graph's permanent caching policy.
  ///
  /// The returned instance is kept alive by the graph until [dispose] is called.
  /// Repeated calls return the existing graph-owned instance without creating
  /// cumulative ownership claims or inflating reference counts.
  ///
  /// Throws [AsyncDependencyException] if [dependency] or any of its transitive
  /// dependencies is asynchronous.
  T resolve<T extends Object>(Dependency<T> dependency) {
    _checkNotDisposed();
    final runtime = _getRuntime(dependency);

    if (runtime.node.transitivelyAsync) {
      throw AsyncDependencyException(
        'Cannot synchronously resolve asynchronous dependency $dependency. Use resolveAsync instead.',
        path: [dependency],
      );
    }

    runtime.isGraphRetained = true;
    try {
      if (runtime.state != InstanceState.initialized) {
        _resolveNodeSync(runtime);
      }
      return runtime.instance as T;
    } catch (_) {
      if (runtime.state != InstanceState.initialized) {
        runtime.isGraphRetained = false;
      }
      rethrow;
    }
  }

  /// Asynchronously resolves [dependency] under the graph's permanent caching policy.
  ///
  /// The returned instance is kept alive by the graph until [dispose] is called.
  /// Repeated calls return the existing graph-owned instance without creating
  /// cumulative ownership claims or inflating reference counts.
  ///
  /// Supports both synchronous and asynchronous providers.
  Future<T> resolveAsync<T extends Object>(Dependency<T> dependency) async {
    _checkNotDisposed();
    final runtime = _getRuntime(dependency);

    runtime.isGraphRetained = true;
    try {
      if (runtime.state != InstanceState.initialized) {
        await _resolveNodeAsync(runtime);
        _checkNotDisposed();
      }
      return runtime.instance as T;
    } catch (_) {
      if (runtime.state != InstanceState.initialized) {
        runtime.isGraphRetained = false;
      }
      rethrow;
    }
  }

  /// Acquires a permanent ownership handle for [dependency].
  ///
  /// The instance remains alive until the returned [DependencyHandle.release] is called
  /// or until graph [dispose].
  DependencyHandle<T> retain<T extends Object>(Dependency<T> dependency) {
    return _createHandleSync<T>(dependency, isPermanent: true);
  }

  /// Acquires an ephemeral ownership handle for [dependency].
  ///
  /// When released, if no other handles or dependent instances retain it,
  /// the instance is deterministically disposed.
  DependencyHandle<T> acquire<T extends Object>(Dependency<T> dependency) {
    return _createHandleSync<T>(dependency, isPermanent: false);
  }

  /// Asynchronously acquires a permanent ownership handle for [dependency].
  Future<DependencyHandle<T>> retainAsync<T extends Object>(
    Dependency<T> dependency,
  ) {
    return _createHandleAsync<T>(dependency, isPermanent: true);
  }

  /// Asynchronously acquires an ephemeral ownership handle for [dependency].
  Future<DependencyHandle<T>> acquireAsync<T extends Object>(
    Dependency<T> dependency,
  ) {
    return _createHandleAsync<T>(dependency, isPermanent: false);
  }

  DependencyHandle<T> _createHandleSync<T extends Object>(
    Dependency<T> dependency, {
    required bool isPermanent,
  }) {
    _checkNotDisposed();
    final runtime = _getRuntime(dependency);

    if (runtime.node.transitivelyAsync) {
      throw AsyncDependencyException(
        'Cannot synchronously resolve asynchronous dependency $dependency. Use acquireAsync or retainAsync instead.',
        path: [dependency],
      );
    }

    _resolveNodeSync(runtime);

    runtime.externalRefCount++;
    final handle = _DependencyHandleImpl<T>(
      dependency: dependency,
      runtime: runtime,
      graph: this,
      isPermanent: isPermanent,
    );
    runtime.activeHandles.add(handle);
    return handle;
  }

  Future<DependencyHandle<T>> _createHandleAsync<T extends Object>(
    Dependency<T> dependency, {
    required bool isPermanent,
  }) async {
    _checkNotDisposed();
    final runtime = _getRuntime(dependency);

    // Increment externalRefCount so ownership exists while initialization awaits
    runtime.externalRefCount++;
    final handle = _DependencyHandleImpl<T>(
      dependency: dependency,
      runtime: runtime,
      graph: this,
      isPermanent: isPermanent,
    );
    runtime.activeHandles.add(handle);

    try {
      await _resolveNodeAsync(runtime);
      _checkNotDisposed();

      if (handle.isReleased) {
        throw DisposedGraphException(
          'Handle for $dependency was released before asynchronous resolution completed.',
        );
      }
      return handle;
    } catch (e) {
      handle.release();
      rethrow;
    }
  }

  void _resolveNodeSync(_NodeRuntime runtime) {
    if (runtime.state == InstanceState.initialized) {
      return;
    }
    if (runtime.state == InstanceState.initializing) {
      throw DependencyCycleException(
        'Reentrant synchronous initialization detected for ${runtime.node.dependency}.',
        cycle: [runtime.node.dependency, runtime.node.dependency],
      );
    }
    if (runtime.state == InstanceState.disposing) {
      throw StateError(
        'Cannot resolve ${runtime.node.dependency} while it is disposing.',
      );
    }

    runtime.state = InstanceState.initializing;
    final newlyRetained = <Dependency<Object>>[];

    try {
      // 1. Retain and resolve declared dependencies synchronously
      for (final depToken in runtime.node.requires) {
        final depRuntime = _runtimes[depToken]!;
        depRuntime.internalRefCount++;
        runtime.retainedDependencies.add(depToken);
        newlyRetained.add(depToken);
        _resolveNodeSync(depRuntime);
      }

      // 2. Pass restricted resolver
      final restrictedDeps = _RestrictedSyncDependencies(
        requestingProvider: runtime.node.dependency,
        allowedDependencies: runtime.node.requires,
        runtimes: _runtimes,
      );

      // 3. Construct instance
      final syncDef =
          runtime.node.definition as _SyncProviderDefinition<Object>;
      final instance = syncDef.factory(restrictedDeps);

      runtime.instance = instance;
      runtime.state = InstanceState.initialized;
      _constructionOrder.add(runtime.node.dependency);
    } catch (error, stackTrace) {
      // Rollback partially retained dependencies on failure
      for (final depToken in newlyRetained) {
        final depRuntime = _runtimes[depToken]!;
        depRuntime.internalRefCount--;
        runtime.retainedDependencies.remove(depToken);
        if (depRuntime.totalRefCount <= 0 &&
            depRuntime.state == InstanceState.initialized) {
          _disposeNode(depRuntime);
        }
      }
      runtime.state = InstanceState.uninitialized;
      runtime.instance = null;

      if (error is DependencyException) {
        rethrow;
      }
      throw DependencyResolutionException(
        'Failed to construct ${runtime.node.dependency}: $error',
        dependency: runtime.node.dependency,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _resolveNodeAsync(_NodeRuntime runtime) async {
    if (runtime.state == InstanceState.initialized) {
      return;
    }
    if (runtime.state == InstanceState.initializing) {
      if (runtime.inFlightFuture != null) {
        await runtime.inFlightFuture;
        return;
      }
      throw DependencyCycleException(
        'Reentrant initialization detected for ${runtime.node.dependency}.',
        cycle: [runtime.node.dependency, runtime.node.dependency],
      );
    }
    if (runtime.state == InstanceState.disposing) {
      throw StateError(
        'Cannot resolve ${runtime.node.dependency} while it is disposing.',
      );
    }

    final completer = Completer<void>();
    runtime.inFlightFuture = completer.future;
    runtime.state = InstanceState.initializing;
    final newlyRetained = <Dependency<Object>>[];

    try {
      // 1. Retain and resolve declared dependencies
      for (final depToken in runtime.node.requires) {
        final depRuntime = _runtimes[depToken]!;
        depRuntime.internalRefCount++;
        runtime.retainedDependencies.add(depToken);
        newlyRetained.add(depToken);
        await _resolveNodeAsync(depRuntime);
      }

      // 2. Restricted resolver
      final restrictedDeps = _RestrictedAsyncDependencies(
        requestingProvider: runtime.node.dependency,
        allowedDependencies: runtime.node.requires,
        runtimes: _runtimes,
      );

      // 3. Construct instance
      final Object instance;
      if (runtime.node.isAsync) {
        final asyncDef =
            runtime.node.definition as _AsyncProviderDefinition<Object>;
        instance = await asyncDef.factory(restrictedDeps);
      } else {
        final syncDef =
            runtime.node.definition as _SyncProviderDefinition<Object>;
        instance = syncDef.factory(restrictedDeps);
      }

      runtime.instance = instance;

      // Check if all owners released claims while factory was awaiting
      if (runtime.totalRefCount <= 0) {
        runtime.state = InstanceState.initialized;
        _disposeNode(runtime);
      } else {
        runtime.state = InstanceState.initialized;
        _constructionOrder.add(runtime.node.dependency);
      }

      completer.complete();
    } catch (error, stackTrace) {
      // Rollback
      for (final depToken in newlyRetained) {
        final depRuntime = _runtimes[depToken]!;
        depRuntime.internalRefCount--;
        runtime.retainedDependencies.remove(depToken);
        if (depRuntime.totalRefCount <= 0 &&
            depRuntime.state == InstanceState.initialized) {
          _disposeNode(depRuntime);
        }
      }
      runtime.state = InstanceState.uninitialized;
      runtime.instance = null;

      final resolutionError = error is DependencyException
          ? error
          : DependencyResolutionException(
              'Failed to construct ${runtime.node.dependency}: $error',
              dependency: runtime.node.dependency,
              cause: error,
              stackTrace: stackTrace,
            );
      completer.completeError(resolutionError, stackTrace);
      completer.future.ignore();
      throw resolutionError;
    } finally {
      runtime.inFlightFuture = null;
    }
  }

  void _onHandleReleased(_DependencyHandleImpl<Object> handle) {
    if (_isDisposed) return;
    final runtime = handle.runtime;
    runtime.activeHandles.remove(handle);
    runtime.externalRefCount--;

    if (runtime.totalRefCount <= 0 &&
        runtime.state == InstanceState.initialized) {
      _disposeNode(runtime);
    }
  }

  void _disposeNode(_NodeRuntime runtime) {
    if (runtime.state != InstanceState.initialized) return;

    runtime.state = InstanceState.disposing;

    // Invalidate any lingering handles
    for (final handle in runtime.activeHandles) {
      handle._markInvalidated();
    }
    runtime.activeHandles.clear();

    // Execute disposal callback
    final dispose = runtime.node.definition.dispose;
    if (dispose != null && runtime.instance != null) {
      try {
        final res = dispose(runtime.instance!);
        if (res is Future) {
          // Fire and forget unawaited during synchronous handle release
          res.ignore();
        }
      } catch (_) {
        // Ignored during synchronous handle cascading
      }
    }

    // Release internally retained dependencies
    final retained = List.of(runtime.retainedDependencies);
    runtime.retainedDependencies.clear();
    for (final depToken in retained) {
      final depRuntime = _runtimes[depToken]!;
      depRuntime.internalRefCount--;
      if (depRuntime.totalRefCount <= 0 &&
          depRuntime.state == InstanceState.initialized) {
        _disposeNode(depRuntime);
      }
    }

    _constructionOrder.remove(runtime.node.dependency);
    _disposalOrder.add(runtime.node.dependency);
    runtime.isGraphRetained = false;
    runtime.instance = null;
    runtime.state = InstanceState.uninitialized;
  }

  /// Authoritatively shuts down the entire dependency graph.
  ///
  /// Disposes every initialized instance in reverse dependency/construction order.
  /// Invalidates all outstanding handles and rejects any subsequent resolutions.
  ///
  /// If one or more disposal callbacks throw, cleanup continues for all remaining
  /// instances, and a [DisposalAggregateException] is thrown containing all caught errors.
  ///
  /// Repeated calls to [dispose] are safe and idempotent.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    // Await any in-flight asynchronous initializations before shutting down
    for (final runtime in _runtimes.values) {
      if (runtime.inFlightFuture != null) {
        try {
          await runtime.inFlightFuture;
        } catch (_) {
          // Ignore failures of in-flight initializations during shutdown
        }
      }
    }

    // Invalidate all active external handles
    for (final runtime in _runtimes.values) {
      for (final handle in runtime.activeHandles) {
        handle._markInvalidated();
      }
      runtime.activeHandles.clear();
    }

    final errors = <Object>[];
    final stackTraces = <StackTrace>[];

    // Dispose in reverse construction order (guarantees reverse dependency order)
    final orderToDispose = List.of(_constructionOrder.reversed);
    for (final token in orderToDispose) {
      final runtime = _runtimes[token]!;
      if (runtime.state != InstanceState.initialized) continue;

      runtime.state = InstanceState.disposing;
      final dispose = runtime.node.definition.dispose;
      if (dispose != null && runtime.instance != null) {
        try {
          final res = dispose(runtime.instance!);
          if (res is Future) {
            await res;
          }
        } catch (e, st) {
          errors.add(e);
          stackTraces.add(st);
        }
      }

      runtime.isGraphRetained = false;
      runtime.instance = null;
      runtime.state = InstanceState.uninitialized;
      runtime.retainedDependencies.clear();
      runtime.internalRefCount = 0;
      runtime.externalRefCount = 0;
      _disposalOrder.add(token);
    }

    _constructionOrder.clear();

    if (errors.isNotEmpty) {
      throw DisposalAggregateException(
        'One or more disposal callbacks threw errors during graph disposal.',
        errors: List.unmodifiable(errors),
        stackTraces: List.unmodifiable(stackTraces),
      );
    }
  }

  void _checkNotDisposed() {
    if (_isDisposed) {
      throw const DisposedGraphException();
    }
  }

  _CompiledNode _getNode(Dependency<Object> dependency) {
    final node = _compiledNodes[dependency];
    if (node == null) {
      throw MissingDependencyException(
        'Dependency $dependency is not registered in this graph.',
        dependency: dependency,
      );
    }
    return node;
  }

  _NodeRuntime _getRuntime(Dependency<Object> dependency) {
    final runtime = _runtimes[dependency];
    if (runtime == null) {
      throw MissingDependencyException(
        'Dependency $dependency is not registered in this graph.',
        dependency: dependency,
      );
    }
    return runtime;
  }
}
