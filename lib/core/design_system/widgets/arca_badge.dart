import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';

enum ArcaBadgeVariant { normal, warning, critical, info, neutral }

/// Clinical indicator pill badge for lab ranges, document states, and vitals.
class ArcaBadge extends StatelessWidget {
  const ArcaBadge({
    required this.label,
    super.key,
    this.variant = ArcaBadgeVariant.neutral,
  });

  final String label;
  final ArcaBadgeVariant variant;

  (Color bg, Color text) get _colors {
    switch (variant) {
      case ArcaBadgeVariant.normal:
        return (ArcaColors.successSubtle, ArcaColors.success);
      case ArcaBadgeVariant.warning:
        return (ArcaColors.warningSubtle, ArcaColors.warning);
      case ArcaBadgeVariant.critical:
        return (ArcaColors.dangerSubtle, ArcaColors.danger);
      case ArcaBadgeVariant.info:
        return (ArcaColors.infoSubtle, ArcaColors.info);
      case ArcaBadgeVariant.neutral:
        return (ArcaColors.surfaceElevated, ArcaColors.textSecondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, text) = _colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArcaSpacing.xs,
        vertical: ArcaSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: ArcaRadii.pill,
        border: Border.all(color: text.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: ArcaTypography.caption.copyWith(
          color: text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
