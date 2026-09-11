import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFF2478C8);
  static const primaryDark = Color(0xFF155C99);
  static const darkPrimary = Color(0xFF41A1E3);
  static const darkPrimaryContainer = Color(0xFF0F2133);
  static const text = Color(0xFF101828);
  static const mutedText = Color(0xFF7E8792);
  static const fieldBorder = Color(0xFFE3E6EA);
  static const surface = Color(0xFFFFFFFF);
  static const welcomeTop = Color(0xFF8BAACD);
  static const welcomeBottom = Color(0xFFF4F8FC);
  static const welcomeText = Color(0xFF344054);
  static const darkBackground = Color(0xFF121212);
  static const darkCard = Color(0xFF191B24);
  static const darkSubtle = darkCard;
  static const darkElevated = Color(0xFF222835);
  static const darkBorder = Color(0xFF283143);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color pageBackground(BuildContext context) =>
      isDark(context) ? darkBackground : surface;

  static Color cardBackground(BuildContext context) =>
      isDark(context) ? darkCard : surface;

  static Color subtleBackground(BuildContext context) =>
      isDark(context) ? darkSubtle : const Color(0xFFFAFAFB);

  static Color fieldBackground(BuildContext context) =>
      isDark(context) ? darkCard : const Color(0xFFFAFAFA);

  static Color border(BuildContext context) =>
      isDark(context) ? darkBorder : const Color(0xFFEDEFF3);

  static Color accent(BuildContext context) =>
      isDark(context) ? darkPrimary : primary;

  static Color primaryText(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color secondaryText(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;
}
