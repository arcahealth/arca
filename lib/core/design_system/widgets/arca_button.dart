import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';

enum ArcaButtonVariant { primary, secondary, ghost }

/// Accessible, foundation-first button widget for Arca.
///
/// Complies with mobile accessibility guidelines: enforces a minimum 48x48 dp
/// tap target, supports keyboard focus, and embeds accessibility semantics.
/// Follows Swiss / Typographic Minimalist design: stark flat surfaces,
/// 1px architectural lines, zero faux drop-shadows, and automatic icon color inheritance.
class const ArcaButton({
  required final String label,
  required final VoidCallback? onPressed,
  super.key,
  final ArcaButtonVariant variant = .primary,
  final Widget? leadingIcon,
  final Widget? trailingIcon,
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
    if (!_isEnabled) return ArcaColors.surfaceSubtle;
    switch (widget.variant) {
      case .primary:
        if (_isPressed) return const Color(0xFFD4D4D4);
        if (_isHovered) return ArcaColors.primaryHover;
        return ArcaColors.primary;
      case .secondary:
        if (_isPressed) return ArcaColors.surfaceElevated;
        if (_isHovered) return ArcaColors.surfaceElevated;
        return ArcaColors.surface;
      case .ghost:
        if (_isPressed || _isHovered) return ArcaColors.surfaceSubtle;
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
    if (!_isEnabled) {
      return widget.variant == .secondary
          ? Border.all(color: ArcaColors.borderSubtle, width: 1.0)
          : null;
    }
    switch (widget.variant) {
      case .primary:
        return null;
      case .secondary:
        final borderColor = _isHovered
            ? ArcaColors.border
            : ArcaColors.borderSubtle;
        return Border.all(color: borderColor, width: 1.0);
      case .ghost:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = widget.semanticsLabel ?? widget.label;
    final effectiveLeading = widget.leadingIcon;
    final effectiveTrailing = widget.trailingIcon ?? widget.icon;

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
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 80),
            opacity: _isEnabled && _isPressed ? 0.8 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              constraints: const BoxConstraints(
                minHeight: 48.0,
                minWidth: 48.0,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: ArcaSpacing.md,
                vertical: ArcaSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: ArcaRadii.none,
                border: _border,
              ),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Text('...', style: ArcaTypography.button),
                      )
                    : IconTheme.merge(
                        data: IconThemeData(color: _textColor, size: 18.0),
                        child: Row(
                          mainAxisSize: .min,
                          mainAxisAlignment: .center,
                          children: [
                            if (effectiveLeading != null) ...[
                              effectiveLeading,
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
                            if (effectiveTrailing != null) ...[
                              const SizedBox(width: ArcaSpacing.xs),
                              effectiveTrailing,
                            ],
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
