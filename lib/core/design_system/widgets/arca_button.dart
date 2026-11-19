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
    if (!_isEnabled) return ArcaColors.surfaceElevated;
    switch (widget.variant) {
      case .primary:
        if (_isHovered) return ArcaColors.primaryHover;
        return ArcaColors.primary;
      case .secondary:
        if (_isHovered) return ArcaColors.surfaceElevated;
        return ArcaColors.surface;
      case .ghost:
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

  Border get _border {
    if (!_isEnabled) {
      return Border.all(color: ArcaColors.borderSubtle, width: 2.0);
    }
    switch (widget.variant) {
      case .primary:
        return Border.all(color: ArcaColors.textPrimary, width: 2.0);
      case .secondary:
        return Border.all(color: ArcaColors.border, width: 2.0);
      case .ghost:
        return Border.all(color: ArcaColors.borderSubtle, width: 2.0);
    }
  }

  List<BoxShadow> get _boxShadow {
    if (!_isEnabled || widget.variant == .ghost) return const [];
    final shadowColor = widget.variant == .primary
        ? ArcaColors.shadowSubtle
        : ArcaColors.shadow;
    final offset = _isPressed ? const Offset(1.0, 1.0) : const Offset(3.0, 3.0);
    return [BoxShadow(color: shadowColor, offset: offset, blurRadius: 0)];
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
          child: Transform.translate(
            offset: _isPressed ? const Offset(2.0, 2.0) : Offset.zero,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 60),
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
                boxShadow: _boxShadow,
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
                          if (widget.icon != null) ...[
                            const SizedBox(width: ArcaSpacing.xs),
                            widget.icon!,
                          ],
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
