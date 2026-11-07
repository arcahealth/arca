import '../../../../core/vault/models/vault.dart';

sealed class VaultEvent {
  const VaultEvent();
}

final class VaultLoadRequested extends VaultEvent {
  const VaultLoadRequested();
}

final class VaultActiveSwitched extends VaultEvent {
  const VaultActiveSwitched(this.vaultId);
  final String vaultId;
}

final class VaultAdded extends VaultEvent {
  const VaultAdded(this.vault);
  final Vault vault;
}

final class VaultStreamUpdated extends VaultEvent {
  const VaultStreamUpdated({required this.vaults, required this.activeId});
  final List<Vault> vaults;
  final String activeId;
}

/// Compatibility aliases.
typedef ProfileEvent = VaultEvent;
typedef ProfileLoadRequested = VaultLoadRequested;
typedef ProfileActiveSwitched = VaultActiveSwitched;
typedef ProfileAdded = VaultAdded;
