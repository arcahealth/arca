import 'dart:ui' show Color;

/// Core high-contrast color palette for Arca.
///
/// Designed with a Swiss / Neo-brutalist typographic minimalism aesthetic:
/// pure high-contrast surfaces, solid structural borders, stark typography,
/// and restrained clinical status accents without relying on Material/Cupertino tokens.
abstract final class ArcaColors {
  // Backgrounds & Surfaces (Pure Stark Monochrome)
  static const Color background = Color(0xFF000000); // Pure Pitch Black
  static const Color surface = Color(0xFF111111); // Raw Dark Slab
  static const Color surfaceElevated = Color(0xFF1C1C1C);
  static const Color surfaceSubtle = Color(0xFF161616);

  // Borders & Dividers (Stark 2px Architectural Lines)
  static const Color border = Color(
    0xFFFFFFFF,
  ); // High-contrast solid white border
  static const Color borderSubtle = Color(
    0xFF333333,
  ); // Structural grid divider

  // Shadows (Hard unblurred Neo-brutalist offset shadows)
  static const Color shadow = Color(0xFFFFFFFF);
  static const Color shadowSubtle = Color(0xFF404040);

  // Typography & Content
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure White
  static const Color textSecondary = Color(0xFFA3A3A3); // Neutral Gray
  static const Color textMuted = Color(0xFF737373); // Muted Label Gray
  static const Color textInverse = Color(
    0xFF000000,
  ); // Pure Black on white buttons

  // Brand & Clinical Accent
  static const Color primary = Color(
    0xFFFFFFFF,
  ); // Primary CTA is stark solid white box
  static const Color primaryHover = Color(0xFFE5E5E5);
  static const Color primarySubtle = Color(0xFF1F1F1F);
  static const Color accent = Color(0xFF0038FF); // International Klein Blue

  // Semantic Clinical Status
  static const Color success = Color(0xFF22C55E);
  static const Color successSubtle = Color(0xFF052E16);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSubtle = Color(0xFF451A03);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSubtle = Color(0xFF450A0A);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoSubtle = Color(0xFF172554);
}
