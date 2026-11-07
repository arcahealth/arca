import '../../../../core/vault/models/vault.dart';

sealed class VaultState {
  const VaultState();
}

final class VaultInitial extends VaultState {
  const VaultInitial();
}

final class VaultLoading extends VaultState {
  const VaultLoading();
}

final class VaultLoaded extends VaultState {
  const VaultLoaded({required this.vaults, required this.activeVault});

  final List<Vault> vaults;
  final Vault activeVault;

  /// Compatibility getter.
  List<Vault> get profiles => vaults;
  Vault get activeProfile => activeVault;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultLoaded &&
          runtimeType == other.runtimeType &&
          activeVault == other.activeVault &&
          _listEquals(vaults, other.vaults);

  @override
  int get hashCode => Object.hash(activeVault, Object.hashAll(vaults));

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

final class VaultFailure extends VaultState {
  const VaultFailure(this.message);
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultFailure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// Compatibility aliases.
typedef ProfileState = VaultState;
typedef ProfileInitial = VaultInitial;
typedef ProfileLoading = VaultLoading;
typedef ProfileLoaded = VaultLoaded;
typedef ProfileFailure = VaultFailure;
