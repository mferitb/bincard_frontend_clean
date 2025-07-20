import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selectedLanguage';

  String _selectedLanguage = 'Türkçe';
  final List<String> _availableLanguages = ['Türkçe', 'English'];
  bool _isInitialized = false;

  String get selectedLanguage => _selectedLanguage;
  List<String> get availableLanguages => _availableLanguages;
  bool get isInitialized => _isInitialized;

  LanguageService() {
    _initSettings();
  }

  Future<void> _initSettings() async {
    await _loadSettings();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedLanguage = prefs.getString(_languageKey) ?? 'Türkçe';
    } catch (e) {
      _selectedLanguage = 'Türkçe';
      debugPrint('LanguageService yüklenirken hata oluştu: $e');
    }
  }

  Future<void> setLanguage(String language) async {
    if (!_availableLanguages.contains(language) ||
        _selectedLanguage == language) {
      return;
    }

    _selectedLanguage = language;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, _selectedLanguage);
    } catch (e) {
      debugPrint('Dil ayarları kaydedilirken hata oluştu: $e');
    }
  }

  Locale get locale {
    switch (_selectedLanguage) {
      case 'English':
        return const Locale('en', 'US');
      case 'Türkçe':
      default:
        return const Locale('tr', 'TR');
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _loadSettings();
    
    _isInitialized = true;
    notifyListeners();
  }
}
