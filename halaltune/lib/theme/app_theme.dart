import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pure AMOLED colour system – no Material You / dynamic colour.
/// Background: #000000  Surface: #0D0D0D  Cards: #141414
/// Accent: WHITE (#FFFFFF)  Active: #E0E0E0
class AppTheme {
  // Core AMOLED palette
  static const Color bg          = Color(0xFF000000);
  static const Color bgCard      = Color(0xFF0D0D0D);
  static const Color bgElevated  = Color(0xFF141414);
  static const Color surface     = Color(0xFF1A1A1A);
  static const Color surfaceHigh = Color(0xFF242424);

  // Accent (white)
  static const Color accent      = Color(0xFFFFFFFF);
  static const Color accentDim   = Color(0xFFE0E0E0);
  static const Color accentFaint = Color(0xFF3A3A3A);

  // Text
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textDim       = Color(0xFF555555);

  // Function colours
  static const Color liked  = Color(0xFFEF4444);
  static const Color danger = Color(0xFFFF4D4D);
  static const Color online = Color(0xFF4ADE80);

  static const Map<String, Color> langColors = {
    'arabic':    Color(0xFF10B981),
    'malayalam': Color(0xFF3B82F6),
    'english':   Color(0xFFF59E0B),
    'urdu':      Color(0xFF8B5CF6),
    'others':    Color(0xFF6B7280),
  };

  static final ColorScheme _cs = ColorScheme(
    brightness: Brightness.dark,
    primary: accent,
    onPrimary: Colors.black,
    primaryContainer: accentFaint,
    onPrimaryContainer: textPrimary,
    secondary: accentDim,
    onSecondary: Colors.black,
    secondaryContainer: surfaceHigh,
    onSecondaryContainer: textPrimary,
    tertiary: accentDim,
    onTertiary: Colors.black,
    tertiaryContainer: surfaceHigh,
    onTertiaryContainer: textPrimary,
    error: danger,
    onError: Colors.black,
    errorContainer: Color(0xFF3B0000),
    onErrorContainer: Color(0xFFFFB4AB),
    surface: bgCard,
    onSurface: textPrimary,
    surfaceContainerHighest: surfaceHigh,
    surfaceContainerHigh: surface,
    surfaceContainer: bgElevated,
    surfaceContainerLow: bgCard,
    surfaceContainerLowest: bg,
    onSurfaceVariant: textSecondary,
    outline: Color(0xFF333333),
    outlineVariant: Color(0xFF222222),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: textPrimary,
    onInverseSurface: Colors.black,
    inversePrimary: Colors.black,
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: _cs,
    fontFamily: 'Outfit',
    scaffoldBackgroundColor: bg,
    splashFactory: NoSplash.splashFactory,      // remove ripple for perf
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,

    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontFamily: 'Outfit', fontSize: 20,
        fontWeight: FontWeight.w700, color: textPrimary,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: bgCard,
      indicatorColor: accentFaint,
      height: 60,
      labelTextStyle: WidgetStateProperty.resolveWith((s) {
        final active = s.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: 'Outfit', fontSize: 10,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          color: active ? accent : textDim,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
        color: s.contains(WidgetState.selected) ? accent : textDim,
        size: 22,
      )),
    ),

    textTheme: const TextTheme(
      displayLarge:  TextStyle(fontFamily:'Outfit', fontSize:32, fontWeight:FontWeight.w700, color:textPrimary),
      displaySmall:  TextStyle(fontFamily:'Outfit', fontSize:26, fontWeight:FontWeight.w700, color:textPrimary),
      headlineMedium:TextStyle(fontFamily:'Outfit', fontSize:24, fontWeight:FontWeight.w700, color:textPrimary),
      headlineSmall: TextStyle(fontFamily:'Outfit', fontSize:20, fontWeight:FontWeight.w700, color:textPrimary),
      titleLarge:    TextStyle(fontFamily:'Outfit', fontSize:18, fontWeight:FontWeight.w600, color:textPrimary),
      titleMedium:   TextStyle(fontFamily:'Outfit', fontSize:16, fontWeight:FontWeight.w500, color:textPrimary),
      titleSmall:    TextStyle(fontFamily:'Outfit', fontSize:14, fontWeight:FontWeight.w500, color:textPrimary),
      bodyLarge:     TextStyle(fontFamily:'Outfit', fontSize:16, color:textPrimary),
      bodyMedium:    TextStyle(fontFamily:'Outfit', fontSize:14, color:textSecondary),
      bodySmall:     TextStyle(fontFamily:'Outfit', fontSize:12, color:textSecondary),
      labelLarge:    TextStyle(fontFamily:'Outfit', fontSize:14, fontWeight:FontWeight.w600, color:textPrimary),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgElevated,
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accent, width: 1)),
      hintStyle: const TextStyle(color: textDim, fontFamily: 'Outfit'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontFamily:'Outfit', fontSize:15, fontWeight:FontWeight.w700),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentFaint,
        foregroundColor: textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: const TextStyle(fontFamily:'Outfit', fontSize:15, fontWeight:FontWeight.w600),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: const BorderSide(color: accent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontFamily:'Outfit', fontWeight:FontWeight.w600),
      ),
    ),

    cardTheme: CardThemeData(
      color: bgElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
    ),

    dividerTheme: const DividerThemeData(color: Color(0xFF1E1E1E), thickness: 0.5),

    listTileTheme: const ListTileThemeData(
      tileColor: Colors.transparent,
      iconColor: textSecondary,
      titleTextStyle: TextStyle(fontFamily:'Outfit', fontSize:14, fontWeight:FontWeight.w500, color:textPrimary),
      subtitleTextStyle: TextStyle(fontFamily:'Outfit', fontSize:12, color:textSecondary),
    ),

    sliderTheme: const SliderThemeData(
      activeTrackColor: accent,
      inactiveTrackColor: Color(0xFF333333),
      thumbColor: accent,
      overlayColor: Color(0x22FFFFFF),
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
      trackHeight: 2.5,
    ),

    tabBarTheme: const TabBarThemeData(
      labelColor: accent,
      unselectedLabelColor: textDim,
      labelStyle: TextStyle(fontFamily:'Outfit', fontWeight:FontWeight.w600, fontSize:13),
      unselectedLabelStyle: TextStyle(fontFamily:'Outfit', fontSize:13),
      indicator: UnderlineTabIndicator(borderSide: BorderSide(color: accent, width: 2)),
      dividerColor: Color(0xFF1E1E1E),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: bgElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: bgElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceHigh,
      contentTextStyle: const TextStyle(color: textPrimary, fontFamily: 'Outfit'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),

    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
