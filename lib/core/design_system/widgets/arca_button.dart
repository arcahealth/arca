import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';

enum ArcaButtonVariant { primary, secondary, ghost }

/// Accessible, foundation-first button widget for Arca.
///
/// Complies with mobile accessibility guidelines: enforces a minimum 48x48 dp
/// tap target, supports keyboard focus, and embeds accessibility semantics.
class const ArcaButton({
  required final String label,
  required final VoidCallback? onPressed,
  super.key,
  final ArcaButtonVariant variant = .primary,
  final Widget? icon,
  final bool isLoading = false,
  final String? semanticsLabel,
}) extends StatefulWidget {
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
      case .primary:
        if (_isPressed) return ArcaColors.primarySubtle;
        if (_isHovered) return ArcaColors.primaryHover;
        return ArcaColors.primary;
      case .secondary:
        if (_isPressed) return ArcaColors.surfaceElevated;
        if (_isHovered) return ArcaColors.surfaceElevated;
        return ArcaColors.surface;
      case .ghost:
        if (_isPressed) return ArcaColors.surface;
        if (_isHovered) return ArcaColors.surfaceSubtle;
        return const Color(0x00000000);
    }
  }

  Color get _textColor {
    if (!_isEnabled) return ArcaColors.textMuted;
    switch (widget.variant) {
      case .primary:
        return ArcaColors.textInverse;
      case .secondary:
      case .ghost:
        return ArcaColors.textPrimary;
    }
  }

  Border? get _border {
    if (widget.variant == .secondary) {
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
      onTap: _isEnabled ? widget.onPressed : null,
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: _isEnabled,
        onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
        child: GestureDetector(
          onTap: _isEnabled ? widget.onPressed : null,
          onTapDown: _isEnabled
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: _isEnabled
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: () => setState(() => _isPressed = false),
          behavior: .opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 48.0, minWidth: 48.0),
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
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Text('...', style: ArcaTypography.button),
                    )
                  : Row(
                      mainAxisSize: .min,
                      mainAxisAlignment: .center,
                      children: [
                        if (widget.icon != null) ...[
                          widget.icon!,
                          const SizedBox(width: ArcaSpacing.xs),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
                            style: ArcaTypography.button.copyWith(
                              color: _textColor,
                            ),
                            maxLines: 1,
                            overflow: .ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
