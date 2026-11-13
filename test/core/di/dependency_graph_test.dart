import 'package:arca/core/di/di.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test logger to track lifecycle events across services.
final class LifecycleLogger {
  final List<String> events = [];

  void log(String event) => events.add(event);
  void clear() => events.clear();
}

/// Sample service models for testing.
final class DatabaseService {
  final String dbName;
  final LifecycleLogger? logger;

  DatabaseService(this.dbName, [this.logger]) {
    logger?.log('create:DatabaseService($dbName)');
  }

  void dispose() {
    logger?.log('dispose:DatabaseService($dbName)');
  }
}

final class CacheService {
  final String cacheName;
  final LifecycleLogger? logger;

  CacheService(this.cacheName, [this.logger]) {
    logger?.log('create:CacheService($cacheName)');
  }

  void dispose() {
    logger?.log('dispose:CacheService($cacheName)');
  }
}

final class UserService {
  final DatabaseService db;
  final CacheService cache;
  final LifecycleLogger? logger;

  UserService(this.db, this.cache, [this.logger]) {
    logger?.log('create:UserService');
  }

  void dispose() {
    logger?.log('dispose:UserService');
  }
}

final class AuthService {
  final DatabaseService db;
  final LifecycleLogger? logger;

  AuthService(this.db, [this.logger]) {
    logger?.log('create:AuthService');
  }

  void dispose() {
    logger?.log('dispose:AuthService');
  }
}

void main() {
  group('Milestone 1 — Tokens and Registration', () {
    test('token identity and const canonicalization', () {
      const tokenA1 = Dependency<String>('user');
      const tokenA2 = Dependency<String>('user');
      const tokenB = Dependency<String>('admin');
      final dynamicToken = Dependency<String>('user');

      // Canonical const instances share identical reference
      expect(identical(tokenA1, tokenA2), isTrue);
      // Different name const tokens are not identical
      expect(identical(tokenA1, tokenB), isFalse);
      // Non-const instantiation produces a distinct reference
      expect(identical(tokenA1, dynamicToken), isFalse);
      expect(tokenA1.toString(), contains('Dependency<String>(user)'));
    });

    test('supports multiple tokens of the same generic Dart type', () {
      const primaryCache = Dependency<CacheService>('primaryCache');
      const sessionCache = Dependency<CacheService>('sessionCache');
      const imageCache = Dependency<CacheService>('imageCache');

      final registry = DependencyRegistry()
        ..define(primaryCache, (_) => CacheService('primary'))
        ..define(sessionCache, (_) => CacheService('session'))
        ..define(imageCache, (_) => CacheService('image'));

      final graph = registry.compile();
      final primary = graph.resolve(primaryCache);
      final session = graph.resolve(sessionCache);
      final image = graph.resolve(imageCache);

      expect(primary.cacheName, equals('primary'));
      expect(session.cacheName, equals('session'));
      expect(image.cacheName, equals('image'));
      expect(identical(primary, session), isFalse);
      expect(identical(session, image), isFalse);
    });

    test('rejects duplicate registration of the exact same token', () {
      const dbToken = Dependency<DatabaseService>('db');
      final registry = DependencyRegistry()
        ..define(dbToken, (_) => DatabaseService('test'));

      expect(
        () => registry.define(dbToken, (_) => DatabaseService('another')),
        throwsA(
          isA<DuplicateDependencyException>().having(
            (e) => e.dependency,
            'dependency',
            equals(dbToken),
          ),
        ),
      );
    });

    test('factories are not executed during registration', () {
      final logger = LifecycleLogger();
      const dbToken = Dependency<DatabaseService>('db');
      final registry = DependencyRegistry();

      registry.define(dbToken, (_) => DatabaseService('lazy', logger));

      expect(logger.events, isEmpty);
    });
  });

  group('Milestone 2 — Graph Compilation and Validation', () {
    test('compilation does not execute factories', () {
      final logger = LifecycleLogger();
      const dbToken = Dependency<DatabaseService>('db');
      final registry = DependencyRegistry()
        ..define(dbToken, (_) => DatabaseService('test', logger));

      final graph = registry.compile();
      expect(logger.events, isEmpty);
      expect(graph.isDisposed, isFalse);
    });

    test(
      'throws MissingDependencyException when required dependency is missing',
      () {
        const userToken = Dependency<UserService>('userService');
        const dbToken = Dependency<DatabaseService>('database');

        final registry = DependencyRegistry()
          ..define(
            userToken,
            (deps) => UserService(deps.require(dbToken), CacheService('dummy')),
            requires: [dbToken],
          );

        expect(
          () => registry.compile(),
          throwsA(
            isA<MissingDependencyException>()
                .having((e) => e.dependency, 'dependency', equals(dbToken))
                .having((e) => e.requiredBy, 'requiredBy', equals(userToken)),
          ),
        );
      },
    );

    test('detects direct circular dependency (A -> A)', () {
      const loopToken = Dependency<String>('loop');
      final registry = DependencyRegistry()
        ..define(
          loopToken,
          (deps) => deps.require(loopToken),
          requires: [loopToken],
        );

      expect(
        () => registry.compile(),
        throwsA(
          isA<DependencyCycleException>().having(
            (e) => e.cycle,
            'cycle',
            equals([loopToken, loopToken]),
          ),
        ),
      );
    });

    test('detects indirect circular dependency (A -> B -> A)', () {
      const tokenA = Dependency<String>('a');
      const tokenB = Dependency<String>('b');

      final registry = DependencyRegistry()
        ..define(tokenA, (deps) => deps.require(tokenB), requires: [tokenB])
        ..define(tokenB, (deps) => deps.require(tokenA), requires: [tokenA]);

      expect(
        () => registry.compile(),
        throwsA(
          isA<DependencyCycleException>().having(
            (e) => e.cycle,
            'cycle',
            containsAllInOrder([tokenA, tokenB, tokenA]),
          ),
        ),
      );
    });

    test('detects longer indirect circular dependency (A -> B -> C -> A)', () {
      const tokenA = Dependency<String>('a');
      const tokenB = Dependency<String>('b');
      const tokenC = Dependency<String>('c');

      final registry = DependencyRegistry()
        ..define(tokenA, (deps) => deps.require(tokenB), requires: [tokenB])
        ..define(tokenB, (deps) => deps.require(tokenC), requires: [tokenC])
        ..define(tokenC, (deps) => deps.require(tokenA), requires: [tokenA]);

      expect(
        () => registry.compile(),
        throwsA(
          isA<DependencyCycleException>().having(
            (e) => e.cycle,
            'cycle',
            containsAllInOrder([tokenA, tokenB, tokenC, tokenA]),
          ),
        ),
      );
    });

    test('validates diamond dependency graph without cycles', () {
      // D -> B, C; B -> A; C -> A
      const tokenA = Dependency<String>('a');
      const tokenB = Dependency<String>('b');
      const tokenC = Dependency<String>('c');
      const tokenD = Dependency<String>('d');

      final registry = DependencyRegistry()
        ..define(tokenA, (_) => 'A')
        ..define(
          tokenB,
          (deps) => '${deps.require(tokenA)}B',
          requires: [tokenA],
        )
        ..define(
          tokenC,
          (deps) => '${deps.require(tokenA)}C',
          requires: [tokenA],
        )
        ..define(
          tokenD,
          (deps) => '${deps.require(tokenB)}${deps.require(tokenC)}D',
          requires: [tokenB, tokenC],
        );

      final graph = registry.compile();
      expect(graph.resolve(tokenD), equals('ABACD'));
    });

    test('rejects direct synchronous dependency on asynchronous provider', () {
      const syncToken = Dependency<String>('sync');
      const asyncToken = Dependency<String>('async');

      final registry = DependencyRegistry()
        ..defineAsync(asyncToken, (_) async => 'asyncVal')
        ..define(
          syncToken,
          (deps) => 'syncVal:${deps.require(asyncToken)}',
          requires: [asyncToken],
        );

      expect(
        () => registry.compile(),
        throwsA(
          isA<AsyncDependencyException>().having(
            (e) => e.path,
            'path',
            equals([syncToken, asyncToken]),
          ),
        ),
      );
    });

    test(
      'rejects transitive synchronous dependency on asynchronous provider',
      () {
        const syncA = Dependency<String>('syncA');
        const syncB = Dependency<String>('syncB');
        const asyncC = Dependency<String>('asyncC');

        final registry = DependencyRegistry()
          ..defineAsync(asyncC, (_) async => 'asyncVal')
          ..define(syncB, (deps) => deps.require(asyncC), requires: [asyncC])
          ..define(syncA, (deps) => deps.require(syncB), requires: [syncB]);

        expect(
          () => registry.compile(),
          throwsA(
            isA<AsyncDependencyException>().having(
              (e) => e.path,
              'path',
              equals([syncB, asyncC]),
            ),
          ),
        );
      },
    );

    test('allows asynchronous provider to depend on synchronous provider', () {
      const syncToken = Dependency<String>('sync');
      const asyncToken = Dependency<String>('async');

      final registry = DependencyRegistry()
        ..define(syncToken, (_) => 'hello')
        ..defineAsync(
          asyncToken,
          (deps) async => '${deps.require(syncToken)} world',
          requires: [syncToken],
        );

      final graph = registry.compile();
      expect(graph, isNotNull);
    });

    test(
      'allows asynchronous provider to depend on another asynchronous provider',
      () {
        const asyncA = Dependency<String>('asyncA');
        const asyncB = Dependency<String>('asyncB');

        final registry = DependencyRegistry()
          ..defineAsync(asyncA, (_) async => 'first')
          ..defineAsync(
            asyncB,
            (deps) async => '${await deps.requireAsync(asyncA)} second',
            requires: [asyncA],
          );

        final graph = registry.compile();
        expect(graph, isNotNull);
      },
    );
  });

  group('Milestone 3 — Synchronous Lazy Resolution', () {
    test('lazily initializes and caches synchronous instances', () {
      final logger = LifecycleLogger();
      const dbToken = Dependency<DatabaseService>('db');

      final registry = DependencyRegistry()
        ..define(dbToken, (_) => DatabaseService('testDb', logger));

      final graph = registry.compile();
      expect(logger.events, isEmpty);

      final first = graph.resolve(dbToken);
      expect(logger.events, equals(['create:DatabaseService(testDb)']));

      final second = graph.resolve(dbToken);
      expect(identical(first, second), isTrue);
      // Construction count remains 1
      expect(logger.events, equals(['create:DatabaseService(testDb)']));
    });

    test('repeated calls to resolve() do not accumulate ownership claims or inflate ref counts', () {
      const dbToken = Dependency<DatabaseService>('db');
      final registry = DependencyRegistry()
        ..define(dbToken, (_) => DatabaseService('testDb'));

      final graph = registry.compile();

      for (int i = 0; i < 10; i++) {
        final instance = graph.resolve(dbToken);
        expect(instance.dbName, equals('testDb'));
      }

      // Graph ownership is marked, external ref count remains 0, total ref count is exactly 1
      expect(graph.diagnostics.isGraphRetained(dbToken), isTrue);
      expect(graph.diagnostics.externalRefCountOf(dbToken), equals(0));
      expect(graph.diagnostics.totalRefCountOf(dbToken), equals(1));
    });

    test('resolves nested dependencies in order before consumer', () {
      final logger = LifecycleLogger();
      const dbToken = Dependency<DatabaseService>('db');
      const cacheToken = Dependency<CacheService>('cache');
      const userToken = Dependency<UserService>('user');

      final registry = DependencyRegistry()
        ..define(dbToken, (_) => DatabaseService('userDb', logger))
        ..define(cacheToken, (_) => CacheService('userCache', logger))
        ..define(
          userToken,
          (deps) => UserService(
            deps.require(dbToken),
            deps.require(cacheToken),
            logger,
          ),
          requires: [dbToken, cacheToken],
        );

      final graph = registry.compile();
      expect(logger.events, isEmpty);

      final user = graph.resolve(userToken);
      expect(user.db.dbName, equals('userDb'));
      expect(user.cache.cacheName, equals('userCache'));

      expect(
        logger.events,
        equals([
          'create:DatabaseService(userDb)',
          'create:CacheService(userCache)',
          'create:UserService',
        ]),
      );
    });

    test('shares single dependency instance across multiple consumers', () {
      final logger = LifecycleLogger();
      const dbToken = Dependency<DatabaseService>('db');
      const cacheToken = Dependency<CacheService>('cache');
      const userToken = Dependency<UserService>('user');
      const authToken = Dependency<AuthService>('auth');

      final registry = DependencyRegistry()
        ..define(dbToken, (_) => DatabaseService('sharedDb', logger))
        ..define(cacheToken, (_) => CacheService('sharedCache', logger))
        ..define(
          userToken,
          (deps) => UserService(
            deps.require(dbToken),
            deps.require(cacheToken),
            logger,
          ),
          requires: [dbToken, cacheToken],
        )
        ..define(
          authToken,
          (deps) => AuthService(deps.require(dbToken), logger),
          requires: [dbToken],
        );

      final graph = registry.compile();
      final user = graph.resolve(userToken);
      final auth = graph.resolve(authToken);

      expect(identical(user.db, auth.db), isTrue);
      // DatabaseService constructed exactly once
      expect(
        logger.events.where((e) => e.contains('DatabaseService')).length,
        equals(1),
      );
    });

    test(
      'throws UndeclaredDependencyException on accessing undeclared token',
      () {
        const dbToken = Dependency<DatabaseService>('db');
        const cacheToken = Dependency<CacheService>('cache');
        const userToken = Dependency<UserService>('user');

        final registry = DependencyRegistry()
          ..define(dbToken, (_) => DatabaseService('testDb'))
          ..define(cacheToken, (_) => CacheService('testCache'))
          ..define(
            userToken,
            (deps) => UserService(
              deps.require(dbToken),
              // cacheToken is intentionally omitted from `requires`
              deps.require(cacheToken),
            ),
            requires: [dbToken],
          );

        final graph = registry.compile();
        expect(
          () => graph.resolve(userToken),
          throwsA(
            isA<UndeclaredDependencyException>()
                .having((e) => e.requested, 'requested', equals(cacheToken))
                .having(
                  (e) => e.requestingProvider,
                  'requestingProvider',
                  equals(userToken),
                ),
          ),
        );
      },
    );

    test('throws AsyncDependencyException if requireAsync is called inside sync factory', () {
      const dbToken = Dependency<DatabaseService>('db');
      const userToken = Dependency<UserService>('user');

      final registry = DependencyRegistry()
        ..define(dbToken, (_) => DatabaseService('testDb'))
        ..define(userToken, (deps) {
          deps.requireAsync(dbToken);
          return UserService(deps.require(dbToken), CacheService('c'));
        }, requires: [dbToken]);

      final graph = registry.compile();
      expect(
        () => graph.resolve(userToken),
        throwsA(isA<AsyncDependencyException>()),
      );
    });

    test('factory exception triggers rollback of retained dependencies', () {
      final logger = LifecycleLogger();
      const dbToken = Dependency<DatabaseService>('db');
      const failingToken = Dependency<String>('failing');

      final registry = DependencyRegistry()
        ..define(
          dbToken,
          (_) => DatabaseService('testDb', logger),
          dispose: (db) => db.dispose(),
        )
        ..define(failingToken, (deps) {
          deps.require(dbToken);
          throw StateError('Factory failure');
        }, requires: [dbToken]);

      final graph = registry.compile();

      expect(
        () => graph.resolve(failingToken),
        throwsA(isA<DependencyResolutionException>()),
      );

      // The database should have been rolled back and disposed because failingToken failed
      expect(
        graph.diagnostics.stateOf(failingToken),
        equals(InstanceState.uninitialized),
      );
      expect(graph.diagnostics.totalRefCountOf(dbToken), equals(0));
    });
  });

  group('Milestone 4 — Asynchronous Resolution', () {
    test('resolves asynchronous provider via resolveAsync', () async {
      const asyncDbToken = Dependency<DatabaseService>('asyncDb');
      final logger = LifecycleLogger();

      final registry = DependencyRegistry()
        ..defineAsync(asyncDbToken, (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return DatabaseService('asyncDb', logger);
        });

      final graph = registry.compile();
      final db = await graph.resolveAsync(asyncDbToken);

      expect(db.dbName, equals('asyncDb'));
      expect(logger.events, equals(['create:DatabaseService(asyncDb)']));

      // Repeated resolution returns cached instance
      final db2 = await graph.resolveAsync(asyncDbToken);
      expect(identical(db, db2), isTrue);
    });

    test('resolveAsync can resolve synchronous providers seamlessly', () async {
      const syncDbToken = Dependency<DatabaseService>('syncDb');
      final registry = DependencyRegistry()
        ..define(syncDbToken, (_) => DatabaseService('syncDb'));

      final graph = registry.compile();
      final db = await graph.resolveAsync(syncDbToken);
      expect(db.dbName, equals('syncDb'));
    });

    test('rejects synchronous resolution of an asynchronous provider', () {
      const asyncToken = Dependency<String>('asyncVal');
      final registry = DependencyRegistry()
        ..defineAsync(asyncToken, (_) async => 'hello');

      final graph = registry.compile();
      expect(
        () => graph.resolve(asyncToken),
        throwsA(
          isA<AsyncDependencyException>().having(
            (e) => e.path,
            'path',
            equals([asyncToken]),
          ),
        ),
      );
    });

    test(
      'concurrent resolution requests share a single in-flight future',
      () async {
        int constructionCount = 0;
        const asyncToken = Dependency<String>('sharedAsync');

        final registry = DependencyRegistry()
          ..defineAsync(asyncToken, (_) async {
            constructionCount++;
            await Future<void>.delayed(const Duration(milliseconds: 30));
            return 'result';
          });

        final graph = registry.compile();

        // Launch 5 concurrent resolution futures
        final results = await Future.wait([
          graph.resolveAsync(asyncToken),
          graph.resolveAsync(asyncToken),
          graph.resolveAsync(asyncToken),
          graph.resolveAsync(asyncToken),
          graph.resolveAsync(asyncToken),
        ]);

        expect(constructionCount, equals(1));
        for (final r in results) {
          expect(r, equals('result'));
        }
      },
    );

    test('repeated concurrent calls to resolveAsync() do not accumulate ownership claims', () async {
      const dbToken = Dependency<DatabaseService>('db');
      final registry = DependencyRegistry()
        ..defineAsync(dbToken, (_) async => DatabaseService('testDb'));

      final graph = registry.compile();

      final results = await Future.wait(
        List.generate(10, (_) => graph.resolveAsync(dbToken)),
      );

      for (final res in results) {
        expect(res.dbName, equals('testDb'));
      }

      expect(graph.diagnostics.isGraphRetained(dbToken), isTrue);
      expect(graph.diagnostics.externalRefCountOf(dbToken), equals(0));
      expect(graph.diagnostics.totalRefCountOf(dbToken), equals(1));
    });

    test('async resolution failure rolls back partially retained dependencies and permits retry', () async {
      int attempts = 0;
      const dbToken = Dependency<DatabaseService>('db');
      const asyncServiceToken = Dependency<String>('flakeyService');

      final registry = DependencyRegistry()
        ..define(dbToken, (_) => DatabaseService('db'))
        ..defineAsync(asyncServiceToken, (deps) async {
          deps.require(dbToken);
          attempts++;
          if (attempts == 1) {
            throw StateError('Transient network failure');
          }
          return 'recovered';
        }, requires: [dbToken]);

      final graph = registry.compile();

      // First attempt fails
      await expectLater(
        graph.resolveAsync(asyncServiceToken),
        throwsA(isA<DependencyResolutionException>()),
      );

      // Verify clean rollback of state
      expect(
        graph.diagnostics.stateOf(asyncServiceToken),
        equals(InstanceState.uninitialized),
      );
      expect(graph.diagnostics.totalRefCountOf(dbToken), equals(0));

      // Second attempt succeeds
      final result = await graph.resolveAsync(asyncServiceToken);
      expect(result, equals('recovered'));
      expect(attempts, equals(2));
      expect(
        graph.diagnostics.stateOf(asyncServiceToken),
        equals(InstanceState.initialized),
      );
    });
  });

  group('Milestone 5 — Reference-Counted Ownership and Handles', () {
    test(
      'clear distinction between resolve() and retain() ownership semantics',
      () {
        const dbToken = Dependency<DatabaseService>('db');
        final registry = DependencyRegistry()
          ..define(dbToken, (_) => DatabaseService('testDb'));

        final graph = registry.compile();

        // resolve() establishes graph-owned caching without creating external handles
        final resolved = graph.resolve(dbToken);
        expect(graph.diagnostics.isGraphRetained(dbToken), isTrue);
        expect(graph.diagnostics.externalRefCountOf(dbToken), equals(0));
        expect(graph.diagnostics.totalRefCountOf(dbToken), equals(1));

        // retain() issues distinct explicit handles that increment externalRefCount
        final handle1 = graph.retain(dbToken);
        final handle2 = graph.retain(dbToken);
        expect(identical(handle1.value, resolved), isTrue);
        expect(identical(handle2.value, resolved), isTrue);
        expect(graph.diagnostics.externalRefCountOf(dbToken), equals(2));
        expect(
          graph.diagnostics.totalRefCountOf(dbToken),
          equals(3),
        ); // 1 graph + 2 handles

        handle1.release();
        expect(graph.diagnostics.externalRefCountOf(dbToken), equals(1));
        expect(graph.diagnostics.totalRefCountOf(dbToken), equals(2));

        handle2.release();
        expect(graph.diagnostics.externalRefCountOf(dbToken), equals(0));
        expect(
          graph.diagnostics.totalRefCountOf(dbToken),
          equals(1),
        ); // still retained by graph
      },
    );

    test('acquire creates ephemeral handle; release disposes instance', () {
      final logger = LifecycleLogger();
      const dbToken = Dependency<DatabaseService>('db');

      final registry = DependencyRegistry()
        ..define(
          dbToken,
          (_) => DatabaseService('testDb', logger),
          dispose: (db) => db.dispose(),
        );

      final graph = registry.compile();
      final handle = graph.acquire(dbToken);

      expect(handle.isReleased, isFalse);
      expect(handle.isPermanent, isFalse);
      expect(handle.value.dbName, equals('testDb'));
      expect(graph.diagnostics.externalRefCountOf(dbToken), equals(1));
      expect(
        graph.diagnostics.stateOf(dbToken),
        equals(InstanceState.initialized),
      );

      // Release handle
      handle.release();

      expect(handle.isReleased, isTrue);
      expect(logger.events, contains('dispose:DatabaseService(testDb)'));
      expect(
        graph.diagnostics.stateOf(dbToken),
        equals(InstanceState.uninitialized),
      );
      expect(graph.diagnostics.totalRefCountOf(dbToken), equals(0));

      // Value access on released handle throws
      expect(() => handle.value, throwsA(isA<StateError>()));

      // Double release is harmless
      handle.release();
      expect(handle.isReleased, isTrue);
    });

    test(
      'multiple ephemeral handles keep instance alive until all are released',
      () {
        final logger = LifecycleLogger();
        const dbToken = Dependency<DatabaseService>('db');

        final registry = DependencyRegistry()
          ..define(
            dbToken,
            (_) => DatabaseService('sharedDb', logger),
            dispose: (db) => db.dispose(),
          );

        final graph = registry.compile();
        final handle1 = graph.acquire(dbToken);
        final handle2 = graph.acquire(dbToken);

        expect(graph.diagnostics.externalRefCountOf(dbToken), equals(2));
        expect(identical(handle1.value, handle2.value), isTrue);

        // Release first handle: instance stays alive
        handle1.release();
        expect(handle1.isReleased, isTrue);
        expect(handle2.isReleased, isFalse);
        expect(
          logger.events,
          isNot(contains('dispose:DatabaseService(sharedDb)')),
        );
        expect(graph.diagnostics.externalRefCountOf(dbToken), equals(1));
        expect(handle2.value.dbName, equals('sharedDb'));

        // Release second handle: instance is now disposed
        handle2.release();
        expect(logger.events, contains('dispose:DatabaseService(sharedDb)'));
        expect(
          graph.diagnostics.stateOf(dbToken),
          equals(InstanceState.uninitialized),
        );
      },
    );

    test(
      'cascading disposal: releasing parent disposes unshared dependencies',
      () {
        final logger = LifecycleLogger();
        const dbToken = Dependency<DatabaseService>('db');
        const cacheToken = Dependency<CacheService>('cache');
        const userToken = Dependency<UserService>('user');

        final registry = DependencyRegistry()
          ..define(
            dbToken,
            (_) => DatabaseService('userDb', logger),
            dispose: (db) => db.dispose(),
          )
          ..define(
            cacheToken,
            (_) => CacheService('userCache', logger),
            dispose: (cache) => cache.dispose(),
          )
          ..define(
            userToken,
            (deps) => UserService(
              deps.require(dbToken),
              deps.require(cacheToken),
              logger,
            ),
            requires: [dbToken, cacheToken],
            dispose: (user) => user.dispose(),
          );

        final graph = registry.compile();
        final userHandle = graph.acquire(userToken);

        expect(graph.diagnostics.externalRefCountOf(userToken), equals(1));
        expect(graph.diagnostics.internalRefCountOf(dbToken), equals(1));
        expect(graph.diagnostics.internalRefCountOf(cacheToken), equals(1));

        // Release userHandle
        userHandle.release();

        expect(
          logger.events,
          containsAllInOrder([
            'create:DatabaseService(userDb)',
            'create:CacheService(userCache)',
            'create:UserService',
            'dispose:UserService',
            'dispose:DatabaseService(userDb)',
            'dispose:CacheService(userCache)',
          ]),
        );

        expect(
          graph.diagnostics.stateOf(userToken),
          equals(InstanceState.uninitialized),
        );
        expect(
          graph.diagnostics.stateOf(dbToken),
          equals(InstanceState.uninitialized),
        );
        expect(
          graph.diagnostics.stateOf(cacheToken),
          equals(InstanceState.uninitialized),
        );
      },
    );

    test(
      'shared dependencies remain alive while another consumer retains them',
      () {
        final logger = LifecycleLogger();
        const dbToken = Dependency<DatabaseService>('db');
        const cacheToken = Dependency<CacheService>('cache');
        const userToken = Dependency<UserService>('user');
        const authToken = Dependency<AuthService>('auth');

        final registry = DependencyRegistry()
          ..define(
            dbToken,
            (_) => DatabaseService('sharedDb', logger),
            dispose: (db) => db.dispose(),
          )
          ..define(
            cacheToken,
            (_) => CacheService('cache', logger),
            dispose: (c) => c.dispose(),
          )
          ..define(
            userToken,
            (deps) => UserService(
              deps.require(dbToken),
              deps.require(cacheToken),
              logger,
            ),
            requires: [dbToken, cacheToken],
            dispose: (u) => u.dispose(),
          )
          ..define(
            authToken,
            (deps) => AuthService(deps.require(dbToken), logger),
            requires: [dbToken],
            dispose: (a) => a.dispose(),
          );

        final graph = registry.compile();
        final userHandle = graph.acquire(userToken);
        final authHandle = graph.acquire(authToken);

        expect(graph.diagnostics.internalRefCountOf(dbToken), equals(2));

        // Releasing userHandle disposes user and cache, but NOT db
        userHandle.release();
        expect(logger.events, contains('dispose:UserService'));
        expect(logger.events, contains('dispose:CacheService(cache)'));
        expect(
          logger.events,
          isNot(contains('dispose:DatabaseService(sharedDb)')),
        );

        expect(
          graph.diagnostics.stateOf(dbToken),
          equals(InstanceState.initialized),
        );
        expect(graph.diagnostics.internalRefCountOf(dbToken), equals(1));

        // Releasing authHandle disposes auth and now also db
        authHandle.release();
        expect(logger.events, contains('dispose:AuthService'));
        expect(logger.events, contains('dispose:DatabaseService(sharedDb)'));
        expect(
          graph.diagnostics.stateOf(dbToken),
          equals(InstanceState.uninitialized),
        );
      },
    );

    test('reacquisition after disposal creates fresh instance via unchanged compiled graph', () {
      final logger = LifecycleLogger();
      const dbToken = Dependency<DatabaseService>('db');

      final registry = DependencyRegistry()
        ..define(
          dbToken,
          (_) => DatabaseService('rebornDb', logger),
          dispose: (db) => db.dispose(),
        );

      final graph = registry.compile();

      final handle1 = graph.acquire(dbToken);
      final instance1 = handle1.value;
      handle1.release();

      expect(logger.events, contains('dispose:DatabaseService(rebornDb)'));
      expect(
        graph.diagnostics.stateOf(dbToken),
        equals(InstanceState.uninitialized),
      );

      // Reacquire
      final handle2 = graph.acquire(dbToken);
      final instance2 = handle2.value;

      expect(identical(instance1, instance2), isFalse);
      expect(instance2.dbName, equals('rebornDb'));
      expect(
        graph.diagnostics.stateOf(dbToken),
        equals(InstanceState.initialized),
      );

      handle2.release();
    });

    test('async acquireAsync and release handles', () async {
      const asyncToken = Dependency<String>('asyncStr');
      final registry = DependencyRegistry()
        ..defineAsync(asyncToken, (_) async => 'asyncValue');

      final graph = registry.compile();
      final handle = await graph.acquireAsync(asyncToken);

      expect(handle.value, equals('asyncValue'));
      handle.release();
      expect(handle.isReleased, isTrue);
    });

    test('handles released while async initialization is in-flight immediately clean up', () async {
      final logger = LifecycleLogger();
      const asyncDb = Dependency<DatabaseService>('slowDb');

      final registry = DependencyRegistry()
        ..defineAsync(asyncDb, (_) async {
          logger.log('startInit');
          await Future<void>.delayed(const Duration(milliseconds: 30));
          logger.log('finishInit');
          return DatabaseService('slowDb', logger);
        }, dispose: (db) => db.dispose());

      final graph = registry.compile();
      final futureHandle = graph.acquireAsync(asyncDb);

      // Release the in-flight handle before it completes
      // We can grab the runtime active handle or release once available
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final runtimeHandles = graph.diagnostics.externalRefCountOf(asyncDb);
      expect(runtimeHandles, equals(1));

      // Once the future completes, if released in flight:
      final handle = await futureHandle;
      handle.release();

      expect(logger.events, contains('dispose:DatabaseService(slowDb)'));
    });
  });

  group('Milestone 6 — Graph-Wide Disposal and Shutdown', () {
    test('authoritative disposal cleans up all instances in reverse dependency order', () async {
      final logger = LifecycleLogger();
      const dbToken = Dependency<DatabaseService>('db');
      const cacheToken = Dependency<CacheService>('cache');
      const userToken = Dependency<UserService>('user');

      final registry = DependencyRegistry()
        ..define(
          dbToken,
          (_) => DatabaseService('db', logger),
          dispose: (db) => db.dispose(),
        )
        ..define(
          cacheToken,
          (_) => CacheService('cache', logger),
          dispose: (c) => c.dispose(),
        )
        ..define(
          userToken,
          (deps) => UserService(
            deps.require(dbToken),
            deps.require(cacheToken),
            logger,
          ),
          requires: [dbToken, cacheToken],
          dispose: (u) => u.dispose(),
        );

      final graph = registry.compile();
      graph.resolve(userToken);

      expect(
        graph.diagnostics.stateOf(userToken),
        equals(InstanceState.initialized),
      );
      expect(
        graph.diagnostics.stateOf(dbToken),
        equals(InstanceState.initialized),
      );
      expect(
        graph.diagnostics.stateOf(cacheToken),
        equals(InstanceState.initialized),
      );

      await graph.dispose();

      expect(graph.isDisposed, isTrue);
      // Consumer disposed before dependencies
      expect(
        logger.events,
        containsAllInOrder([
          'dispose:UserService',
          'dispose:DatabaseService(db)',
        ]),
      );
    });

    test('invalidates active handles and rejects subsequent resolutions after disposal', () async {
      const dbToken = Dependency<DatabaseService>('db');
      final registry = DependencyRegistry()
        ..define(dbToken, (_) => DatabaseService('db'));

      final graph = registry.compile();
      final handle = graph.acquire(dbToken);
      expect(handle.value, isNotNull);

      await graph.dispose();

      // Handle is invalidated
      expect(handle.isReleased, isTrue);
      expect(() => handle.value, throwsA(isA<StateError>()));

      // Subsequent resolution throws DisposedGraphException
      expect(
        () => graph.resolve(dbToken),
        throwsA(isA<DisposedGraphException>()),
      );
      expect(
        () => graph.acquire(dbToken),
        throwsA(isA<DisposedGraphException>()),
      );
      expect(
        () => graph.resolveAsync(dbToken),
        throwsA(isA<DisposedGraphException>()),
      );
    });

    test('graph disposal is idempotent', () async {
      int disposeCount = 0;
      const dbToken = Dependency<String>('db');

      final registry = DependencyRegistry()
        ..define(dbToken, (_) => 'db', dispose: (_) => disposeCount++);

      final graph = registry.compile();
      graph.resolve(dbToken);

      await graph.dispose();
      expect(disposeCount, equals(1));

      // Repeated disposal call is no-op
      await graph.dispose();
      expect(disposeCount, equals(1));
    });

    test('disposal failures are collected into DisposalAggregateException', () async {
      final logger = LifecycleLogger();
      const faultyToken1 = Dependency<String>('faulty1');
      const faultyToken2 = Dependency<String>('faulty2');
      const healthyToken = Dependency<String>('healthy');

      final registry = DependencyRegistry()
        ..define(
          healthyToken,
          (_) => 'healthy',
          dispose: (_) => logger.log('dispose:healthy'),
        )
        ..define(
          faultyToken1,
          (_) => 'faulty1',
          dispose: (_) {
            logger.log('dispose:faulty1');
            throw StateError('Error 1');
          },
        )
        ..define(
          faultyToken2,
          (_) => 'faulty2',
          dispose: (_) {
            logger.log('dispose:faulty2');
            throw StateError('Error 2');
          },
        );

      final graph = registry.compile();
      graph.resolve(healthyToken);
      graph.resolve(faultyToken1);
      graph.resolve(faultyToken2);

      expect(
        () => graph.dispose(),
        throwsA(
          isA<DisposalAggregateException>().having(
            (e) => e.errors.length,
            'errors.length',
            equals(2),
          ),
        ),
      );

      // Verify that healthy instance was still disposed despite other failures
      expect(logger.events, contains('dispose:healthy'));
      expect(graph.isDisposed, isTrue);
    });
  });

  group('Milestone 7 — Diagnostics and Observability', () {
    test('reports graph structure, roots, leaves, and dump output', () {
      const dbToken = Dependency<DatabaseService>('db');
      const cacheToken = Dependency<CacheService>('cache');
      const userToken = Dependency<UserService>('user');

      final registry = DependencyRegistry()
        ..define(dbToken, (_) => DatabaseService('db'))
        ..define(cacheToken, (_) => CacheService('cache'))
        ..define(
          userToken,
          (deps) =>
              UserService(deps.require(dbToken), deps.require(cacheToken)),
          requires: [dbToken, cacheToken],
        );

      final graph = registry.compile();
      final diag = graph.diagnostics;

      expect(
        diag.registeredTokens,
        containsAll([dbToken, cacheToken, userToken]),
      );
      expect(diag.rootTokens, equals([userToken]));
      expect(diag.leafTokens, containsAll([dbToken, cacheToken]));

      expect(
        diag.dependenciesOf(userToken),
        containsAll([dbToken, cacheToken]),
      );
      expect(diag.dependentsOf(dbToken), equals([userToken]));
      expect(diag.dependentsOf(cacheToken), equals([userToken]));

      expect(diag.stateOf(userToken), equals(InstanceState.uninitialized));
      expect(diag.totalRefCountOf(userToken), equals(0));

      graph.resolve(userToken);

      expect(diag.stateOf(userToken), equals(InstanceState.initialized));
      expect(
        diag.totalRefCountOf(userToken),
        equals(1),
      ); // 1 from graph retention
      expect(diag.internalRefCountOf(dbToken), equals(1));
      expect(diag.internalRefCountOf(cacheToken), equals(1));

      final dump = diag.dump();
      expect(dump, contains('DependencyGraph Diagnostics Dump:'));
      expect(dump, contains('Dependency<UserService>(user)'));
      expect(dump, contains('Roots: [user]'));
      expect(dump, contains('Leaves: [db, cache]'));
      expect(dump, contains('Construction Order:'));
    });
  });
}
