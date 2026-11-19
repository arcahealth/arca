import 'package:flutter/widgets.dart' show BorderRadius;

/// Corner radius tokens for Arca.
///
/// Follows Swiss Design and Neo-brutalist principles: pure geometric sharp corners
/// without decorative rounded curves or pill shapes.
abstract final class ArcaRadii {
  static const double rawNone = 0.0;
  static const double rawSm = 0.0;
  static const double rawMd = 0.0;
  static const double rawLg = 0.0;
  static const double rawPill = 0.0;

  static const BorderRadius none = BorderRadius.zero;
  static const BorderRadius sm = BorderRadius.zero;
  static const BorderRadius md = BorderRadius.zero;
  static const BorderRadius lg = BorderRadius.zero;
  static const BorderRadius pill = BorderRadius.zero;
}
