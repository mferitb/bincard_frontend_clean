import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'secure_storage_service.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecureStorageService _secureStorage = SecureStorageService();

  // Singleton pattern
  static final BiometricService _instance = BiometricService._internal();
  
  factory BiometricService() {
    return _instance;
  }
  
  BiometricService._internal();

  // Cihazın biyometrik kimlik doğrulama özelliklerini kontrol eder
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException catch (e) {
      debugPrint('Biyometrik kontrol hatası: $e');
      return false;
    }
  }

  // Kullanılabilir biyometrik kimlik doğrulama türlerini getirir
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();
      // Tüm biyometrik türleri döndür (yüz tanıma dahil)
      return biometrics;
    } on PlatformException catch (e) {
      debugPrint('Biyometrik tür getirme hatası: $e');
      return [];
    }
  }

  // Cihazın biyometrik doğrulama yapabilir olup olmadığını kontrol et
  Future<bool> canAuthenticate() async {
    try {
      // Cihaz biyometrik doğrulamayı destekliyor mu?
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) {
        debugPrint("Cihaz biyometrik doğrulamayı desteklemiyor");
        return false;
      }

      // Biyometrik doğrulama için kayıtlı bir kimlik var mı?
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        debugPrint("Biyometrik doğrulama için kayıtlı kimlik bulunamadı");
        return false;
      }

      // Kullanılabilir biyometrik türlerini kontrol et
      final availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        debugPrint("Kullanılabilir biyometrik türü bulunamadı");
        return false;
      }
      
      // Kullanıcı biyometrik doğrulamayı etkinleştirmiş mi?
      final isBiometricEnabled = await _secureStorage.getBiometricEnabled();
      if (!isBiometricEnabled) {
        debugPrint("Kullanıcı biyometrik doğrulamayı etkinleştirmemiş");
        return false;
      }

      return true;
    } on PlatformException catch (e) {
      debugPrint('Biyometrik doğrulama kontrolü hatası: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Beklenmeyen hata: $e');
      return false;
    }
  }

  // Biyometrik kimlik doğrulama işlemini başlatır
  Future<bool> authenticate({
    String reason = 'Lütfen kimliğinizi doğrulayın',
    String description = 'Giriş yapmak için biyometrik doğrulama kullanın',
  }) async {
    try {
      debugPrint('Biyometrik doğrulama başlatılıyor...');
      debugPrint('Reason: $reason');
      debugPrint('Description: $description');
      
      // Önce cihazın ve kullanıcının biyometrik doğrulama yapabildiğini kontrol et
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        debugPrint('Cihaz biyometrik doğrulamayı desteklemiyor');
        return false;
      }
      
      final isBiometricEnabled = await _secureStorage.getBiometricEnabled();
      if (!isBiometricEnabled) {
        debugPrint('Kullanıcı biyometrik doğrulamayı etkinleştirmemiş');
        return false;
      }
      
      // Kullanılabilir biyometrik türlerini kontrol et (yüz tanıma hariç)
      final availableBiometrics = await getAvailableBiometrics();
      debugPrint('Kullanılabilir biyometrik türleri: $availableBiometrics');
      
      if (availableBiometrics.isEmpty) {
        debugPrint('Cihazda kayıtlı biyometrik veri bulunamadı veya sadece yüz tanıma mevcut');
        return false;
      }
      
      // Biyometrik doğrulama yap
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true, // Uygulama arka plana alındığında doğrulamayı sürdür
          biometricOnly: true, // Sadece biyometrik doğrulama (PIN/şifre değil)
          useErrorDialogs: true, // Hata durumunda sistem diyaloglarını göster
        ),
      );
      
      debugPrint("Biyometrik doğrulama sonucu: $authenticated");
      return authenticated;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        debugPrint('Biyometrik doğrulama kullanılamıyor: ${e.message}');
      } else if (e.code == auth_error.notEnrolled) {
        debugPrint('Biyometrik kimlik kaydedilmemiş: ${e.message}');
      } else if (e.code == auth_error.lockedOut) {
        debugPrint('Çok fazla başarısız deneme nedeniyle kilitlendi: ${e.message}');
      } else if (e.code == auth_error.permanentlyLockedOut) {
        debugPrint('Cihaz kalıcı olarak kilitlendi, PIN/şifre gerekiyor: ${e.message}');
      } else {
        debugPrint('Biyometrik doğrulama hatası (${e.code}): ${e.message}');
      }
      return false;
    } catch (e) {
      debugPrint('Biyometrik doğrulama sırasında beklenmeyen hata: $e');
      return false;
    }
  }

  // Yüz tanıma özelliği var mı?
  Future<bool> hasFaceID() async {
    // Yüz tanıma devre dışı bırakıldı
    return false;
  }

  // Parmak izi özelliği var mı?
  Future<bool> hasFingerprint() async {
    final availableBiometrics = await getAvailableBiometrics();
    return availableBiometrics.contains(BiometricType.fingerprint) ||
        availableBiometrics.contains(BiometricType.strong);
  }

  // Biyometrik doğrulama için kullanıcıdan izin iste ve etkinleştir
  Future<bool> enableBiometricAuthentication() async {
    try {
      // Cihaz biyometrik doğrulamayı destekliyor mu?
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) {
        return false;
      }

      // Biyometrik doğrulama için kayıtlı bir kimlik var mı?
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        return false;
      }

      // Kullanılabilir biyometrik türlerini kontrol et (yüz tanıma dahil)
      final availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        debugPrint("Sadece parmak izi kullanılabilir, yüz tanıma devre dışı");
        // Eğer sadece yüz tanıma varsa ve başka biyometrik yöntem yoksa, false döndür
        final allBiometrics = await _localAuth.getAvailableBiometrics();
        if (allBiometrics.contains(BiometricType.face) && availableBiometrics.isEmpty) {
          debugPrint("Sadece yüz tanıma mevcut, biyometrik doğrulama etkinleştirilemiyor");
          return false;
        }
      }

      // Kullanıcı tercihi kaydet
      await _secureStorage.setBiometricEnabled(true);
      final enabled = await _secureStorage.getBiometricEnabled();
      debugPrint('Biyometrik ayarı kaydedildi: $enabled');
      return true;
    } catch (e) {
      debugPrint('Biyometrik izin hatası: $e');
      return false;
    }
  }

  // Biyometrik doğrulama tercihini devre dışı bırak
  Future<void> disableBiometricAuthentication() async {
    await _secureStorage.setBiometricEnabled(false);
    final enabled = await _secureStorage.getBiometricEnabled();
    debugPrint('Biyometrik ayarı devre dışı bırakıldı: $enabled');
  }

  // Biyometrik doğrulama etkin mi?
  Future<bool> isBiometricEnabled() async {
    return await _secureStorage.getBiometricEnabled();
  }

  // Cihazda herhangi bir biyometrik kayıt (yüz tanıma veya parmak izi) var mı?
  Future<bool> hasAnyBiometricEnrolled() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) return false;
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) return false;
      final biometrics = await getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (e) {
      debugPrint('Biyometrik kayıt kontrol hatası: $e');
      return false;
    }
  }
}
