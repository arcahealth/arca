import 'package:flutter/widgets.dart' show BorderRadius, Radius;

/// Corner radius tokens for rounded surfaces, cards, and buttons.
abstract final class ArcaRadii {
  static const double rawSm = 6.0;
  static const double rawMd = 12.0;
  static const double rawLg = 16.0;
  static const double rawPill = 999.0;

  static const BorderRadius sm = BorderRadius.all(Radius.circular(rawSm));
  static const BorderRadius md = BorderRadius.all(Radius.circular(rawMd));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(rawLg));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(rawPill));
}
