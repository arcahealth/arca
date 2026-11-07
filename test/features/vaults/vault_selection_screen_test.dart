import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arca/core/design_system/arca_design_system.dart';
import 'package:arca/core/vault/models/vault.dart';
import 'package:arca/core/vault/repositories/in_memory_vault_repository.dart';
import 'package:arca/core/vault/repositories/vault_repository.dart';
import 'package:arca/features/vaults/presentation/bloc/vault_bloc.dart';
import 'package:arca/features/vaults/presentation/screens/vault_selection_screen.dart';

void main() {
  group('VaultSelectionScreen Tests', () {
    testWidgets(
      'Empty mode enforces vault creation and triggers onVaultCreated callback',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final VaultRepository emptyRepo = InMemoryVaultRepository(
          initialVaults: [],
        );
        addTearDown(emptyRepo.dispose);
        Vault? createdVault;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: BlocProvider<VaultBloc>(
              create: (_) => VaultBloc(repository: emptyRepo),
              child: VaultSelectionScreen(
                onVaultCreated: (v) => createdVault = v,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('No Vaults Configured'), findsOneWidget);
        expect(find.text('Create Your First Health Vault'), findsOneWidget);

        final textField = find.byType(ArcaTextField).first;
        await tester.enterText(textField, 'Personal Vault');
        await tester.pumpAndSettle();

        final createBtn = find.text('Create & Open Vault →');
        await tester.ensureVisible(createBtn);
        await tester.tap(createBtn);
        await tester.pumpAndSettle();

        expect(createdVault, isNotNull);
        expect(createdVault!.name, 'Personal Vault');
      },
    );

    testWidgets(
      'Multi-vault mode lists available vaults and triggers onVaultSelected callback',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final vault1 = Vault(
          id: 'vault-self',
          name: 'Me (Primary)',
          relationship: VaultRelationship.self,
          createdAt: DateTime(2026, 1, 1),
        );
        final vault2 = Vault(
          id: 'vault-child',
          name: 'Leo',
          relationship: VaultRelationship.child,
          createdAt: DateTime(2026, 2, 1),
        );

        final VaultRepository multiRepo = InMemoryVaultRepository(
          initialVaults: [vault1, vault2],
          initialActiveId: 'vault-self',
        );
        addTearDown(multiRepo.dispose);

        String? selectedId;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: BlocProvider<VaultBloc>(
              create: (_) => VaultBloc(repository: multiRepo),
              child: VaultSelectionScreen(
                onVaultSelected: (id) => selectedId = id,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Select Health Vault'), findsOneWidget);
        expect(find.text('Me (Primary)'), findsOneWidget);
        expect(find.text('Leo'), findsOneWidget);

        final leoVault = find.text('Leo');
        await tester.ensureVisible(leoVault);
        await tester.tap(leoVault);
        await tester.pumpAndSettle();

        expect(selectedId, 'vault-child');
      },
    );
  });
}
