import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';

/// Surface card for clinical records, vitals summaries, and family member cards.
class const ArcaCard({
  required final Widget child,
  super.key,
  final EdgeInsetsGeometry padding = const EdgeInsets.all(ArcaSpacing.md),
  final Color backgroundColor = ArcaColors.surface,
  final Color borderColor = ArcaColors.border,
  final VoidCallback? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: ArcaRadii.md,
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: .opaque,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
