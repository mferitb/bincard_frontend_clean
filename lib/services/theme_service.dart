import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _isDarkModeKey = 'isDarkMode';
  static const String _textScaleKey = 'textScale';

  bool _isDarkMode = false;
  double _textScale = 1.0;
  bool _isInitialized = false;

  bool get isDarkMode => _isDarkMode;
  double get textScale => _textScale;
  bool get isInitialized => _isInitialized;

  ThemeService() {
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
      _isDarkMode = prefs.getBool(_isDarkModeKey) ?? false;
      _textScale = prefs.getDouble(_textScaleKey) ?? 1.0;
    } catch (e) {
      // Hata durumunda varsayılan değerleri kullan
      _isDarkMode = false;
      _textScale = 1.0;
      debugPrint('ThemeService yüklenirken hata oluştu: $e');
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return; // Değer aynıysa işlem yapma

    _isDarkMode = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    if (_textScale == value) return; // Değer aynıysa işlem yapma

    _textScale = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isDarkModeKey, _isDarkMode);
      await prefs.setDouble(_textScaleKey, _textScale);
    } catch (e) {
      debugPrint('Tema ayarları kaydedilirken hata oluştu: $e');
    }
  }

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Tema servisini başlatmak için public metod
  Future<void> initialize() async {
    // Eğer zaten başlatılmışsa, işlem yapma
    if (_isInitialized) return;
    
    // Ayarları yükle
    await _loadSettings();
    
    // Başlatıldı olarak işaretle
    _isInitialized = true;
    notifyListeners();
  }
}
