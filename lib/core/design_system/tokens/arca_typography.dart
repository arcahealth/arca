import 'package:flutter/widgets.dart' show TextStyle, FontWeight;
import 'arca_colors.dart';

/// Clean typography hierarchy for medical records, journal entries, and vitals.
///
/// Designed independently from Material TextTheme to ensure long-term stability
/// across Flutter framework refactors.
abstract final class ArcaTypography {
  static const TextStyle display = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.5,
    color: ArcaColors.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.3,
    color: ArcaColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    height: 1.35,
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

  static const TextStyle button = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
    color: ArcaColors.textPrimary,
  );

  /// Tabular numbers for clinical lab results and biometric values.
  static const TextStyle metricValue = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w700,
    height: 1.2,
    fontFamily: 'monospace',
    color: ArcaColors.textPrimary,
  );
}
