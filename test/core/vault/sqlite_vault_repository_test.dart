import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite_async/sqlite_async.dart';
import 'package:arca/core/database/migrations.dart';
import 'package:arca/core/vault/models/vault.dart';
import 'package:arca/core/vault/repositories/sqlite_vault_repository.dart';
import 'package:arca/core/vault/repositories/vault_repository.dart';

void main() {
  group('SqliteVaultRepository Tests', () {
    late Directory tempDir;
    late SqliteDatabase db;
    late VaultRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = Directory.systemTemp.createTempSync('arca_vaults_test_');
      final dbPath = p.join(tempDir.path, 'vaults.db');
      db = SqliteDatabase(path: dbPath);
      await ArcaDatabaseMigrations.migrations.migrate(db);
      repository = SqliteVaultRepository(db: db);
    });

    tearDown(() async {
      repository.dispose();
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('retrieves initial seeded self vault', () async {
      final vaults = await repository.getVaults();
      expect(vaults, isNotEmpty);
      expect(vaults.first.id, 'self');
      expect(vaults.first.relationship, VaultRelationship.self);
    });

    test('adds and retrieves child and parent family member vaults', () async {
      final child = Vault(
        id: 'child-leo',
        name: 'Leo',
        relationship: VaultRelationship.child,
        dateOfBirth: '2020-04-12',
        bloodType: 'O+',
        allergies: 'Penicillin',
        createdAt: DateTime(2026, 2, 1),
      );

      final parent = Vault(
        id: 'parent-eleanor',
        name: 'Eleanor',
        relationship: VaultRelationship.parent,
        dateOfBirth: '1952-09-24',
        bloodType: 'A+',
        createdAt: DateTime(2026, 3, 1),
      );

      await repository.addVault(child);
      await repository.addVault(parent);

      final vaults = await repository.getVaults();
      expect(vaults.length, 3); // self + child + parent

      final retrievedChild = await repository.getVaultById('child-leo');
      expect(retrievedChild, isNotNull);
      expect(retrievedChild!.name, 'Leo');
      expect(retrievedChild.allergies, 'Penicillin');
    });

    test('persists and broadcasts active vault identifier', () async {
      expect(await repository.getActiveVaultId(), 'self');

      expectLater(repository.activeVaultIdStream, emits('child-leo'));

      await repository.setActiveVaultId('child-leo');
      expect(await repository.getActiveVaultId(), 'child-leo');
    });
  });
}
