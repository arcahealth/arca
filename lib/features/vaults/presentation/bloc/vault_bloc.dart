import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/vault/models/vault.dart';
import '../../../../core/vault/repositories/vault_repository.dart';
import 'vault_event.dart';
import 'vault_state.dart';

class VaultBloc extends Bloc<VaultEvent, VaultState> {
  VaultBloc({required this.repository}) : super(const VaultInitial()) {
    on<VaultLoadRequested>(_onLoadRequested);
    on<VaultActiveSwitched>(_onActiveSwitched);
    on<VaultAdded>(_onVaultAdded);
    on<VaultStreamUpdated>(_onStreamUpdated);

    // Reactive listening across modules via broadcast stream
    _vaultsSubscription = repository.vaultsStream.listen((vaults) async {
      final activeId = await repository.getActiveVaultId();
      add(VaultStreamUpdated(vaults: vaults, activeId: activeId));
    });

    _activeIdSubscription = repository.activeVaultIdStream.listen((
      activeId,
    ) async {
      final vaults = await repository.getVaults();
      add(VaultStreamUpdated(vaults: vaults, activeId: activeId));
    });
  }

  final VaultRepository repository;
  StreamSubscription? _vaultsSubscription;
  StreamSubscription? _activeIdSubscription;

  Future<void> _onLoadRequested(
    VaultLoadRequested event,
    Emitter<VaultState> emit,
  ) async {
    emit(const VaultLoading());
    try {
      final vaults = await repository.getVaults();
      final activeId = await repository.getActiveVaultId();
      final active = vaults.firstWhere(
        (v) => v.id == activeId,
        orElse: () => vaults.isNotEmpty
            ? vaults.first
            : Vault(
                id: 'self',
                name: 'Me (Primary)',
                relationship: VaultRelationship.self,
                createdAt: DateTime.now(),
              ),
      );
      emit(VaultLoaded(vaults: vaults, activeVault: active));
    } catch (e) {
      emit(VaultFailure('Failed to load vaults: $e'));
    }
  }

  Future<void> _onActiveSwitched(
    VaultActiveSwitched event,
    Emitter<VaultState> emit,
  ) async {
    final current = state;
    if (current is! VaultLoaded) return;

    try {
      await repository.setActiveVaultId(event.vaultId);
      final active = current.vaults.firstWhere(
        (v) => v.id == event.vaultId,
        orElse: () => current.activeVault,
      );
      emit(VaultLoaded(vaults: current.vaults, activeVault: active));
    } catch (e) {
      emit(VaultFailure('Failed to switch active vault: $e'));
    }
  }

  Future<void> _onVaultAdded(VaultAdded event, Emitter<VaultState> emit) async {
    try {
      await repository.addVault(event.vault);
      await repository.setActiveVaultId(event.vault.id);
      final vaults = await repository.getVaults();
      emit(VaultLoaded(vaults: vaults, activeVault: event.vault));
    } catch (e) {
      emit(VaultFailure('Failed to add vault: $e'));
    }
  }

  void _onStreamUpdated(VaultStreamUpdated event, Emitter<VaultState> emit) {
    if (event.vaults.isEmpty) {
      emit(
        VaultLoaded(
          vaults: const [],
          activeVault: Vault(
            id: 'self',
            name: 'Me (Primary)',
            relationship: VaultRelationship.self,
            createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        ),
      );
      return;
    }

    final active = event.vaults.firstWhere(
      (v) => v.id == event.activeId,
      orElse: () => event.vaults.first,
    );
    emit(VaultLoaded(vaults: event.vaults, activeVault: active));
  }

  @override
  Future<void> close() {
    _vaultsSubscription?.cancel();
    _activeIdSubscription?.cancel();
    return super.close();
  }
}

/// Compatibility alias.
typedef ProfileBloc = VaultBloc;
