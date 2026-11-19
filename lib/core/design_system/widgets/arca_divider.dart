import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';

/// Classy, timeless 1px hairline divider for Swiss typographic layouts.
class ArcaDivider extends StatelessWidget {
  const ArcaDivider({
    super.key,
    this.color = ArcaColors.borderSubtle,
    this.thickness = 1.0,
    this.margin = const EdgeInsets.symmetric(vertical: ArcaSpacing.md),
  });

  final Color color;
  final double thickness;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Container(height: thickness, color: color),
    );
  }
}
