import 'dart:ui' show Color;

/// Core color palette for Arca.
///
/// Designed with a calm, clinical journal aesthetic prioritizing legibility,
/// high contrast, and serene visual hierarchy without relying on Material/Cupertino tokens.
abstract final class ArcaColors {
  // Backgrounds & Surfaces
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B); // Slate 800
  static const Color surfaceElevated = Color(0xFF334155); // Slate 700
  static const Color surfaceSubtle = Color(0xFF182234);

  // Borders & Dividers
  static const Color border = Color(0xFF334155);
  static const Color borderSubtle = Color(0xFF243046);

  // Typography & Content
  static const Color textPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color textInverse = Color(0xFF0F172A);

  // Brand & Accent (Teal / Medical Cyan)
  static const Color primary = Color(0xFF0EA5E9); // Ocean / Sky 500
  static const Color primaryHover = Color(0xFF38BDF8);
  static const Color primarySubtle = Color(0xFF0C4A6E);

  // Semantic Clinical Status Colors
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successSubtle = Color(0xFF064E3B);
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningSubtle = Color(0xFF78350F);
  static const Color danger = Color(0xFFEF4444); // Red 500
  static const Color dangerSubtle = Color(0xFF7F1D1D);
  static const Color info = Color(0xFF6366F1); // Indigo 500
  static const Color infoSubtle = Color(0xFF312E81);
}
