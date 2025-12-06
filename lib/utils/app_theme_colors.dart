import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';

class AppThemeColors {
  static const Color _kButtonColor = Color(0xFF5B8A94);
  static const Color _kPrimaryRed = Color(0xFFBC0805);
  static const Color _kLogoutRed = Color(0xFFE57373);
  static const Color _kFindRecipes = Color(0xFFAFB73D);
  static const Color _kOpenInventory = Color(0xFFD97D55);
  static const Color _kSavedRecipes = Color(0xFFF5CA59);
  
  // Light mode colors
  static const Color lightBackground = Colors.white;
  static const Color lightSurfaceColor = Colors.white;
  static const Color lightText = Colors.black;
  static const Color lightSubtleGray = Color(0xFFF5F5F5);
  static const Color lightSearchBorder = Color(0xFFF3F3F3);
  static const Color lightCardShadow = Color(0x33000000);
  
  // Dark mode colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkText = Color(0xFFE1E1E1);
  static const Color darkSubtleGray = Color(0xFF2A2A2A);
  static const Color darkSearchBorder = Color(0xFF3A3A3A);
  static const Color darkCardShadow = Color(0x33FFFFFF);
  
  static bool get isDarkMode => ThemeProvider().darkModeEnabled;
  
  // Helper methods to get colors based on theme
  static Color getBackgroundColor() => isDarkMode ? darkBackground : lightBackground;
  static Color getSurfaceColor() => isDarkMode ? darkSurfaceColor : lightSurfaceColor;
  static Color getTextColor() => isDarkMode ? darkText : lightText;
  static Color getSubtleGrayColor() => isDarkMode ? darkSubtleGray : lightSubtleGray;
  static Color getSearchBorderColor() => isDarkMode ? darkSearchBorder : lightSearchBorder;
  static Color getCardShadowColor() => isDarkMode ? darkCardShadow : lightCardShadow;
  
  // Primary color (same in both modes)
  static const Color buttonColor = _kButtonColor;
  static const Color primaryRed = _kPrimaryRed;
  static const Color logoutRed = _kLogoutRed;
  static const Color findRecipes = _kFindRecipes;
  static const Color openInventory = _kOpenInventory;
  static const Color savedRecipes = _kSavedRecipes;
}
