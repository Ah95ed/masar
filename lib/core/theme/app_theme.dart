import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// الهوية البصرية الرسمية المطابقة للوحة تحكم الموقع Just_admin (CSS: app.css)
class AppTheme {
  AppTheme._();

  // ألوان المنظومة الرسمية المستخرجة من Just_admin/assets/css/app.css
  static const Color ink = Color(0xFF102B3F);        // --ink: اللون الكحلي الليلي الأساسي
  static const Color inkSoft = Color(0xFF193E54);    // --ink-soft: كحلي ناعم للهيدر والبطاقات
  static const Color cyan = Color(0xFF078DA5);       // --cyan: أزرق مائي ترند رئيسي
  static const Color cyanPale = Color(0xFFE7F5F6);   // --cyan-pale
  static const Color green = Color(0xFF13805D);      // --green: أخضر مالي واعتمادات
  static const Color greenPale = Color(0xFFE6F5ED);  // --green-pale
  static const Color amber = Color(0xFFB76B08);      // --amber: كهرماني للآليات والصيانة
  static const Color amberPale = Color(0xFFFFF3DD);  // --amber-pale
  static const Color red = Color(0xFFBD3F42);        // --red: أحمر للتقارير المعلقة والحذف
  static const Color redPale = Color(0xFFFAE9E9);    // --red-pale
  static const Color paper = Color(0xFFF4F7F8);      // --paper: خلفية الصفحات العامة
  static const Color line = Color(0xFFDCE5E8);       // --line: الحدود والفواصل
  static const Color muted = Color(0xFF647782);      // --muted: النصوص الثانوية والرمادية
  static const Color white = Colors.white;           // --white

  // توافق مع الرموز المستعملة في التطبيق
  static const Color primaryColor = ink;
  static const Color primaryLight = inkSoft;
  static const Color primaryDark = Color(0xFF0B1E2D);
  static const Color accentColor = cyan;
  static const Color accentLight = cyanPale;
  static const Color backgroundColor = paper;
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;

  static const Color textPrimary = Color(0xFF203642); // لون نص الموقع الرسمي
  static const Color textSecondary = muted;
  static const Color textMuted = Color(0xFF8A9BA3);

  static const Color successColor = green;
  static const Color warningColor = amber;
  static const Color dangerColor = red;
  static const Color infoColor = cyan;

  static ThemeData get lightTheme {
    final cairoFont = GoogleFonts.cairo().fontFamily;

    return ThemeData(
      useMaterial3: true,
      fontFamily: cairoFont,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ink,
        primary: ink,
        secondary: cyan,
        surface: surfaceColor,
        error: red,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: paper,
      tabBarTheme: TabBarThemeData(
        indicatorColor: cyan,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFFCBD5E1),
        labelStyle: TextStyle(
          fontFamily: cairoFont,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: cairoFont,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ink,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: cairoFont,
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: line, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: TextStyle(
            fontFamily: cairoFont,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: line, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: TextStyle(
            fontFamily: cairoFont,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: cyan, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: red, width: 1.4),
        ),
        labelStyle: const TextStyle(color: muted, fontSize: 13),
        hintStyle: const TextStyle(color: textMuted, fontSize: 12),
      ),
      dividerTheme: const DividerThemeData(
        color: line,
        thickness: 1,
        space: 20,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: cyan,
        unselectedItemColor: muted,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontFamily: cairoFont, fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontFamily: cairoFont, fontSize: 11),
      ),
    );
  }
}
