import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static final LocaleProvider _instance = LocaleProvider._internal();
  factory LocaleProvider() => _instance;
  LocaleProvider._internal();

  static const String _kSelectedLocaleKey = 'selected_locale';

  Locale? _locale;
  Locale? get locale => _locale;

  /// A simple ValueNotifier to allow widgets to listen without provider package
  final ValueNotifier<Locale?> localeNotifier = ValueNotifier<Locale?>(null);

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_kSelectedLocaleKey);
      if (code != null && code.isNotEmpty) {
        _locale = Locale(code);
        localeNotifier.value = _locale;
        notifyListeners();
      }
    } catch (e) {
      // ignore errors and stay with default locale
      print('LocaleProvider initialize error: $e');
    }
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    localeNotifier.value = _locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(_kSelectedLocaleKey);
      } else {
        await prefs.setString(_kSelectedLocaleKey, locale.languageCode);
      }
    } catch (e) {
      print('LocaleProvider save error: $e');
    }
  }
}
