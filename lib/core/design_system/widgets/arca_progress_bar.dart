import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';

/// Accessible, foundation-first linear progress indicator.
class const ArcaProgressBar({
  required final double value,
  super.key,
  final double height = 8.0,
  final Color backgroundColor = ArcaColors.surfaceElevated,
  final Color progressColor = ArcaColors.primary,
  final String? semanticsLabel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0);
    final percentage = (clampedValue * 100).round();

    return Semantics(
      label: semanticsLabel ?? 'Progress',
      value: '$percentage%',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: ArcaRadii.pill,
        ),
        clipBehavior: .antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: .centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: constraints.maxWidth * clampedValue,
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: ArcaRadii.pill,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
