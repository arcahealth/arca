import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/common.dart' as sqlite;
import 'package:sqlite_async/sqlite_async.dart';

import '../../domain/models/profile.dart';
import '../../domain/repositories/profile_repository.dart';

/// On-device SQLite implementation of [ProfileRepository].
class SqliteProfileRepository implements ProfileRepository {
  SqliteProfileRepository({required this.db, this.prefs});

  final SqliteDatabase db;
  SharedPreferences? prefs;

  static const String _activeProfilePrefKey = 'arca_active_profile_id';

  Future<SharedPreferences> _getPrefs() async {
    final cached = prefs;
    if (cached != null) return cached;
    final loaded = await SharedPreferences.getInstance();
    prefs = loaded;
    return loaded;
  }

  @override
  Future<List<Profile>> getProfiles() async {
    final results = await db.getAll('''
      SELECT id, name, relationship, date_of_birth, blood_type, allergies, created_at
      FROM profiles
      ORDER BY created_at ASC
      ''');

    return results.map(_rowToProfile).toList(growable: false);
  }

  @override
  Future<Profile?> getProfileById(String id) async {
    final row = await db.getOptional(
      '''
      SELECT id, name, relationship, date_of_birth, blood_type, allergies, created_at
      FROM profiles
      WHERE id = ?
      ''',
      [id],
    );

    if (row == null) return null;
    return _rowToProfile(row);
  }

  @override
  Future<void> addProfile(Profile profile) async {
    await db.execute(
      '''
      INSERT OR REPLACE INTO profiles (
        id, name, relationship, date_of_birth, blood_type, allergies, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        profile.id,
        profile.name,
        profile.relationship.name,
        profile.dateOfBirth,
        profile.bloodType,
        profile.allergies,
        profile.createdAt.millisecondsSinceEpoch,
      ],
    );
  }

  @override
  Future<String> getActiveProfileId() async {
    final prefs = await _getPrefs();
    return prefs.getString(_activeProfilePrefKey) ?? 'self';
  }

  @override
  Future<void> setActiveProfileId(String id) async {
    final prefs = await _getPrefs();
    await prefs.setString(_activeProfilePrefKey, id);
  }

  static Profile _rowToProfile(sqlite.Row row) {
    final relName = row['relationship'] as String;
    final relationship = ProfileRelationship.values.firstWhere(
      (r) => r.name == relName,
      orElse: () => ProfileRelationship.other,
    );

    return Profile(
      id: row['id'] as String,
      name: row['name'] as String,
      relationship: relationship,
      dateOfBirth: row['date_of_birth'] as String?,
      bloodType: row['blood_type'] as String?,
      allergies: row['allergies'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    );
  }
}
