import 'package:flutter/material.dart';

/// Colour tokens for the whole app.
///
/// Screens never hard-code colours. They call [AppPalette.of] and read the
/// token they need, which is what makes light / dark switching work on every
/// screen without each screen knowing about themes.
class AppPalette {
  final Color bg;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color onPrimary;

  const AppPalette({
    required this.bg,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.onPrimary,
  });

  static const light = AppPalette(
    bg: Color(0xFFFAF7F2),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE6E0D6),
    textPrimary: Color(0xFF1B2A41),
    textSecondary: Color(0xFF6B7280),
    primary: Color(0xFF1B2A41),
    onPrimary: Color(0xFFFFFFFF),
  );

  static const dark = AppPalette(
    bg: Color(0xFF0F141C),
    card: Color(0xFF1A2230),
    border: Color(0xFF2A3445),
    textPrimary: Color(0xFFF2EEE6),
    textSecondary: Color(0xFF9AA4B2),
    primary: Color(0xFFF2EEE6),
    onPrimary: Color(0xFF1B2A41),
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

/// Builds the two [ThemeData] objects handed to MaterialApp. Material widgets
/// we don't style ourselves (dialogs, progress indicators, segmented buttons)
/// pick their colours up from the colour scheme defined here.
class AppTheme {
  static const Color _seed = Color(0xFF1B2A41);

  static ThemeData get light => _build(Brightness.light, AppPalette.light);
  static ThemeData get dark => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    ).copyWith(
      primary: p.primary,
      onPrimary: p.onPrimary,
      surface: p.card,
      onSurface: p.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
    );
  }
}