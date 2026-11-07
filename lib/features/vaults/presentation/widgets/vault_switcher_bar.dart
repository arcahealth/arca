import 'package:flutter/widgets.dart';

import '../../../../core/design_system/arca_design_system.dart';
import '../../../../core/vault/models/vault.dart';

/// Horizontal switcher bar for active family member vaults.
///
/// Complies with mobile accessibility guidelines: 48x48 dp minimum tap targets,
/// keyboard focus highlight, and semantic roles.
class VaultSwitcherBar extends StatelessWidget {
  const VaultSwitcherBar({
    required this.vaults,
    required this.activeVault,
    required this.onVaultSelected,
    super.key,
    this.onAddVault,
  });

  final List<Vault> vaults;
  final Vault activeVault;
  final ValueChanged<String> onVaultSelected;
  final VoidCallback? onAddVault;

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
        scrollDirection: Axis.horizontal,
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
                variant: ArcaButtonVariant.ghost,
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
        behavior: HitTestBehavior.opaque,
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
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vault.name,
                  style: ArcaTypography.caption.copyWith(
                    color: textColor,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                if (!isActive) ...[
                  const SizedBox(width: ArcaSpacing.xxs),
                  ArcaBadge(
                    label: vault.relationship.name.toUpperCase(),
                    variant: ArcaBadgeVariant.neutral,
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

/// Backwards compatibility wrapper for tests.
class MemberSwitcherBar extends StatelessWidget {
  const MemberSwitcherBar({
    required this.profiles,
    required this.activeProfile,
    required this.onProfileSelected,
    super.key,
    this.onAddProfile,
  });

  final List<Vault> profiles;
  final Vault activeProfile;
  final ValueChanged<String> onProfileSelected;
  final VoidCallback? onAddProfile;

  @override
  Widget build(BuildContext context) {
    return VaultSwitcherBar(
      vaults: profiles,
      activeVault: activeProfile,
      onVaultSelected: onProfileSelected,
      onAddVault: onAddProfile,
    );
  }
}
