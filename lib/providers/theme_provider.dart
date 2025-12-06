import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static final ThemeProvider _instance = ThemeProvider._internal();
  static SharedPreferences? _prefs;
  
  factory ThemeProvider() {
    return _instance;
  }
  
  ThemeProvider._internal();
  
  bool _darkModeEnabled = false;
  bool _isInitialized = false;
  
  bool get darkModeEnabled => _darkModeEnabled;
  bool get isInitialized => _isInitialized;
  
  // Initialize SharedPreferences and load saved preference
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _prefs ??= await SharedPreferences.getInstance();
      _darkModeEnabled = _prefs?.getBool('darkModeEnabled') ?? false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing ThemeProvider: $e');
      _isInitialized = true;
    }
  }
  
  // Toggle dark mode and save preference
  Future<void> toggleDarkMode(bool value) async {
    _darkModeEnabled = value;
    notifyListeners();
    
    try {
      if (_prefs != null) {
        await _prefs!.setBool('darkModeEnabled', value);
      }
    } catch (e) {
      print('Error saving dark mode preference: $e');
    }
  }
  
  // Set dark mode and save preference
  Future<void> setDarkMode(bool value) async {
    _darkModeEnabled = value;
    notifyListeners();
    
    try {
      if (_prefs != null) {
        await _prefs!.setBool('darkModeEnabled', value);
      }
    } catch (e) {
      print('Error saving dark mode preference: $e');
    }
  }
}
