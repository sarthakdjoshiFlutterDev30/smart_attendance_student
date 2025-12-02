import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePersistenceProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  Future<void> loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[prefs.getInt('themePreference') ?? 0];
    notifyListeners();
  }

  Future<void> saveTheme(ThemeMode themeMode) async {
    _themeMode = themeMode;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themePreference', themeMode.index);
  }
}
