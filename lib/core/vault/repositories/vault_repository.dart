import '../models/vault.dart';

/// Core repository contract for managing family health vaults on-device.
abstract interface class VaultRepository {
  /// Broadcast stream emitting the active vault ID whenever it changes.
  Stream<String> get activeVaultIdStream;

  /// Broadcast stream emitting the updated list of vaults whenever one is added or modified.
  Stream<List<Vault>> get vaultsStream;

  /// Retrieves all configured vaults.
  Future<List<Vault>> getVaults();

  /// Retrieves a specific vault by ID.
  Future<Vault?> getVaultById(String id);

  /// Stores or updates a vault.
  Future<void> addVault(Vault vault);

  /// Retrieves the current active vault identifier.
  Future<String> getActiveVaultId();

  /// Persists and broadcasts the new active vault identifier.
  Future<void> setActiveVaultId(String id);

  /// Closes internal stream controllers and releases listeners.
  void dispose();
}
