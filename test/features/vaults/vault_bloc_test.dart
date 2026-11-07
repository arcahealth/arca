import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arca/core/vault/models/vault.dart';
import 'package:arca/core/vault/repositories/in_memory_vault_repository.dart';
import 'package:arca/core/vault/repositories/vault_repository.dart';
import 'package:arca/features/vaults/presentation/bloc/vault_bloc.dart';
import 'package:arca/features/vaults/presentation/bloc/vault_event.dart';
import 'package:arca/features/vaults/presentation/bloc/vault_state.dart';

void main() {
  group('VaultBloc Tests', () {
    late VaultRepository repo;

    final selfVault = Vault(
      id: 'self',
      name: 'Me (Primary)',
      relationship: VaultRelationship.self,
      createdAt: DateTime(2026, 1, 1),
    );

    setUp(() {
      repo = InMemoryVaultRepository(initialVaults: [selfVault]);
    });

    tearDown(() => repo.dispose());

    test('initial state is VaultInitial', () {
      final bloc = VaultBloc(repository: repo);
      expect(bloc.state, isA<VaultInitial>());
      bloc.close();
    });

    blocTest<VaultBloc, VaultState>(
      'loads vaults and sets active vault',
      build: () => VaultBloc(repository: repo),
      act: (bloc) => bloc.add(const VaultLoadRequested()),
      expect: () => [
        const VaultLoading(),
        VaultLoaded(vaults: [selfVault], activeVault: selfVault),
      ],
    );

    blocTest<VaultBloc, VaultState>(
      'switches active vault',
      build: () => VaultBloc(
        repository: InMemoryVaultRepository(
          initialVaults: [
            selfVault,
            Vault(
              id: 'child_1',
              name: 'Leo',
              relationship: VaultRelationship.child,
              createdAt: DateTime(2026, 2, 1),
            ),
          ],
        ),
      ),
      seed: () => VaultLoaded(
        vaults: [
          selfVault,
          Vault(
            id: 'child_1',
            name: 'Leo',
            relationship: VaultRelationship.child,
            createdAt: DateTime(2026, 2, 1),
          ),
        ],
        activeVault: selfVault,
      ),
      act: (bloc) => bloc.add(const VaultActiveSwitched('child_1')),
      expect: () => [
        predicate<VaultLoaded>((state) => state.activeVault.id == 'child_1'),
      ],
    );
  });
}
