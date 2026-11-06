import 'package:flutter/widgets.dart';
import '../tokens/tokens.dart';

/// Surface card for clinical records, vitals summaries, and family member cards.
class ArcaCard extends StatelessWidget {
  const ArcaCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(ArcaSpacing.md),
    this.backgroundColor = ArcaColors.surface,
    this.borderColor = ArcaColors.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: ArcaRadii.md,
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
