import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arca/core/vault/models/vault.dart';
import 'package:arca/features/vaults/presentation/widgets/vault_switcher_bar.dart';

void main() {
  group('VaultSwitcherBar Widget Tests', () {
    final self = Vault(
      id: 'self',
      name: 'Me (Primary)',
      relationship: VaultRelationship.self,
      createdAt: DateTime(2026, 1, 1),
    );

    final child = Vault(
      id: 'child_1',
      name: 'Leo',
      relationship: VaultRelationship.child,
      createdAt: DateTime(2026, 2, 1),
    );

    testWidgets('renders all member pills and handles selection', (
      tester,
    ) async {
      String? selectedId;
      var addCalled = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: VaultSwitcherBar(
            vaults: [self, child],
            activeVault: self,
            onVaultSelected: (id) => selectedId = id,
            onAddVault: () => addCalled = true,
          ),
        ),
      );

      expect(find.text('Me (Primary)'), findsOneWidget);
      expect(find.text('Leo'), findsOneWidget);
      expect(find.text('+ Add Member'), findsOneWidget);

      await tester.tap(find.text('Leo'));
      expect(selectedId, 'child_1');

      await tester.tap(find.text('+ Add Member'));
      expect(addCalled, isTrue);
    });
  });
}
