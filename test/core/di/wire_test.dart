import 'package:arca/core/di/di.dart';
import 'package:flutter_test/flutter_test.dart';

enum Environment { dev, staging, prod }

enum Role { user, admin }

enum CacheKind { fast, persistent }

final class DatabaseService {
  final String path;
  DatabaseService([this.path = 'memory.db']);
}

final class CacheService {
  final CacheKind kind;
  CacheService([this.kind = CacheKind.fast]);
}

final class AuthService {
  final String secret;
  AuthService([this.secret = 'default-secret']);
}

final class UserService {
  final DatabaseService db;
  UserService(this.db);
}

final class OrderService {
  final DatabaseService db;
  final CacheService cache;
  OrderService(this.db, this.cache);
}

final class AppService {
  final DatabaseService db;
  final CacheService cache;
  final AuthService auth;
  AppService(this.db, this.cache, this.auth);
}

final class NotificationService {
  final String channel;
  NotificationService([this.channel = 'alerts']);
}

final class ComplexAppService {
  final DatabaseService db;
  final CacheService cache;
  final AuthService auth;
  final NotificationService notifications;
  ComplexAppService(this.db, this.cache, this.auth, this.notifications);
}

void main() {
  group('WireKey and Wire Definition Specs', () {
    test('untagged sync Wire has (T, null) key and isAsync false', () {
      final wire = Wire(() => DatabaseService());
      expect(wire.key, equals((DatabaseService, null)));
      expect(wire.dependencies, isEmpty);
      expect(wire.isAsync, isFalse);
    });

    test('tagged sync Wire has (T, tag) key and isAsync false', () {
      final wire = Wire.tag(
        () => DatabaseService('prod.db'),
        tag: Environment.prod,
      );
      expect(wire.key, equals((DatabaseService, Environment.prod)));
      expect(wire.dependencies, isEmpty);
      expect(wire.isAsync, isFalse);
    });

    test('untagged AsyncWire has (T, null) key and isAsync true', () {
      final wire = AsyncWire(() async => DatabaseService());
      expect(wire.key, equals((DatabaseService, null)));
      expect(wire.dependencies, isEmpty);
      expect(wire.isAsync, isTrue);
    });

    test('tagged AsyncWire has (T, tag) key and isAsync true', () {
      final wire = AsyncWire.tag(
        () async => DatabaseService('staging.db'),
        tag: Environment.staging,
      );
      expect(wire.key, equals((DatabaseService, Environment.staging)));
      expect(wire.dependencies, isEmpty);
      expect(wire.isAsync, isTrue);
    });
  });

  group('WireBuilder Accumulator Chaining', () {
    test('1-dep Wire.takes<A>() produces builder with single dependency', () {
      final builder = Wire.takes<DatabaseService>();
      final wire = builder.to(UserService.new);

      expect(wire.key, equals((UserService, null)));
      expect(wire.dependencies, equals([(DatabaseService, null)]));
      expect(wire.isAsync, isFalse);
    });

    test('1-dep Wire.takesTagged<A, K>(tag) produces builder with tagged dependency', () {
      final wire = Wire.takesTagged<DatabaseService, Environment>(
        Environment.prod,
      ).to(UserService.new);

      expect(wire.key, equals((UserService, null)));
      expect(wire.dependencies, equals([(DatabaseService, Environment.prod)]));
    });

    test('2-deps WireBuilder chains into (Acc, Next) accumulator', () {
      final wire = Wire.takes<DatabaseService>().takes<CacheService>().to(
        (deps) => OrderService(deps.$1, deps.$2),
      );

      expect(wire.key, equals((OrderService, null)));
      expect(
        wire.dependencies,
        equals([(DatabaseService, null), (CacheService, null)]),
      );
    });

    test('3-deps WireBuilder chains into ((Acc, Next1), Next2)', () {
      final wire = Wire.takes<DatabaseService>()
          .takes<CacheService>()
          .takes<AuthService>()
          .to((deps) {
            final ((db, cache), auth) = deps;
            return AppService(db, cache, auth);
          });

      expect(wire.key, equals((AppService, null)));
      expect(
        wire.dependencies,
        equals([
          (DatabaseService, null),
          (CacheService, null),
          (AuthService, null),
        ]),
      );
    });

    test('WireBuilder supports mixed untagged and tagged dependencies', () {
      final wire = Wire.takes<DatabaseService>()
          .takesTagged<CacheService, CacheKind>(CacheKind.persistent)
          .to((deps) => OrderService(deps.$1, deps.$2));

      expect(wire.key, equals((OrderService, null)));
      expect(
        wire.dependencies,
        equals([(DatabaseService, null), (CacheService, CacheKind.persistent)]),
      );
    });

    test('WireBuilder.to supports tagged output wire', () {
      final wire = Wire.takes<DatabaseService>().to(
        UserService.new,
        tag: Role.admin,
      );

      expect(wire.key, equals((UserService, Role.admin)));
      expect(wire.dependencies, equals([(DatabaseService, null)]));
    });
  });

  group('AsyncWireBuilder Accumulator Chaining', () {
    test('1-dep AsyncWire.takes<A>() produces async wire', () {
      final wire = AsyncWire.takes<DatabaseService>().to(
        (db) async => UserService(db),
      );

      expect(wire.key, equals((UserService, null)));
      expect(wire.dependencies, equals([(DatabaseService, null)]));
      expect(wire.isAsync, isTrue);
    });

    test('1-dep AsyncWire.takesTagged<A, K>() produces tagged dependency', () {
      final wire = AsyncWire.takesTagged<DatabaseService, Environment>(
        Environment.staging,
      ).to((db) async => UserService(db));

      expect(wire.key, equals((UserService, null)));
      expect(
        wire.dependencies,
        equals([(DatabaseService, Environment.staging)]),
      );
      expect(wire.isAsync, isTrue);
    });

    test('2-deps AsyncWireBuilder chains into (Acc, Next)', () {
      final wire = AsyncWire.takes<DatabaseService>().takes<CacheService>().to(
        (deps) async => OrderService(deps.$1, deps.$2),
      );

      expect(wire.key, equals((OrderService, null)));
      expect(
        wire.dependencies,
        equals([(DatabaseService, null), (CacheService, null)]),
      );
      expect(wire.isAsync, isTrue);
    });

    test('AsyncWireBuilder.to supports tagged output wire', () {
      final wire = AsyncWire.takes<DatabaseService>().to(
        (db) async => UserService(db),
        tag: Role.admin,
      );

      expect(wire.key, equals((UserService, Role.admin)));
      expect(wire.dependencies, equals([(DatabaseService, null)]));
      expect(wire.isAsync, isTrue);
    });
  });

  group('disposeInstance Hook Handling', () {
    test('invokes onDispose with typed instance for Wire', () async {
      var disposed = false;
      final wire = Wire(
        () => DatabaseService(),
        onDispose: (instance) {
          disposed = true;
        },
      );

      final db = DatabaseService();
      await wire.disposeInstance(db);
      expect(disposed, isTrue);

      // Disposing non-matching instance does not invoke callback
      var otherDisposed = false;
      final otherWire = Wire(
        () => DatabaseService(),
        onDispose: (_) => otherDisposed = true,
      );
      await otherWire.disposeInstance('not a database service');
      expect(otherDisposed, isFalse);
    });

    test('invokes onDispose with typed instance for AsyncWire', () async {
      var disposed = false;
      final wire = AsyncWire(
        () async => DatabaseService(),
        onDispose: (instance) {
          disposed = true;
        },
      );

      final db = DatabaseService();
      await wire.disposeInstance(db);
      expect(disposed, isTrue);
    });
  });

  group('Unpacker Resolution Verification in Circuit', () {
    test('1-dep tear-off unpacks single dependency directly', () async {
      final circuit = await Circuit.build([
        Wire(() => DatabaseService('direct.db')),
        Wire.takes<DatabaseService>().to(UserService.new),
      ]);

      final user = circuit.get<UserService>();
      expect(user.db.path, equals('direct.db'));
    });

    test('2-deps unpacks (Acc, Next) tuple directly into closure', () async {
      final circuit = await Circuit.build([
        Wire(() => DatabaseService('multi.db')),
        Wire(() => CacheService(CacheKind.persistent)),
        Wire.takes<DatabaseService>().takes<CacheService>().to(
          (deps) => OrderService(deps.$1, deps.$2),
        ),
      ]);

      final order = circuit.get<OrderService>();
      expect(order.db.path, equals('multi.db'));
      expect(order.cache.kind, equals(CacheKind.persistent));
    });

    test('3-deps unpacks ((Acc, Next1), Next2) nested record tuple', () async {
      final circuit = await Circuit.build([
        Wire(() => DatabaseService('app.db')),
        Wire(() => CacheService(CacheKind.fast)),
        Wire(() => AuthService('app-secret')),
        Wire.takes<DatabaseService>()
            .takes<CacheService>()
            .takes<AuthService>()
            .to((deps) {
              final ((db, cache), auth) = deps;
              return AppService(db, cache, auth);
            }),
      ]);

      final app = circuit.get<AppService>();
      expect(app.db.path, equals('app.db'));
      expect(app.cache.kind, equals(CacheKind.fast));
      expect(app.auth.secret, equals('app-secret'));
    });

    test(
      '4-deps unpacks (((Acc, Next1), Next2), Next3) left-nested record tuple',
      () async {
        final circuit = await Circuit.build([
          Wire(() => DatabaseService('app.db')),
          Wire(() => CacheService(CacheKind.fast)),
          Wire(() => AuthService('app-secret')),
          Wire(() => NotificationService('push')),
          Wire.takes<DatabaseService>()
              .takes<CacheService>()
              .takes<AuthService>()
              .takes<NotificationService>()
              .to((deps) {
                final (((db, cache), auth), notifs) = deps;
                return ComplexAppService(db, cache, auth, notifs);
              }),
        ]);

        final app = circuit.get<ComplexAppService>();
        expect(app.db.path, equals('app.db'));
        expect(app.cache.kind, equals(CacheKind.fast));
        expect(app.auth.secret, equals('app-secret'));
        expect(app.notifications.channel, equals('push'));
      },
    );
  });
}
