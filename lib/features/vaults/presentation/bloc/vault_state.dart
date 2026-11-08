import 'package:collection/collection.dart';

import '../../../../core/vault/models/vault.dart';

sealed class const VaultState();

final class const VaultInitial() extends VaultState;

final class const VaultLoading() extends VaultState;

final class const VaultLoaded({
  required final List<Vault> vaults,
  required final Vault activeVault,
}) extends VaultState {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultLoaded &&
          runtimeType == other.runtimeType &&
          activeVault == other.activeVault &&
          const ListEquality<Vault>().equals(vaults, other.vaults);

  @override
  int get hashCode =>
      Object.hash(activeVault, const ListEquality<Vault>().hash(vaults));
}

final class const VaultFailure(final String message) extends VaultState {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultFailure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
