import 'package:flutter/widgets.dart';

/// Conditionally renders [builder] when [value] is non-null, or [fallback]
/// (defaults to [SizedBox.shrink]) when null.
class const NullableBuilder<T>(
  final T? value, {
  required final Widget Function(BuildContext context, T value) builder,
  super.key,
  final Widget? fallback,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final v = value;
    if (v != null) return builder(context, v);

    return fallback ?? const SizedBox.shrink();
  }
}
