import 'package:flutter/widgets.dart';

import '../../../../core/design_system/arca_design_system.dart';
import '../../domain/models/profile.dart';

/// Accessible horizontal selector for switching between family member vaults.
class MemberSwitcherBar extends StatelessWidget {
  const MemberSwitcherBar({
    required this.profiles,
    required this.activeProfile,
    required this.onProfileSelected,
    required this.onAddProfile,
    super.key,
  });

  final List<Profile> profiles;
  final Profile activeProfile;
  final ValueChanged<String> onProfileSelected;
  final VoidCallback onAddProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArcaSpacing.md,
        vertical: ArcaSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: ArcaColors.surfaceSubtle,
        border: Border(
          bottom: BorderSide(color: ArcaColors.borderSubtle, width: 1.0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final profile in profiles) ...[
              _ProfilePill(
                profile: profile,
                isActive: profile.id == activeProfile.id,
                onTap: () => onProfileSelected(profile.id),
              ),
              const SizedBox(width: ArcaSpacing.xs),
            ],
            ArcaButton(
              label: '+ Add Member',
              variant: ArcaButtonVariant.ghost,
              semanticsLabel: 'Add a new family member profile',
              onPressed: onAddProfile,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({
    required this.profile,
    required this.isActive,
    required this.onTap,
  });

  final Profile profile;
  final bool isActive;
  final VoidCallback onTap;

  String _relationshipIcon(ProfileRelationship rel) {
    return switch (rel) {
      ProfileRelationship.self => '👤',
      ProfileRelationship.child => '🧒',
      ProfileRelationship.parent => '👵',
      ProfileRelationship.partner => '🤝',
      ProfileRelationship.other => '📋',
    };
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive ? ArcaColors.primary : ArcaColors.surface;
    final textColor = isActive
        ? ArcaColors.textInverse
        : ArcaColors.textPrimary;
    final borderColor = isActive ? ArcaColors.primary : ArcaColors.border;

    return Semantics(
      button: true,
      selected: isActive,
      label: '${profile.name} (${profile.relationship.name}) vault profile',
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48.0, minWidth: 48.0),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ArcaSpacing.md,
              vertical: ArcaSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: ArcaRadii.pill,
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _relationshipIcon(profile.relationship),
                  style: const TextStyle(fontSize: 14.0),
                ),
                const SizedBox(width: ArcaSpacing.xs),
                Text(
                  profile.name,
                  style: ArcaTypography.button.copyWith(
                    color: textColor,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
