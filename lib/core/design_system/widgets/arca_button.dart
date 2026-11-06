import 'package:flutter/widgets.dart';
import '../tokens/tokens.dart';

enum ArcaButtonVariant {
  primary,
  secondary,
  ghost,
}

/// Accessible, foundation-first button widget for Arca.
///
/// Complies with mobile accessibility guidelines: enforces a minimum 48x48 dp
/// tap target, supports keyboard focus, and embeds accessibility semantics.
class ArcaButton extends StatefulWidget {
  const ArcaButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = ArcaButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.semanticsLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final ArcaButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final String? semanticsLabel;

  @override
  State<ArcaButton> createState() => _ArcaButtonState();
}

class _ArcaButtonState extends State<ArcaButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  Color get _backgroundColor {
    if (!_isEnabled) return ArcaColors.surfaceElevated.withValues(alpha: 0.4);
    switch (widget.variant) {
      case ArcaButtonVariant.primary:
        if (_isPressed) return ArcaColors.primarySubtle;
        if (_isHovered) return ArcaColors.primaryHover;
        return ArcaColors.primary;
      case ArcaButtonVariant.secondary:
        if (_isPressed) return ArcaColors.surfaceElevated;
        if (_isHovered) return ArcaColors.surfaceElevated;
        return ArcaColors.surface;
      case ArcaButtonVariant.ghost:
        if (_isPressed) return ArcaColors.surface;
        if (_isHovered) return ArcaColors.surfaceSubtle;
        return const Color(0x00000000);
    }
  }

  Color get _textColor {
    if (!_isEnabled) return ArcaColors.textMuted;
    switch (widget.variant) {
      case ArcaButtonVariant.primary:
        return ArcaColors.textInverse;
      case ArcaButtonVariant.secondary:
      case ArcaButtonVariant.ghost:
        return ArcaColors.textPrimary;
    }
  }

  Border? get _border {
    if (widget.variant == ArcaButtonVariant.secondary) {
      return Border.all(
        color: _isEnabled ? ArcaColors.border : ArcaColors.borderSubtle,
        width: 1.0,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = widget.semanticsLabel ?? widget.label;

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: effectiveLabel,
      child: FocusableActionDetector(
        enabled: _isEnabled,
        onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
        child: GestureDetector(
          onTap: _isEnabled ? widget.onPressed : null,
          onTapDown: _isEnabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: _isEnabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: () => setState(() => _isPressed = false),
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 48.0,
              minWidth: 48.0,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(
                horizontal: ArcaSpacing.md,
                vertical: ArcaSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: ArcaRadii.md,
                border: _border,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      widget.icon!,
                      const SizedBox(width: ArcaSpacing.xs),
                    ],
                    Text(
                      widget.label,
                      style: ArcaTypography.button.copyWith(color: _textColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
