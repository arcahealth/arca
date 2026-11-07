import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';

/// Accessible, foundation-first linear progress indicator.
class ArcaProgressBar extends StatelessWidget {
  const ArcaProgressBar({
    required this.value,
    super.key,
    this.height = 8.0,
    this.backgroundColor = ArcaColors.surfaceElevated,
    this.progressColor = ArcaColors.primary,
    this.semanticsLabel,
  });

  /// Progress fraction clamped between 0.0 and 1.0.
  final double value;
  final double height;
  final Color backgroundColor;
  final Color progressColor;
  final String? semanticsLabel;

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
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.centerLeft,
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
