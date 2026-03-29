import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:obsidian/l10n/app_localizations.dart';
import 'features/login/presentation/screens/login_screen.dart';

/// 全局颜色 Token，对齐 Stitch 设计规范
class AppColors {
  // 品牌主色
  static const brandPrimary = Color(0xFF0053D4);
  static const brandPrimaryAlt = Color(0xFF1E6BFF);
  static const brandPrimaryPressed = Color(0xFF1552CC);
  static const brandPrimaryContainer = Color(0xFFE8F0FF);
  static const brandSecondary = Color(0xFF0EA5A6);
  static const brandAccent = Color(0xFFF59E0B);

  // 语义色
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const error = Color(0xFFDC2626);
  static const info = Color(0xFF0EA5E9);

  // 亮色中性色
  static const lightBg = Color(0xFFF8FAFC);       // 页面背景
  static const lightSurface = Color(0xFFFFFFFF);  // 卡片/组件
  static const lightSurfaceLow = Color(0xFFF2F3FF); // 侧栏背景
  static const lightSurfaceHigh = Color(0xFFEAEDFF); // 高亮背景
  static const lightBorder = Color(0xFFCBD5E1);
  static const lightTextPrimary = Color(0xFF131B2E);
  static const lightTextSecondary = Color(0xFF475569);
  static const lightTextTertiary = Color(0xFF64748B);

  // 暗色中性色
  static const darkBg = Color(0xFF0B1220);
  static const darkSurface = Color(0xFF111827);
  static const darkSurfaceElevated = Color(0xFF1F2937);
  static const darkBorder = Color(0xFF334155);
  static const darkTextPrimary = Color(0xFFE5E7EB);
  static const darkTextSecondary = Color(0xFF94A3B8);
}

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
      ],
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: LoginScreen(),
    );
  }

  /// 亮色主题
  ThemeData _buildLightTheme() {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.brandPrimary,
      primaryContainer: AppColors.brandPrimaryContainer,
      secondary: AppColors.brandSecondary,
      error: AppColors.error,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      onSurfaceVariant: AppColors.lightTextSecondary,
      surfaceContainerLowest: AppColors.lightSurface,
      surfaceContainerLow: AppColors.lightSurfaceLow,
      surfaceContainer: AppColors.lightSurfaceHigh,
      outline: AppColors.lightBorder,
    );

    final textTheme = GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.manrope(
        fontSize: 56, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary,
      ),
      displayMedium: GoogleFonts.manrope(
        fontSize: 45, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary,
      ),
      headlineLarge: GoogleFonts.manrope(
        fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary,
      ),
      headlineSmall: GoogleFonts.manrope(
        fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary,
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.lightTextPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.lightTextPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.lightTextPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.lightTextSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.lightTextTertiary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.lightTextPrimary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.lightTextSecondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w500,
        letterSpacing: 0.5, color: AppColors.lightTextTertiary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.lightBg,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: AppColors.brandPrimary, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: AppColors.lightTextSecondary,
          letterSpacing: 0.3,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14, color: AppColors.lightTextTertiary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }

  /// 暗色主题
  ThemeData _buildDarkTheme() {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.brandPrimaryAlt,
      primaryContainer: const Color(0xFF1A2B4A),
      secondary: AppColors.brandSecondary,
      error: AppColors.error,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkTextSecondary,
      surfaceContainerLowest: AppColors.darkSurface,
      surfaceContainerLow: AppColors.darkSurfaceElevated,
      surfaceContainer: const Color(0xFF283044),
      outline: AppColors.darkBorder,
    );

    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.manrope(
        fontSize: 56, fontWeight: FontWeight.w800, color: AppColors.darkTextPrimary,
      ),
      headlineLarge: GoogleFonts.manrope(
        fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary,
      ),
      headlineSmall: GoogleFonts.manrope(
        fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary,
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.darkTextPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.darkTextPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.darkTextSecondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w500,
        letterSpacing: 0.5, color: AppColors.darkTextSecondary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.darkBg,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.brandPrimaryAlt,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandPrimaryAlt,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: AppColors.brandPrimaryAlt, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: AppColors.darkTextSecondary, letterSpacing: 0.3,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14, color: AppColors.darkTextSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}
