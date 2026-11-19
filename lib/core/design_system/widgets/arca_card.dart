import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';

/// Surface card for clinical records, vitals summaries, and family member cards.
///
/// Follows Swiss / Typographic Minimalist design: flat, sharp geometry,
/// clean 1px hairline borders, and zero faux drop-shadows.
class ArcaCard extends StatefulWidget {
  const ArcaCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(ArcaSpacing.md),
    this.backgroundColor = ArcaColors.surface,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  State<ArcaCard> createState() => _ArcaCardState();
}

class _ArcaCardState extends State<ArcaCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor =
        widget.borderColor ?? (_isHovered || _isPressed ? ArcaColors.border : ArcaColors.borderSubtle);

    final cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: _isPressed ? ArcaColors.surfaceElevated : widget.backgroundColor,
        borderRadius: ArcaRadii.none,
        border: Border.all(color: effectiveBorderColor, width: 1.0),
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      return FocusableActionDetector(
        onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          behavior: .opaque,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
