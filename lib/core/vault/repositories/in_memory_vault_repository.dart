import 'dart:async';

import '../models/vault.dart';
import 'vault_repository.dart';

/// In-memory implementation of [VaultRepository] with broadcast streams for testing & offline use.
class InMemoryVaultRepository implements VaultRepository {
  InMemoryVaultRepository({
    List<Vault>? initialVaults,
    String initialActiveId = 'self',
  }) : _vaults = List.of(initialVaults ?? _defaultVaults),
       _activeVaultId = initialActiveId;

  final List<Vault> _vaults;
  String _activeVaultId;

  final StreamController<String> _activeVaultController =
      StreamController<String>.broadcast();
  final StreamController<List<Vault>> _vaultsController =
      StreamController<List<Vault>>.broadcast();

  static final List<Vault> _defaultVaults = [
    Vault(
      id: 'self',
      name: 'Me (Primary)',
      relationship: .self,
      createdAt: DateTime(2026, 1, 1),
    ),
    Vault(
      id: 'child_1',
      name: 'Leo',
      relationship: .child,
      createdAt: DateTime(2026, 2, 1),
    ),
    Vault(
      id: 'parent_1',
      name: 'Eleanor',
      relationship: .parent,
      createdAt: DateTime(2026, 3, 1),
    ),
  ];

  @override
  Stream<String> get activeVaultIdStream => _activeVaultController.stream;

  @override
  Stream<List<Vault>> get vaultsStream => _vaultsController.stream;

  @override
  Future<List<Vault>> getVaults() async => List.unmodifiable(_vaults);

  @override
  Future<Vault?> getVaultById(String id) async {
    final matches = _vaults.where((v) => v.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<void> addVault(Vault vault) async {
    _vaults.add(vault);
    _vaultsController.add(List.unmodifiable(_vaults));
  }

  @override
  Future<String> getActiveVaultId() async => _activeVaultId;

  @override
  Future<void> setActiveVaultId(String id) async {
    _activeVaultId = id;
    _activeVaultController.add(id);
  }

  @override
  void dispose() {
    _activeVaultController.close();
    _vaultsController.close();
  }
}
