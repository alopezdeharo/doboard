import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  // Color semilla del sistema de tema (verde doboard)
  static const _seed = Color(0xFF1D9E75);

  static ThemeData get light {
    return FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: _seed,
        primaryContainer: Color(0xFFE1F5EE),
        secondary: Color(0xFF185FA5),
        secondaryContainer: Color(0xFFE6F1FB),
        tertiary: Color(0xFFBA7517),
        tertiaryContainer: Color(0xFFFAEEDA),
        appBarColor: Colors.white,
        error: Color(0xFFE24B4A),
      ),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 4,
      appBarStyle: FlexAppBarStyle.surface,
      appBarElevation: 0,
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
        inputDecoratorBorderType: FlexInputBorderType.underline,
        inputDecoratorUnfocusedHasBorder: false,
        cardRadius: 12,
        chipRadius: 8,
        bottomSheetRadius: 20,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      textTheme: _textTheme,
    );
  }

  static ThemeData get dark {
    return FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: Color(0xFF5DCAA5),
        primaryContainer: Color(0xFF085041),
        secondary: Color(0xFF85B7EB),
        secondaryContainer: Color(0xFF0C447C),
        tertiary: Color(0xFFFAC775),
        tertiaryContainer: Color(0xFF633806),
        appBarColor: Color(0xFF1A1A1A),
        error: Color(0xFFF09595),
      ),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 8,
      appBarStyle: FlexAppBarStyle.surface,
      appBarElevation: 0,
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
        inputDecoratorBorderType: FlexInputBorderType.underline,
        inputDecoratorUnfocusedHasBorder: false,
        cardRadius: 12,
        chipRadius: 8,
        bottomSheetRadius: 20,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      textTheme: _textTheme,
    );
  }

  static TextTheme get _textTheme {
    return GoogleFonts.dmSansTextTheme().copyWith(
      // Títulos de tarjeta y tablero
      titleMedium: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
      ),
      // Cuerpo de texto en tarjetas
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 11.5,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      // Labels de badges y contadores
      labelSmall: GoogleFonts.dmSans(
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    );
  }
}