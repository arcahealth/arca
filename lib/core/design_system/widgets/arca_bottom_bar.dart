import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';

/// Bottom action and navigation bar for Arca screens.
///
/// Anchors navigation actions (back, continue, proceed) comfortably
/// within thumb reach at the bottom of the screen. When both [leading]
/// and [trailing] are provided, they are evenly spaced side-by-side.
class ArcaBottomBar extends StatelessWidget {
  const ArcaBottomBar({
    super.key,
    this.leading,
    this.trailing,
    this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: ArcaSpacing.lg,
      vertical: ArcaSpacing.md,
    ),
    this.showTopDivider = true,
  });

  final Widget? leading;
  final Widget? trailing;
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (child != null) {
      content = child!;
    } else if (leading != null && trailing != null) {
      content = Row(
        children: [
          Expanded(child: leading!),
          const SizedBox(width: ArcaSpacing.md),
          Expanded(child: trailing!),
        ],
      );
    } else if (trailing != null) {
      content = trailing!;
    } else if (leading != null) {
      content = Row(children: [Expanded(child: leading!)]);
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: showTopDivider
          ? const BoxDecoration(
              color: ArcaColors.background,
              border: Border(
                top: BorderSide(color: ArcaColors.borderSubtle, width: 1.0),
              ),
            )
          : const BoxDecoration(color: ArcaColors.background),
      padding: padding,
      child: content,
    );
  }
}
