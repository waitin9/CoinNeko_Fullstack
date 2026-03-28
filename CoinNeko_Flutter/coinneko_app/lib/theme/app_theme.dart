// frontend/lib/theme/app_theme.dart
// 完整還原 index.html 的 CSS 變數與樣式

import 'package:flutter/material.dart';

// ──────────────────────────────────────────────
// 色彩系統（對應 CSS :root 變數）
// ──────────────────────────────────────────────
class AppColors {
  // --bg: #FFF9F0
  static const Color bg = Color(0xFFFFF9F0);
  // --card: #FFFFFF
  static const Color card = Color(0xFFFFFFFF);
  // --purple: #7C5CBF
  static const Color purple = Color(0xFF7C5CBF);
  // --purple-light: #EDE8FA
  static const Color purpleLight = Color(0xFFEDE8FA);
  // --purple-dark: #5A3E9B
  static const Color purpleDark = Color(0xFF5A3E9B);
  // --gold: #F2A623
  static const Color gold = Color(0xFFF2A623);
  // --gold-light: #FFF3DC
  static const Color goldLight = Color(0xFFFFF3DC);
  // --green: #4CAF72
  static const Color green = Color(0xFF4CAF72);
  // --green-light: #E8F7EE
  static const Color greenLight = Color(0xFFE8F7EE);
  // --red: #E05C5C
  static const Color red = Color(0xFFE05C5C);
  // --red-light: #FDEAEA
  static const Color redLight = Color(0xFFFDEAEA);
  // --text: #2D2240
  static const Color text = Color(0xFF2D2240);
  // --text-sub: #7A6E8A
  static const Color textSub = Color(0xFF7A6E8A);
  // --border: #EDE8FA
  static const Color border = Color(0xFFEDE8FA);

  // Rarity colors
  static const Color rarityCommonBg = Color(0xFFEEEEEE);
  static const Color rarityCommonText = Color(0xFF888888);
  static const Color rarityRareBg = Color(0xFFDCE8FA);
  static const Color rarityRareText = Color(0xFF185FA5);
  static const Color rarityEpicBg = Color(0xFFEDE8FA);
  static const Color rarityEpicText = Color(0xFF7C5CBF);
  static const Color rarityLegendaryBg = Color(0xFFFFF3DC);
  static const Color rarityLegendaryText = Color(0xFF8A5E00);
}

// ──────────────────────────────────────────────
// 陰影（對應 --shadow: 0 4px 20px rgba(124,92,191,0.08)）
// ──────────────────────────────────────────────
class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x147C5CBF),   // rgba(124,92,191,0.08)
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x257C5CBF),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}

// ──────────────────────────────────────────────
// 圓角（對應 --radius: 16px）
// ──────────────────────────────────────────────
class AppRadius {
  static const double card = 16.0;
  static const double button = 12.0;
  static const double badge = 20.0;
  static const double input = 10.0;
  static const double catCard = 14.0;
  static const double modal = 20.0;
}

// ──────────────────────────────────────────────
// TextStyle 系統
// ──────────────────────────────────────────────
class AppTextStyles {
  // 標題用 Nunito（font-weight: 800/900）
  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  // stat-value (28px font-weight: 800)
  static const TextStyle statValue = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 28,
    fontWeight: FontWeight.w800,
  );

  // 一般文字
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSub,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textSub,
    letterSpacing: 0.8,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const TextStyle catName = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );
}

// ──────────────────────────────────────────────
// 主題設定
// ──────────────────────────────────────────────
class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        background: AppColors.bg,
        primary: AppColors.purple,
        secondary: AppColors.gold,
        error: AppColors.red,
      ),
      fontFamily: 'NotoSansTC',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.purple, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: const TextStyle(color: AppColors.textSub, fontWeight: FontWeight.w700, fontSize: 13),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.purple,
        unselectedItemColor: AppColors.textSub,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 稀有度工具
// ──────────────────────────────────────────────
class RarityHelper {
  static String label(String rarity) {
    const map = {
      'common': '普通',
      'rare': '稀有',
      'epic': '史詩',
      'legendary': '傳說',
    };
    return map[rarity] ?? rarity;
  }

  static Color bgColor(String rarity) {
    switch (rarity) {
      case 'rare': return AppColors.rarityRareBg;
      case 'epic': return AppColors.rarityEpicBg;
      case 'legendary': return AppColors.rarityLegendaryBg;
      default: return AppColors.rarityCommonBg;
    }
  }

  static Color textColor(String rarity) {
    switch (rarity) {
      case 'rare': return AppColors.rarityRareText;
      case 'epic': return AppColors.rarityEpicText;
      case 'legendary': return AppColors.rarityLegendaryText;
      default: return AppColors.rarityCommonText;
    }
  }

  static List<Color> cardGradient(String rarity) {
    switch (rarity) {
      case 'legendary':
        return [const Color(0xFFFFF3DC), const Color(0xFFFFE4A0)];
      case 'epic':
        return [const Color(0xFFEDE8FA), const Color(0xFFD6C8F5)];
      case 'rare':
        return [const Color(0xFFDCE8FA), const Color(0xFFBDD0F5)];
      default:
        return [Colors.white, const Color(0xFFF5F5F5)];
    }
  }
}