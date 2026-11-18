import 'package:flutter/widgets.dart';

/// Conditionally builds a widget based on the presence of a nullable [value].
///
/// In widget trees, renders [builder] when [value] is non-null, and [fallback]
/// (or [SizedBox.shrink]) when null.
///
/// For properties typed `Widget?` (such as `leading` or `trailing` in headers),
/// use the static helper [NullableBuilder.orNull] to return `null` when [value] is null.
class const NullableBuilder<T>({
  required final T? value,
  required final Widget Function(BuildContext context, T value) builder,
  super.key,
  final Widget Function(BuildContext context)? fallback,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final v = value;
    if (v != null) return builder(context, v);
    return fallback?.call(context) ?? const SizedBox.shrink();
  }

  /// Evaluates [value] and returns a [Widget] if non-null, or the result of [onNull] (defaults to `null`).
  ///
  /// Eliminates repetitive ternary null-checks for `Widget?` properties.
  static Widget? orNull<T>(
    T? value,
    Widget Function(T value) builder, [
    Widget? Function()? onNull,
  ]) {
    if (value != null) return builder(value);
    return onNull?.call();
  }
}
