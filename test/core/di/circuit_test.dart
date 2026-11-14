import 'dart:async';

import 'package:arca/core/di/di.dart';
import 'package:flutter_test/flutter_test.dart';

enum Environment { dev, staging, prod }

enum Role { user, admin }

final class DatabaseService {
  final String path;
  final void Function(String event)? onLog;

  DatabaseService(this.path, [this.onLog]);

  void dispose() {
    onLog?.call('dispose:DatabaseService($path)');
  }
}

final class CacheService {
  final String name;
  final void Function(String event)? onLog;

  CacheService(this.name, [this.onLog]);

  void dispose() {
    onLog?.call('dispose:CacheService($name)');
  }
}

final class UserService {
  final DatabaseService db;
  final void Function(String event)? onLog;

  UserService(this.db, [this.onLog]);

  void dispose() {
    onLog?.call('dispose:UserService');
  }
}

final class OrderService {
  final UserService user;
  final CacheService cache;
  final void Function(String event)? onLog;

  OrderService(this.user, this.cache, [this.onLog]);

  void dispose() {
    onLog?.call('dispose:OrderService');
  }
}

final class ConfigService {
  final String env;
  final void Function(String event)? onLog;

  ConfigService(this.env, [this.onLog]);

  void dispose() {
    onLog?.call('dispose:ConfigService');
  }
}

final class LoggerService {
  final void Function(String event)? onLog;

  LoggerService([this.onLog]);

  void dispose() {
    onLog?.call('dispose:LoggerService');
  }
}

final class SessionService {
  final CacheService cache;
  final void Function(String event)? onLog;

  SessionService(this.cache, [this.onLog]);

  void dispose() {
    onLog?.call('dispose:SessionService');
  }
}

final class AnalyticsService {
  final UserService user;
  final SessionService session;
  final void Function(String event)? onLog;

  AnalyticsService(this.user, this.session, [this.onLog]);

  void dispose() {
    onLog?.call('dispose:AnalyticsService');
  }
}

final class AppCoordinator {
  final AnalyticsService analytics;
  final OrderService order;
  final void Function(String event)? onLog;

  AppCoordinator(this.analytics, this.order, [this.onLog]);

  void dispose() {
    onLog?.call('dispose:AppCoordinator');
  }
}

void main() {
  group('Circuit DAG Validation', () {
    test(
      'throws DuplicateWireException when registering duplicate untagged wires',
      () async {
        expect(
          () => Circuit.build([
            Wire(() => DatabaseService('db1')),
            Wire(() => DatabaseService('db2')),
          ]),
          throwsA(
            isA<DuplicateWireException>().having(
              (e) => e.key,
              'key',
              equals((DatabaseService, null)),
            ),
          ),
        );
      },
    );

    test(
      'throws DuplicateWireException when registering duplicate tagged wires',
      () async {
        expect(
          () => Circuit.build([
            Wire.tag(() => DatabaseService('prod1'), tag: Environment.prod),
            Wire.tag(() => DatabaseService('prod2'), tag: Environment.prod),
          ]),
          throwsA(
            isA<DuplicateWireException>().having(
              (e) => e.key,
              'key',
              equals((DatabaseService, Environment.prod)),
            ),
          ),
        );
      },
    );

    test(
      'allows untagged wire and tagged wire of same underlying type',
      () async {
        final circuit = await Circuit.build([
          Wire(() => DatabaseService('default.db')),
          Wire.tag(() => DatabaseService('prod.db'), tag: Environment.prod),
        ]);

        final defaultDb = circuit.get<DatabaseService>();
        final prodDb = circuit.getTagged<DatabaseService, Environment>(
          Environment.prod,
        );

        expect(defaultDb.path, equals('default.db'));
        expect(prodDb.path, equals('prod.db'));
        expect(identical(defaultDb, prodDb), isFalse);
      },
    );

    test('allows multiple distinct tags for same underlying type', () async {
      final circuit = await Circuit.build([
        Wire.tag(() => DatabaseService('dev.db'), tag: Environment.dev),
        Wire.tag(() => DatabaseService('prod.db'), tag: Environment.prod),
      ]);

      final devDb = circuit.getTagged<DatabaseService, Environment>(
        Environment.dev,
      );
      final prodDb = circuit.getTagged<DatabaseService, Environment>(
        Environment.prod,
      );

      expect(devDb.path, equals('dev.db'));
      expect(prodDb.path, equals('prod.db'));
    });

    test('throws MissingWireException when dependency is missing', () async {
      expect(
        () =>
            Circuit.build([Wire.takes<DatabaseService>().to(UserService.new)]),
        throwsA(
          isA<MissingWireException>()
              .having(
                (e) => e.missingKey,
                'missingKey',
                equals((DatabaseService, null)),
              )
              .having(
                (e) => e.requiredBy,
                'requiredBy',
                equals((UserService, null)),
              ),
        ),
      );
    });

    test(
      'throws CircularDependencyException for direct 2-node cycle',
      () async {
        expect(
          () => Circuit.build([
            Wire.takes<CacheService>().to((cache) => DatabaseService('cyclic')),
            Wire.takes<DatabaseService>().to((db) => CacheService('cyclic')),
          ]),
          throwsA(
            isA<CircularDependencyException>().having(
              (e) => e.cycle,
              'cycle',
              containsAllInOrder([
                (DatabaseService, null),
                (CacheService, null),
                (DatabaseService, null),
              ]),
            ),
          ),
        );
      },
    );

    test('throws CircularDependencyException for 3-node cycle', () async {
      expect(
        () => Circuit.build([
          Wire.takes<CacheService>().to((cache) => DatabaseService('a')),
          Wire.takes<DatabaseService>().to((db) => UserService(db)),
          Wire.takes<UserService>().to((user) => CacheService('c')),
        ]),
        throwsA(
          isA<CircularDependencyException>().having(
            (e) => e.cycle,
            'cycle',
            isNotEmpty,
          ),
        ),
      );
    });

    test('throws CircularDependencyException for self-cycle', () async {
      expect(
        () => Circuit.build([
          Wire.takes<DatabaseService>().to((db) => DatabaseService('self')),
        ]),
        throwsA(
          isA<CircularDependencyException>().having(
            (e) => e.cycle,
            'cycle',
            equals([(DatabaseService, null), (DatabaseService, null)]),
          ),
        ),
      );
    });
  });

  group('Parallel Topological Wave Execution', () {
    test('resolves independent AsyncWires in parallel in Wave 0', () async {
      final completer1 = Completer<void>();
      final completer2 = Completer<void>();
      var wire1Started = false;
      var wire2Started = false;

      final circuitFuture = Circuit.build([
        AsyncWire(() async {
          wire1Started = true;
          await completer1.future;
          return DatabaseService('async1.db');
        }),
        AsyncWire(() async {
          wire2Started = true;
          await completer2.future;
          return CacheService('asyncCache');
        }),
      ]);

      // Yield event loop so both async factories start execution
      await Future<void>.delayed(Duration.zero);

      // Both must have started execution concurrently in parallel wave 0
      expect(wire1Started, isTrue);
      expect(wire2Started, isTrue);

      completer1.complete();
      completer2.complete();

      final circuit = await circuitFuture;
      expect(circuit.get<DatabaseService>().path, equals('async1.db'));
      expect(circuit.get<CacheService>().name, equals('asyncCache'));
    });

    test(
      'resolves multi-wave async dependencies in topological order',
      () async {
        final log = <String>[];

        final circuit = await Circuit.build([
          AsyncWire(() async {
            log.add('wave0:DatabaseService');
            return DatabaseService('db');
          }),
          AsyncWire.takes<DatabaseService>().to((db) async {
            log.add('wave1:UserService');
            return UserService(db);
          }),
        ]);

        expect(log, equals(['wave0:DatabaseService', 'wave1:UserService']));
        expect(circuit.get<UserService>().db.path, equals('db'));
      },
    );

    test(
      'AsyncWire lazily evaluates required sync Wire during build',
      () async {
        var syncCreated = false;

        final circuit = await Circuit.build([
          Wire(() {
            syncCreated = true;
            return DatabaseService('lazy-sync.db');
          }),
          AsyncWire.takes<DatabaseService>().to((db) async {
            return UserService(db);
          }),
        ]);

        expect(syncCreated, isTrue);
        expect(circuit.get<UserService>().db.path, equals('lazy-sync.db'));
      },
    );

    test('diamond graph with mixed async and sync wires', () async {
      final circuit = await Circuit.build([
        AsyncWire(() async => DatabaseService('diamond.db')),
        Wire.takes<DatabaseService>().to((db) => UserService(db)),
        AsyncWire.takes<DatabaseService>().to(
          (db) async => CacheService(db.path),
        ),
        AsyncWire.takes<UserService>().takes<CacheService>().to(
          (deps) async => OrderService(deps.$1, deps.$2),
        ),
      ]);

      final order = circuit.get<OrderService>();
      expect(order.user.db.path, equals('diamond.db'));
      expect(order.cache.name, equals('diamond.db'));
    });

    test('cleans up previously initialized instances if an AsyncWire fails during build', () async {
      var dbDisposed = false;
      var syncDisposed = false;

      await expectLater(
        Circuit.build([
          Wire(
            () => ConfigService('prod'),
            onDispose: (_) => syncDisposed = true,
          ),
          AsyncWire.takes<ConfigService>().to(
            (cfg) async => DatabaseService('${cfg.env}.db'),
            onDispose: (_) => dbDisposed = true,
          ),
          AsyncWire.takes<DatabaseService>().to((db) async {
            throw StateError('Initialization failure in wave 2');
          }),
        ]),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('wave 2'),
          ),
        ),
      );

      // Verify that wave 0 sync wire and wave 1 async wire were cleanly disposed
      expect(dbDisposed, isTrue);
      expect(syncDisposed, isTrue);
    });

    test('6-level deep diamond DAG with mixed async and sync wires', () async {
      final log = <String>[];

      // Level 0: ConfigService (sync), LoggerService (async)
      // Level 1: DatabaseService (async, depends on LoggerService)
      // Level 2: CacheService (sync, depends on DatabaseService), UserService (async, depends on DatabaseService)
      // Level 3: SessionService (async, depends on CacheService), OrderService (sync, depends on UserService & CacheService)
      // Level 4: AnalyticsService (async, depends on UserService & SessionService)
      // Level 5: AppCoordinator (sync, depends on AnalyticsService & OrderService)
      final circuit = await Circuit.build([
        Wire(
          () => ConfigService('deep-env', log.add),
          onDispose: (inst) => inst.dispose(),
        ),
        AsyncWire(
          () async => LoggerService(log.add),
          onDispose: (inst) => inst.dispose(),
        ),
        AsyncWire.takes<LoggerService>().to(
          (logger) async => DatabaseService('deep.db', log.add),
          onDispose: (inst) => inst.dispose(),
        ),
        Wire.takes<DatabaseService>().to(
          (db) => CacheService('deepCache', log.add),
          onDispose: (inst) => inst.dispose(),
        ),
        AsyncWire.takes<DatabaseService>().to(
          (db) async => UserService(db, log.add),
          onDispose: (inst) => inst.dispose(),
        ),
        AsyncWire.takes<CacheService>().to(
          (cache) async => SessionService(cache, log.add),
          onDispose: (inst) => inst.dispose(),
        ),
        Wire.takes<UserService>().takes<CacheService>().to(
          (deps) => OrderService(deps.$1, deps.$2, log.add),
          onDispose: (inst) => inst.dispose(),
        ),
        AsyncWire.takes<UserService>().takes<SessionService>().to(
          (deps) async => AnalyticsService(deps.$1, deps.$2, log.add),
          onDispose: (inst) => inst.dispose(),
        ),
        Wire.takes<AnalyticsService>().takes<OrderService>().to(
          (deps) => AppCoordinator(deps.$1, deps.$2, log.add),
          onDispose: (inst) => inst.dispose(),
        ),
      ]);

      // Prior to reading AppCoordinator, only async wires and their sync dependencies are instantiated
      expect(circuit.isInitialized<AppCoordinator>(), isFalse);
      expect(circuit.isInitialized<AnalyticsService>(), isTrue);
      expect(circuit.isInitialized<SessionService>(), isTrue);
      expect(circuit.isInitialized<CacheService>(), isTrue);
      expect(circuit.isInitialized<UserService>(), isTrue);
      expect(circuit.isInitialized<DatabaseService>(), isTrue);
      expect(circuit.isInitialized<LoggerService>(), isTrue);
      expect(circuit.isInitialized<ConfigService>(), isFalse);

      final coordinator = circuit.get<AppCoordinator>();
      expect(coordinator.analytics.user.db.path, equals('deep.db'));
      expect(coordinator.order.cache.name, equals('deepCache'));
      expect(circuit.isInitialized<AppCoordinator>(), isTrue);

      await circuit.dispose();

      // Verify reverse topological wave disposal: Level 5 -> Level 4 -> Level 3 -> Level 2 -> Level 1 -> Level 0
      expect(log.indexOf('dispose:AppCoordinator'), equals(0));
      expect(
        log.indexOf('dispose:AnalyticsService'),
        greaterThan(log.indexOf('dispose:AppCoordinator')),
      );
      expect(
        log.indexOf('dispose:SessionService'),
        greaterThan(log.indexOf('dispose:AnalyticsService')),
      );
      expect(
        log.indexOf('dispose:OrderService'),
        greaterThan(log.indexOf('dispose:AnalyticsService')),
      );
      expect(
        log.indexOf('dispose:UserService'),
        greaterThan(log.indexOf('dispose:AnalyticsService')),
      );
      expect(
        log.indexOf('dispose:CacheService(deepCache)'),
        greaterThan(log.indexOf('dispose:SessionService')),
      );
      expect(
        log.indexOf('dispose:DatabaseService(deep.db)'),
        greaterThan(log.indexOf('dispose:CacheService(deepCache)')),
      );
      expect(
        log.indexOf('dispose:LoggerService'),
        greaterThan(log.indexOf('dispose:DatabaseService(deep.db)')),
      );
    });
  });

  group('Synchronous Runtime Reads and Laziness', () {
    test('sync wires are strictly lazily instantiated on first get', () async {
      var dbCreated = false;
      var userCreated = false;

      final circuit = await Circuit.build([
        Wire(() {
          dbCreated = true;
          return DatabaseService('lazy.db');
        }),
        Wire.takes<DatabaseService>().to((db) {
          userCreated = true;
          return UserService(db);
        }),
      ]);

      // Neither sync wire has been instantiated yet
      expect(dbCreated, isFalse);
      expect(userCreated, isFalse);
      expect(circuit.isInitialized<DatabaseService>(), isFalse);
      expect(circuit.isInitialized<UserService>(), isFalse);

      // Accessing UserService instantiates both UserService and its dependency DatabaseService
      final user = circuit.get<UserService>();
      expect(userCreated, isTrue);
      expect(dbCreated, isTrue);
      expect(circuit.isInitialized<UserService>(), isTrue);
      expect(circuit.isInitialized<DatabaseService>(), isTrue);

      // Repeated access returns identical instance without re-instantiation
      final userAgain = circuit.get<UserService>();
      expect(identical(user, userAgain), isTrue);
    });

    test('throws WireNotFoundException for unregistered wire', () async {
      final circuit = await Circuit.build([Wire(() => DatabaseService('db'))]);

      expect(
        () => circuit.get<CacheService>(),
        throwsA(
          isA<WireNotFoundException>().having(
            (e) => e.key,
            'key',
            equals((CacheService, null)),
          ),
        ),
      );

      expect(
        () => circuit.getTagged<DatabaseService, Environment>(Environment.prod),
        throwsA(
          isA<WireNotFoundException>().having(
            (e) => e.key,
            'key',
            equals((DatabaseService, Environment.prod)),
          ),
        ),
      );
    });

    test('sync factory error propagates and does not leave circuit in creating state', () async {
      var callCount = 0;
      final circuit = await Circuit.build([
        Wire<DatabaseService>(() {
          callCount++;
          if (callCount == 1) {
            throw FormatException('Database file corrupted');
          }
          return DatabaseService('recovered.db');
        }),
      ]);

      expect(
        () => circuit.get<DatabaseService>(),
        throwsA(isA<FormatException>()),
      );

      // Subsequent call re-attempts cleanly without circular dependency false positive
      final db = circuit.get<DatabaseService>();
      expect(db.path, equals('recovered.db'));
    });

    test(
      'isInitializedTagged returns true only for initialized tagged singletons',
      () async {
        final circuit = await Circuit.build([
          Wire.tag(() => DatabaseService('dev.db'), tag: Environment.dev),
          Wire.tag(() => DatabaseService('prod.db'), tag: Environment.prod),
        ]);

        expect(
          circuit.isInitializedTagged<DatabaseService, Environment>(
            Environment.dev,
          ),
          isFalse,
        );
        expect(
          circuit.isInitializedTagged<DatabaseService, Environment>(
            Environment.prod,
          ),
          isFalse,
        );

        circuit.getTagged<DatabaseService, Environment>(Environment.dev);

        expect(
          circuit.isInitializedTagged<DatabaseService, Environment>(
            Environment.dev,
          ),
          isTrue,
        );
        expect(
          circuit.isInitializedTagged<DatabaseService, Environment>(
            Environment.prod,
          ),
          isFalse,
        );
      },
    );
  });

  group('Reverse Topological Wave Disposal', () {
    test('disposes initialized instances in reverse topological order (leaves -> roots)', () async {
      final log = <String>[];

      final circuit = await Circuit.build([
        Wire(
          () => DatabaseService('db', log.add),
          onDispose: (inst) => inst.dispose(),
        ),
        Wire(
          () => CacheService('cache', log.add),
          onDispose: (inst) => inst.dispose(),
        ),
        Wire.takes<DatabaseService>().to(
          (db) => UserService(db, log.add),
          onDispose: (inst) => inst.dispose(),
        ),
        Wire.takes<UserService>().takes<CacheService>().to(
          (deps) => OrderService(deps.$1, deps.$2, log.add),
          onDispose: (inst) => inst.dispose(),
        ),
      ]);

      // Initialize all nodes
      circuit.get<OrderService>();

      await circuit.dispose();

      // Disposal order: OrderService (level 2) -> UserService (level 1) -> DatabaseService & CacheService (level 0)
      expect(log.indexOf('dispose:OrderService'), equals(0));
      expect(log.indexOf('dispose:UserService'), equals(1));
      expect(
        log.indexOf('dispose:DatabaseService(db)'),
        greaterThan(log.indexOf('dispose:UserService')),
      );
      expect(
        log.indexOf('dispose:CacheService(cache)'),
        greaterThan(log.indexOf('dispose:OrderService')),
      );
    });

    test('disposal is idempotent and only executes once', () async {
      var disposeCount = 0;

      final circuit = await Circuit.build([
        Wire(() => DatabaseService('db'), onDispose: (_) => disposeCount++),
      ]);

      circuit.get<DatabaseService>();

      await circuit.dispose();
      await circuit.dispose();
      await circuit.dispose();

      expect(disposeCount, equals(1));
      expect(circuit.isDisposed, isTrue);
    });

    test('uninitialized sync wires are NOT disposed', () async {
      var dbDisposed = false;
      var cacheDisposed = false;

      final circuit = await Circuit.build([
        Wire(() => DatabaseService('db'), onDispose: (_) => dbDisposed = true),
        Wire(
          () => CacheService('cache'),
          onDispose: (_) => cacheDisposed = true,
        ),
      ]);

      // Only initialize DatabaseService
      circuit.get<DatabaseService>();

      await circuit.dispose();

      expect(dbDisposed, isTrue);
      expect(cacheDisposed, isFalse);
    });

    test('aggregates disposal failures into DisposalException while completing other cleanups', () async {
      var dbDisposed = false;
      var cacheDisposed = false;

      final circuit = await Circuit.build([
        Wire(
          () => DatabaseService('db'),
          onDispose: (_) {
            dbDisposed = true;
            throw StateError('DB close failure');
          },
        ),
        Wire(
          () => CacheService('cache'),
          onDispose: (_) {
            cacheDisposed = true;
            throw FormatException('Cache flush failure');
          },
        ),
        Wire.takes<DatabaseService>().to(
          (db) => UserService(db),
          onDispose: (_) => throw RangeError('User cleanup failure'),
        ),
      ]);

      // Initialize UserService (which also initialises DatabaseService) and CacheService
      circuit.get<UserService>();
      circuit.get<CacheService>();

      await expectLater(
        circuit.dispose(),
        throwsA(
          isA<DisposalException>().having(
            (e) => e.errors.length,
            'errors.length',
            equals(3),
          ),
        ),
      );

      // Verify that all instances still had their disposal callbacks invoked
      expect(dbDisposed, isTrue);
      expect(cacheDisposed, isTrue);
      expect(circuit.isDisposed, isTrue);
    });

    test(
      'get and getTagged throw DisposedCircuitException after disposal',
      () async {
        final circuit = await Circuit.build([
          Wire(() => DatabaseService('db')),
          Wire.tag(() => DatabaseService('prod.db'), tag: Environment.prod),
        ]);

        await circuit.dispose();

        expect(
          () => circuit.get<DatabaseService>(),
          throwsA(isA<DisposedCircuitException>()),
        );

        expect(
          () =>
              circuit.getTagged<DatabaseService, Environment>(Environment.prod),
          throwsA(isA<DisposedCircuitException>()),
        );
      },
    );

    test(
      'clears instance cache on dispose so instances can be garbage collected',
      () async {
        final circuit = await Circuit.build([
          Wire(() => DatabaseService('db')),
          Wire.tag(() => DatabaseService('prod.db'), tag: Environment.prod),
        ]);

        circuit.get<DatabaseService>();
        circuit.getTagged<DatabaseService, Environment>(Environment.prod);

        expect(circuit.isInitialized<DatabaseService>(), isTrue);
        expect(
          circuit.isInitializedTagged<DatabaseService, Environment>(
            Environment.prod,
          ),
          isTrue,
        );

        await circuit.dispose();

        expect(circuit.isInitialized<DatabaseService>(), isFalse);
        expect(
          circuit.isInitializedTagged<DatabaseService, Environment>(
            Environment.prod,
          ),
          isFalse,
        );
      },
    );

    test('disposal idempotency after error: subsequent dispose calls succeed safely without re-throwing', () async {
      var disposeCalls = 0;
      final circuit = await Circuit.build([
        Wire(
          () => DatabaseService('db'),
          onDispose: (_) {
            disposeCalls++;
            throw StateError('fail on dispose');
          },
        ),
      ]);
      circuit.get<DatabaseService>();

      // First call throws DisposalException
      await expectLater(circuit.dispose(), throwsA(isA<DisposalException>()));
      expect(disposeCalls, equals(1));
      expect(circuit.isDisposed, isTrue);

      // Second call is safe and idempotent no-op
      await circuit.dispose();
      expect(disposeCalls, equals(1));
    });
  });

  group('Empty and Edge-Case Circuits', () {
    test('builds empty circuit and disposes without error', () async {
      final circuit = await Circuit.build([]);
      expect(circuit.isDisposed, isFalse);

      expect(
        () => circuit.get<DatabaseService>(),
        throwsA(isA<WireNotFoundException>()),
      );

      await circuit.dispose();
      expect(circuit.isDisposed, isTrue);
    });
  });
}
