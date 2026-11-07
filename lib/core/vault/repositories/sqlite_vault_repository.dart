import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/common.dart' as sqlite;
import 'package:sqlite_async/sqlite_async.dart';

import '../models/vault.dart';
import 'vault_repository.dart';

/// On-device SQLite implementation of [VaultRepository] with broadcast streams.
class SqliteVaultRepository implements VaultRepository {
  SqliteVaultRepository({required this.db, this.prefs});

  final SqliteDatabase db;
  SharedPreferences? prefs;

  static const String _activeVaultPrefKey = 'arca_active_profile_id';

  final StreamController<String> _activeVaultController =
      StreamController<String>.broadcast();
  final StreamController<List<Vault>> _vaultsController =
      StreamController<List<Vault>>.broadcast();

  @override
  Stream<String> get activeVaultIdStream => _activeVaultController.stream;

  @override
  Stream<List<Vault>> get vaultsStream => _vaultsController.stream;

  Future<SharedPreferences> _getPrefs() async {
    final cached = prefs;
    if (cached != null) return cached;
    final loaded = await SharedPreferences.getInstance();
    prefs = loaded;
    return loaded;
  }

  @override
  Future<List<Vault>> getVaults() async {
    final results = await db.getAll('''
      SELECT id, name, relationship, date_of_birth, blood_type, allergies, created_at
      FROM profiles
      ORDER BY created_at ASC
      ''');

    return results.map(_rowToVault).toList(growable: false);
  }

  @override
  Future<Vault?> getVaultById(String id) async {
    final row = await db.getOptional(
      '''
      SELECT id, name, relationship, date_of_birth, blood_type, allergies, created_at
      FROM profiles
      WHERE id = ?
      ''',
      [id],
    );

    if (row == null) return null;
    return _rowToVault(row);
  }

  @override
  Future<void> addVault(Vault vault) async {
    await db.execute(
      '''
      INSERT OR REPLACE INTO profiles (
        id, name, relationship, date_of_birth, blood_type, allergies, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        vault.id,
        vault.name,
        vault.relationship.name,
        vault.dateOfBirth,
        vault.bloodType,
        vault.allergies,
        vault.createdAt.millisecondsSinceEpoch,
      ],
    );

    final updated = await getVaults();
    _vaultsController.add(updated);
  }

  @override
  Future<String> getActiveVaultId() async {
    final p = await _getPrefs();
    return p.getString(_activeVaultPrefKey) ?? 'self';
  }

  @override
  Future<void> setActiveVaultId(String id) async {
    final p = await _getPrefs();
    await p.setString(_activeVaultPrefKey, id);
    _activeVaultController.add(id);
  }

  @override
  Future<List<Vault>> getProfiles() => getVaults();

  @override
  Future<Vault?> getProfileById(String id) => getVaultById(id);

  @override
  Future<void> addProfile(Vault vault) => addVault(vault);

  @override
  Future<String> getActiveProfileId() => getActiveVaultId();

  @override
  Future<void> setActiveProfileId(String id) => setActiveVaultId(id);

  static Vault _rowToVault(sqlite.Row row) {
    final relName = row['relationship'] as String;
    final relationship = VaultRelationship.values.firstWhere(
      (r) => r.name == relName,
      orElse: () => VaultRelationship.other,
    );

    return Vault(
      id: row['id'] as String,
      name: row['name'] as String,
      relationship: relationship,
      dateOfBirth: row['date_of_birth'] as String?,
      bloodType: row['blood_type'] as String?,
      allergies: row['allergies'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    );
  }

  @override
  void dispose() {
    _activeVaultController.close();
    _vaultsController.close();
  }
}

typedef SqliteProfileRepository = SqliteVaultRepository;
