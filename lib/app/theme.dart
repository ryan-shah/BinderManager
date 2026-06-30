import 'package:flutter/material.dart';

// -- Neutral palette (warm gray, yellow-brown undertone) --

abstract final class AppColors {
  static const neutral950 = Color(0xFF22211D);
  static const neutral900 = Color(0xFF2A2820);
  static const neutral800 = Color(0xFF36352F);
  static const neutral700 = Color(0xFF3A382F);
  static const neutral600 = Color(0xFF6B6862);
  static const neutral500 = Color(0xFF8A877E);
  static const neutral400 = Color(0xFF9A978D);
  static const neutral350 = Color(0xFFB3B0A8);
  static const neutral300 = Color(0xFFBDBAB2);
  static const neutral250 = Color(0xFFCFCCC2);
  static const neutral200 = Color(0xFFD8D6CD);
  static const neutral150 = Color(0xFFE6E4DC);
  static const neutral100 = Color(0xFFECECEA);
  static const neutral75 = Color(0xFFF1EFE9);
  static const neutral50 = Color(0xFFFAF9F6);
  static const neutral0 = Color(0xFFFFFFFF);

  // Amber (warnings, staleness)
  static const amberBg = Color(0xFFF6F1E3);
  static const amberBorder = Color(0xFFE8E0C9);
  static const amberText = Color(0xFF7A6A3A);
  static const amberDot = Color(0xFFCAA44E);
  static const amberBtnBorder = Color(0xFFD8CAA0);

  // Semantic status
  static const statusAddText = Color(0xFF1F5A33);
  static const statusAddBg = Color(0xFFEEF5EF);
  static const statusAddBorder = Color(0xFFCFE3D4);
  static const statusRemoveText = Color(0xFF7A2F1F);
  static const statusRemoveBg = Color(0xFFF6EDEA);
  static const statusRemoveBorder = Color(0xFFE6CABF);
  static const statusMoveBg = Color(0xFFF1EFE9);
  static const statusMoveBorder = Color(0xFFDDD9CF);

  // Foil
  static const foilText = Color(0xFFCAA44E);
}

// -- WUBRG + Colorless + Multicolor mana pip colors --

class ManaPipColor {
  const ManaPipColor(this.background, this.border, this.text);
  final Color background;
  final Color border;
  final Color text;
}

abstract final class ManaPips {
  static const w = ManaPipColor(Color(0xFFF0EAD0), Color(0xFFCDBF86), Color(0xFF6B5E2E));
  static const u = ManaPipColor(Color(0xFFBCDCEF), Color(0xFF6FA8CF), Color(0xFF1F5A7A));
  static const b = ManaPipColor(Color(0xFFC3BDB6), Color(0xFF847C72), Color(0xFF2C2722));
  static const r = ManaPipColor(Color(0xFFF0B3A2), Color(0xFFCF7F6A), Color(0xFF7A2F1F));
  static const g = ManaPipColor(Color(0xFFAED7B9), Color(0xFF6FAE84), Color(0xFF1F5A33));
  static const c = ManaPipColor(Color(0xFFD9D4CD), Color(0xFFA39C91), Color(0xFF5A544B));
  static const m = ManaPipColor(Color(0xFFE8D5A3), Color(0xFFC4A44E), Color(0xFF7A6A3A));

  static const all = [w, u, b, r, g, c, m];
  static const labels = ['W', 'U', 'B', 'R', 'G', 'C', 'M'];
}

// -- Binder skeuomorphic tokens --

abstract final class BinderColors {
  static const surround = Color(0xFFD8D4CA);
  static const surroundBorder = Color(0xFFC9C4B8);
  static const page = Color(0xFFFBFAF6);
  static const pageBorder = Color(0xFFD4D0C6);
  static const spineLight = Color(0xFFCFCABF);
  static const spineMid = Color(0xFFBDB8AC);
  static const ringBorder = Color(0xFFEFECE4);
  static const ringFill = Color(0xFFA8A296);

  // Pocket cell states
  static const pocketBorder = Color(0xFFC7C5BD);
  static const pocketStripe1 = Color(0xFFECEAE4);
  static const pocketStripe2 = Color(0xFFE4E2DA);
  static const pocketEmptyBorder = Color(0xFFCFCCC2);
  static const pocketEmptyBg = Color(0xFFF7F6F2);
  static const pocketGhostBorder = Color(0xFFB9B6AD);
  static const pocketGhostBg = Color(0xFFF4F3EF);
  static const pocketHatchedStripe1 = Color(0xFFE3E0D6);
  static const pocketHatchedStripe2 = Color(0xFFCFCCC2);
  static const pocketMoveBorder = Color(0xFF9A978D);
}

// -- Spacing --

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

// -- Border radii --

abstract final class AppRadii {
  static const double xs = 3;
  static const double sm = 5;
  static const double md = 7;
  static const double lg = 9;
  static const double xl = 10;
  static const double xxl = 14;
}

// -- Shadows --

abstract final class AppShadows {
  static const card = BoxShadow(
    offset: Offset(0, 1),
    blurRadius: 3,
    color: Color(0x14000000),
  );
  static const drag = BoxShadow(
    offset: Offset(0, 6),
    blurRadius: 16,
    color: Color(0x1F000000),
  );
  static const modal = BoxShadow(
    offset: Offset(0, 10),
    blurRadius: 30,
    color: Color(0x29000000),
  );
  static const fab = BoxShadow(
    offset: Offset(0, 4),
    blurRadius: 12,
    color: Color(0x40000000),
  );
}

// -- Typography --

abstract final class AppTypography {
  static const _content = 'Helvetica Neue';
  static const _contentFallback = [
    'Helvetica',
    'Arial',
  ];
  static const _mono = 'ui-monospace';
  static const _monoFallback = ['monospace'];

  // Content voice (Helvetica)
  static final display = TextStyle(
    fontFamily: _content,
    fontFamilyFallback: _contentFallback,
    fontSize: 38,
    fontWeight: FontWeight.w700,
    color: AppColors.neutral900,
  );
  static final headingXl = TextStyle(
    fontFamily: _content,
    fontFamilyFallback: _contentFallback,
    fontSize: 21,
    fontWeight: FontWeight.w700,
    color: AppColors.neutral900,
  );
  static final headingLg = TextStyle(
    fontFamily: _content,
    fontFamilyFallback: _contentFallback,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.neutral900,
  );
  static final headingMd = TextStyle(
    fontFamily: _content,
    fontFamilyFallback: _contentFallback,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.neutral900,
  );
  static final headingSm = TextStyle(
    fontFamily: _content,
    fontFamilyFallback: _contentFallback,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.neutral900,
  );
  static final headingXs = TextStyle(
    fontFamily: _content,
    fontFamilyFallback: _contentFallback,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.neutral900,
  );
  static final body = TextStyle(
    fontFamily: _content,
    fontFamilyFallback: _contentFallback,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral700,
  );
  static final bodySm = TextStyle(
    fontFamily: _content,
    fontFamilyFallback: _contentFallback,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.neutral700,
  );
  static final bodyXs = TextStyle(
    fontFamily: _content,
    fontFamilyFallback: _contentFallback,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.neutral500,
  );
  static final buttonLg = TextStyle(
    fontFamily: _content,
    fontFamilyFallback: _contentFallback,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral0,
  );
  static final button = TextStyle(
    fontFamily: _content,
    fontFamilyFallback: _contentFallback,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral0,
  );
  static final buttonSm = TextStyle(
    fontFamily: _content,
    fontFamilyFallback: _contentFallback,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral0,
  );

  // System voice (monospace)
  static final sectionLabel = TextStyle(
    fontFamily: _mono,
    fontFamilyFallback: _monoFallback,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.66,
    color: AppColors.neutral500,
  );
  static final meta = TextStyle(
    fontFamily: _mono,
    fontFamilyFallback: _monoFallback,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.neutral500,
  );
  static final query = TextStyle(
    fontFamily: _mono,
    fontFamilyFallback: _monoFallback,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.neutral700,
  );
  static final statLabel = TextStyle(
    fontFamily: _mono,
    fontFamilyFallback: _monoFallback,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: AppColors.neutral500,
  );
  static final tag = TextStyle(
    fontFamily: _mono,
    fontFamilyFallback: _monoFallback,
    fontSize: 9,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.36,
    color: AppColors.neutral600,
  );
  static final badge = TextStyle(
    fontFamily: _mono,
    fontFamilyFallback: _monoFallback,
    fontSize: 9,
    fontWeight: FontWeight.w700,
    color: AppColors.neutral600,
  );
  static final pipText = TextStyle(
    fontFamily: _mono,
    fontFamilyFallback: _monoFallback,
    fontSize: 9,
    fontWeight: FontWeight.w700,
  );
}

// -- Responsive breakpoint --

const double kDesktopBreakpoint = 808;

// -- Theme builder --

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.neutral0,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.neutral900,
      surface: AppColors.neutral0,
      onSurface: AppColors.neutral900,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.neutral0,
      foregroundColor: AppColors.neutral900,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppTypography.headingMd,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.neutral100,
      thickness: 1,
      space: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.neutral0,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        side: const BorderSide(color: AppColors.neutral100),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.neutral900,
        foregroundColor: AppColors.neutral0,
        textStyle: AppTypography.button,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.neutral700,
        textStyle: AppTypography.button,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        side: const BorderSide(color: AppColors.neutral200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.neutral50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        borderSide: const BorderSide(color: AppColors.neutral200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        borderSide: const BorderSide(color: AppColors.neutral200),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      hintStyle: AppTypography.body.copyWith(color: AppColors.neutral300),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.neutral950,
      selectedIconTheme: const IconThemeData(color: AppColors.neutral0),
      unselectedIconTheme: const IconThemeData(color: AppColors.neutral250),
      indicatorColor: AppColors.neutral800,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.neutral0,
      selectedItemColor: AppColors.neutral900,
      unselectedItemColor: AppColors.neutral400,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
