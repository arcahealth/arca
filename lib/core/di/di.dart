library;

import 'dart:async';

// Alias for factory builder
typedef IndexableBuilder<T extends Indexable> = FutureOr<T> Function(
  IndexReader index,
);
typedef DisposeFactory<T extends Indexable> = FutureOr<void> Function(T);

// Marker for entities to declare themselves as indexable
abstract interface class Indexable;

/// An interface exposing write only view of an [Indexer].
abstract interface class IndexWriter {
  void index<T extends Indexable>(
    IndexableBuilder<T> builder, {
    List<Type> dependsOn = const [],
    DisposeFactory<T>? dispose,
  });
}

/// An interface exposing read only view of an [Indexer].
abstract interface class IndexReader {
  T lookup<T extends Indexable>(Type type);
}

/// An interface describing the shape of internal data structure used for an [Indexer].
abstract interface class IndexBackend implements IndexReader {
  void add<T extends Indexable>(IndexNode<T> node);

  IndexState get state;

  Future<void> build();
  Future<void> dispose();

  // Diagnostics
  Map<Type, List<Type>> get graph;
  List<Type> get roots;
  List<Type> get buildOrder;
  List<Type> dependenciesOf(Type type);
  List<Type> resolveOrderOf(Type type);
  String describe();
}

enum IndexState { idle, built, dispose }

final class IndexNode<T extends Indexable>(
  final IndexableBuilder<T> builder, {
  final List<Type> dependsOn = const [],
  final DisposeFactory<T>? dispose,
}) {
  Type get type => T;
}

final class _GraphIndexBackend() implements IndexBackend {
  @override
  void add<T extends Indexable>(IndexNode<T> node) {
    // TODO: implement add
  }

  @override
  Future<void> build() {
    // TODO: implement build
    throw UnimplementedError();
  }

  @override
  // TODO: implement buildOrder
  List<Type> get buildOrder => throw UnimplementedError();

  @override
  List<Type> dependenciesOf(Type type) {
    // TODO: implement dependenciesOf
    throw UnimplementedError();
  }

  @override
  String describe() {
    // TODO: implement describe
    throw UnimplementedError();
  }

  @override
  Future<void> dispose() {
    // TODO: implement dispose
    throw UnimplementedError();
  }

  @override
  // TODO: implement graph
  Map<Type, List<Type>> get graph => throw UnimplementedError();

  @override
  // TODO: implement isBuilt
  IndexState get state => throw UnimplementedError();

  @override
  FutureOr<T> lookup<T extends Indexable>(Type type) {
    // TODO: implement lookup
    throw UnimplementedError();
  }

  @override
  List<Type> resolveOrderOf(Type type) {
    // TODO: implement resolveOrderOf
    throw UnimplementedError();
  }

  @override
  // TODO: implement roots
  List<Type> get roots => throw UnimplementedError();
}

final class Indexer([IndexBackend? backend])
    implements IndexReader, IndexWriter {
  this : _backend = backend ?? _GraphIndexBackend();

  final IndexBackend _backend;

  Future<void> build() => _backend.build();
  Future<void> dispose() => _backend.dispose();
  String describe() => _backend.describe();

  List<Type> dependenciesOf(Type type) => _backend.dependenciesOf(type);
  List<Type> resolveOrderOf(Type type) => _backend.resolveOrderOf(type);

  @override
  void index<T extends Indexable>(
    IndexableBuilder<T> builder, {
    List<Type> dependsOn = const [],
    DisposeFactory<T>? dispose,
  }) {
    _backend.add(.new(builder, dependsOn: dependsOn, dispose: dispose));
  }

  @override
  FutureOr<T> lookup<T extends Indexable>(Type type) => _backend.lookup(type);
}
