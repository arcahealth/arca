import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';

/// Accessible, decoupled text input field for Arca.
///
/// Built strictly on Flutter's core [EditableText] and foundation primitives,
/// avoiding dependencies on Material [TextField] or Cupertino text fields.
class ArcaTextField extends StatefulWidget {
  const ArcaTextField({
    required this.controller,
    super.key,
    this.label,
    this.hintText,
    this.focusNode,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.semanticsLabel,
  });

  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? semanticsLabel;

  @override
  State<ArcaTextField> createState() => _ArcaTextFieldState();
}

class _ArcaTextFieldState extends State<ArcaTextField> {
  late FocusNode _internalFocusNode;
  bool _isFocused = false;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _effectiveFocusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(ArcaTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode).removeListener(
        _handleFocusChanged,
      );
      _effectiveFocusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChanged);
    _internalFocusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() => _isFocused = _effectiveFocusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSemantics =
        widget.semanticsLabel ??
        widget.label ??
        widget.hintText ??
        'Text Input';

    return Semantics(
      textField: true,
      label: effectiveSemantics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: ArcaTypography.caption.copyWith(
                color: ArcaColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: ArcaSpacing.xxs),
          ],
          GestureDetector(
            onTap: () => _effectiveFocusNode.requestFocus(),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              constraints: const BoxConstraints(minHeight: 48.0),
              padding: const EdgeInsets.symmetric(
                horizontal: ArcaSpacing.md,
                vertical: ArcaSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: ArcaColors.surface,
                borderRadius: ArcaRadii.md,
                border: Border.all(
                  color: _isFocused ? ArcaColors.primary : ArcaColors.border,
                  width: _isFocused ? 1.5 : 1.0,
                ),
              ),
              alignment: Alignment.centerLeft,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  if (widget.hintText != null && widget.controller.text.isEmpty)
                    Text(
                      widget.hintText!,
                      style: ArcaTypography.bodyMedium.copyWith(
                        color: ArcaColors.textMuted,
                      ),
                    ),
                  EditableText(
                    controller: widget.controller,
                    focusNode: _effectiveFocusNode,
                    style: ArcaTypography.bodyMedium.copyWith(
                      color: ArcaColors.textPrimary,
                    ),
                    cursorColor: ArcaColors.primary,
                    backgroundCursorColor: ArcaColors.surfaceElevated,
                    keyboardType: widget.keyboardType,
                    obscureText: widget.obscureText,
                    onChanged: (val) {
                      setState(() {});
                      widget.onChanged?.call(val);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
