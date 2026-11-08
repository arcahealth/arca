import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';

enum ArcaBadgeVariant { normal, warning, critical, info, neutral }

/// Clinical indicator pill badge for lab ranges, document states, and vitals.
class const ArcaBadge({
  required final String label,
  super.key,
  final ArcaBadgeVariant variant = .neutral,
}) extends StatelessWidget {
  (Color bg, Color text) get _colors {
    switch (variant) {
      case .normal:
        return (ArcaColors.successSubtle, ArcaColors.success);
      case .warning:
        return (ArcaColors.warningSubtle, ArcaColors.warning);
      case .critical:
        return (ArcaColors.dangerSubtle, ArcaColors.danger);
      case .info:
        return (ArcaColors.infoSubtle, ArcaColors.info);
      case .neutral:
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
        style: ArcaTypography.caption.copyWith(color: text, fontWeight: .w600),
      ),
    );
  }
}
