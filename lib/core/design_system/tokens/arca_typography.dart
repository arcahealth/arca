import 'package:flutter/widgets.dart' show TextStyle, FontWeight;

import 'arca_colors.dart';

/// Clean, high-impact typography hierarchy adhering to Swiss International Typographic Style.
///
/// Prioritizes stark hierarchy, bold grotesque display headlines, tight tracking,
/// and highly legible clinical body text.
abstract final class ArcaTypography {
  static const TextStyle display = TextStyle(
    fontSize: 34.0,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -1.2,
    color: ArcaColors.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.4,
    color: ArcaColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.2,
    color: ArcaColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: ArcaColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: ArcaColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: ArcaColors.textMuted,
  );

  static const TextStyle label = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 1.5,
    color: ArcaColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.2,
    color: ArcaColors.textInverse,
  );

  /// Tabular numbers for clinical lab results and biometric values.
  static const TextStyle metricValue = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.w700,
    height: 1.1,
    fontFamily: 'monospace',
    color: ArcaColors.textPrimary,
  );
}
