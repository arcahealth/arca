import 'package:flutter/widgets.dart';

import '../../../../core/design_system/arca_design_system.dart';
import '../../../../core/vault/models/vault.dart';

/// Horizontal switcher bar for active family member vaults.
///
/// Complies with mobile accessibility guidelines: 48x48 dp minimum tap targets,
/// keyboard focus highlight, and semantic roles.
class const VaultSwitcherBar({
  required final List<Vault> vaults,
  required final Vault activeVault,
  required final ValueChanged<String> onVaultSelected,
  super.key,
  final VoidCallback? onAddVault,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArcaSpacing.md,
        vertical: ArcaSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: ArcaColors.background,
        border: Border(
          bottom: BorderSide(color: ArcaColors.borderSubtle, width: 1.0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: .horizontal,
        child: Row(
          children: [
            for (final vault in vaults) ...[
              _buildVaultPill(context, vault, vault.id == activeVault.id),
              const SizedBox(width: ArcaSpacing.xs),
            ],
            if (onAddVault != null) ...[
              const SizedBox(width: ArcaSpacing.xs),
              ArcaButton(
                label: '+ Add Member',
                variant: .ghost,
                semanticsLabel: 'Add new family member vault',
                onPressed: onAddVault,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVaultPill(BuildContext context, Vault vault, bool isActive) {
    final backgroundColor = isActive
        ? ArcaColors.primary
        : ArcaColors.surfaceElevated;
    final textColor = isActive
        ? ArcaColors.textInverse
        : ArcaColors.textPrimary;
    final borderColor = isActive ? ArcaColors.primary : ArcaColors.border;

    return Semantics(
      button: true,
      selected: isActive,
      label: 'Switch to ${vault.name} (${vault.relationship.name})',
      child: GestureDetector(
        onTap: () => onVaultSelected(vault.id),
        behavior: .opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48.0, minWidth: 48.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: ArcaSpacing.md,
              vertical: ArcaSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: ArcaRadii.pill,
              border: Border.all(color: borderColor, width: 1.0),
            ),
            alignment: .center,
            child: Row(
              mainAxisSize: .min,
              children: [
                Text(
                  vault.name,
                  style: ArcaTypography.caption.copyWith(
                    color: textColor,
                    fontWeight: isActive ? .w700 : .w600,
                  ),
                ),
                if (!isActive) ...[
                  const SizedBox(width: ArcaSpacing.xxs),
                  ArcaBadge(
                    label: vault.relationship.name.toUpperCase(),
                    variant: .neutral,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
