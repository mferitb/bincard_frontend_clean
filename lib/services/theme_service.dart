import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _textScaleKey = 'textScale';

  double _textScale = 1.0;
  bool _isInitialized = false;

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
      _textScale = prefs.getDouble(_textScaleKey) ?? 1.0;
    } catch (e) {
      // Hata durumunda varsayılan değerleri kullan
      _textScale = 1.0;
      debugPrint('ThemeService yüklenirken hata oluştu: $e');
    }
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
      await prefs.setDouble(_textScaleKey, _textScale);
    } catch (e) {
      debugPrint('Tema ayarları kaydedilirken hata oluştu: $e');
    }
  }

  // Tema servisini başlatmak için public metod
  Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadSettings();
    _isInitialized = true;
    notifyListeners();
  }
}
