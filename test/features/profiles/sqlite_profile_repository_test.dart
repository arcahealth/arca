import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite_async/sqlite_async.dart';
import 'package:arca/core/database/migrations.dart';
import 'package:arca/features/profiles/data/repositories/sqlite_profile_repository.dart';
import 'package:arca/features/profiles/domain/models/profile.dart';

void main() {
  group('SqliteProfileRepository Tests', () {
    late Directory tempDir;
    late SqliteDatabase db;
    late SqliteProfileRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = Directory.systemTemp.createTempSync('arca_profiles_test_');
      final dbPath = p.join(tempDir.path, 'profiles_vault.db');
      db = SqliteDatabase(path: dbPath);
      await ArcaDatabaseMigrations.migrations.migrate(db);
      repository = SqliteProfileRepository(db: db);
    });

    tearDown(() async {
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('retrieves initial seeded self profile', () async {
      final profiles = await repository.getProfiles();
      expect(profiles, isNotEmpty);
      expect(profiles.first.id, 'self');
      expect(profiles.first.relationship, ProfileRelationship.self);
    });

    test(
      'adds and retrieves child and parent family member profiles',
      () async {
        final child = Profile(
          id: 'child-leo',
          name: 'Leo',
          relationship: ProfileRelationship.child,
          dateOfBirth: '2020-04-12',
          bloodType: 'O+',
          allergies: 'Penicillin',
          createdAt: DateTime(2026, 2, 1),
        );

        final parent = Profile(
          id: 'parent-eleanor',
          name: 'Eleanor',
          relationship: ProfileRelationship.parent,
          dateOfBirth: '1952-09-24',
          bloodType: 'A+',
          createdAt: DateTime(2026, 3, 1),
        );

        await repository.addProfile(child);
        await repository.addProfile(parent);

        final profiles = await repository.getProfiles();
        expect(profiles.length, 3); // self + child + parent

        final retrievedChild = await repository.getProfileById('child-leo');
        expect(retrievedChild, isNotNull);
        expect(retrievedChild!.name, 'Leo');
        expect(retrievedChild.allergies, 'Penicillin');
      },
    );

    test('persists and retrieves active profile identifier', () async {
      expect(await repository.getActiveProfileId(), 'self');

      await repository.setActiveProfileId('child-leo');
      expect(await repository.getActiveProfileId(), 'child-leo');
    });
  });
}
