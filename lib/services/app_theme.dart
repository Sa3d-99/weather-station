import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors from alhm_al5las.ino RGB565 palette
  static const Color bg        = Color(0xFF040821);  // COL_BG  0x0821
  static const Color card      = Color(0xFF081053);  // COL_CARD 0x10A3
  static const Color text      = Color(0xFFFFFFFF);  // COL_TEXT
  static const Color subtext   = Color(0xFFBDF7EF);  // COL_SUBTEXT 0x7BEF
  static const Color colHum    = Color(0xFF0EB7F8);  // COL_HUM  0x1DBF
  static const Color colWind   = Color(0xFFFC1F9E);  // COL_WIND 0xFC1F
  static const Color colPres   = Color(0xFF23F8C8);  // COL_PRES 0x47F1
  static const Color heroAcc   = Color(0xFFFF8C00);  // COL_HERO_ACC 0xFD20
  static const Color colTemp   = Color(0xFFFF6B35);  // derived warm orange

  static const Color online    = Color(0xFF00E676);
  static const Color offline   = Color(0xFFFF6D00);
  static const Color internet  = Color(0xFF7C4DFF);  // purple for internet data

  static const Color divider   = Color(0xFF1A2060);

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: heroAcc,
      secondary: colHum,
      surface: card,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.orbitron(color: text, fontSize: 32, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.orbitron(color: text, fontSize: 22, fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.orbitron(color: heroAcc, fontSize: 12, letterSpacing: 2.5, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.shareTechMono(color: text, fontSize: 13),
      bodyMedium: GoogleFonts.shareTechMono(color: subtext, fontSize: 11),
      labelSmall: GoogleFonts.orbitron(color: subtext, fontSize: 8, letterSpacing: 1.5),
    ),
    dividerColor: divider,
  );
}
