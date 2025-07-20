import 'package:shared_preferences/shared_preferences.dart';

class AppStateService {
  static const String _appClosedKey = 'app_closed_properly';
  
  // Uygulama kapandığında çağrılacak metod
  static Future<void> markAppAsClosed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_appClosedKey, true);
      print('Uygulama düzgün şekilde kapandı olarak işaretlendi');
    } catch (e) {
      print('Uygulama durumu kaydedilirken hata: $e');
    }
  }
  
  // Uygulama başladığında çağrılacak metod
  static Future<bool> wasAppClosedProperly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasClosed = prefs.getBool(_appClosedKey) ?? false;
      
      // Temizle, böylece bir sonraki çağrıda false dönecek
      await prefs.setBool(_appClosedKey, false);
      
      return wasClosed;
    } catch (e) {
      print('Uygulama durumu kontrol edilirken hata: $e');
      return false;
    }
  }
}
