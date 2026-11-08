import '../../../../core/vault/models/vault.dart';

sealed class const VaultEvent();

final class const VaultLoadRequested() extends VaultEvent;

final class const VaultActiveSwitched(final String vaultId) extends VaultEvent;

final class const VaultAdded(final Vault vault) extends VaultEvent;

final class const VaultStreamUpdated({
  required final List<Vault> vaults,
  required final String activeId,
}) extends VaultEvent;
