import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService instance = LanguageService._init();
  LanguageService._init();

  Locale _locale = const Locale('sw');
  Locale get locale => _locale;

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('language_code') ?? 'sw';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    _locale = Locale(languageCode);
    notifyListeners();
  }

  bool get isSwahili => _locale.languageCode == 'sw';
  bool get isEnglish => _locale.languageCode == 'en';
}
