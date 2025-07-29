import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_model.dart';
import '../models/refresh_login_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as Math;
import 'api_service.dart';
import 'secure_storage_service.dart';
import 'token_service.dart';
import 'biometric_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/widgets.dart';
import '../main.dart'; // navigatorKey için import
import '../constants/api_constants.dart';
import '../routes.dart'; // AppRoutes için import
import 'notification_service.dart';
import 'fcm_token_service.dart';
import 'package:provider/provider.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final SecureStorageService _secureStorage = SecureStorageService();
  final TokenService _tokenService = TokenService();
  final BiometricService _biometricService = BiometricService();

  // SharedPreferences Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  // Kullanıcı adı ve şifre ile giriş (YENİ BACKEND)
  Future<TokenResponseDTO> login(String phone, String password) async {
    try {
      debugPrint('Login isteği gönderiliyor: $phone');
      final deviceInfo = await getDeviceInfo();
      final ipAddress = await getIpAddress();
      final appVersion = await getAppVersion();
      final platform = getPlatform();

      final response = await _apiService.post(
        ApiConstants.loginEndpoint,
        data: {
          'telephone': phone,
          'password': password,
          'deviceInfo': deviceInfo,
          'ipAddress': ipAddress,
          'appVersion': appVersion,
          'platform': platform,
        },
        useLoginDio: true,
      );

      if (response.statusCode == 200 && response.data != null) {
        // Yeni cihaz algılandı durumu kontrolü
        if (response.data['success'] == false && 
            response.data['message'] == "Yeni cihaz algılandı. Giriş için doğrulama kodu gönderildi.") {
          // SMS doğrulama ekranına yönlendirmek için özel bir exception fırlat
          throw Exception("SMS_VERIFICATION_REQUIRED");
        }
        
        // accessToken veya refreshToken yoksa hata mesajı göster
        if (response.data['accessToken'] == null || response.data['refreshToken'] == null) {
          final message = response.data['message'] ?? 'Giriş başarısız oldu.';
          throw Exception(message);
        }
        final tokenResponse = TokenResponseDTO.fromJson(response.data);
        // Token'ları güvenli depolamaya kaydet
        await _secureStorage.setAccessToken(tokenResponse.accessToken.token);
        await _secureStorage.setRefreshToken(tokenResponse.refreshToken.token);
        await _secureStorage.setAccessTokenExpiry(tokenResponse.accessToken.expiredAt.toIso8601String());
        await _secureStorage.setRefreshTokenExpiry(tokenResponse.refreshToken.expiredAt.toIso8601String());
        
        // Save phone number to secure storage
        await _secureStorage.setUserPhone(phone);
        debugPrint('Saved phone number to secure storage: $phone');
        
        // Log the tokens
        final savedAccessToken = await _secureStorage.getAccessToken();
        final savedRefreshToken = await _secureStorage.getRefreshToken();
        debugPrint('Saved Access Token: ${savedAccessToken != null ? savedAccessToken.substring(0, Math.min(10, savedAccessToken.length))+'...' : 'null'}');
        debugPrint('Saved Refresh Token: ${savedRefreshToken != null ? savedRefreshToken.substring(0, Math.min(10, savedRefreshToken.length))+'...' : 'null'}');
        
        // Kullanıcı bilgilerini kaydet (eğer yanıtta varsa)
        if (response.data.containsKey('user')) {
          await _saveUserInfo(response.data['user']);
        }
        
        // Token interceptor'ı etkinleştir
        _apiService.setupTokenInterceptor();
        // Biyometrik izin sor
        await _askForBiometricPermission();
        // FCM tokenı API'ye gönder
        try {
          final fcmTokenService = FcmTokenService();
          final fcmToken = fcmTokenService.token;
          if (fcmToken != null) {
            await NotificationService().sendFcmTokenToApi(fcmToken);
          }
        } catch (e) {
          debugPrint('Login sonrası FCM token gönderilemedi: $e');
        }
        return tokenResponse;
      } else {
        final message = response.data?['message'] ?? 'Giriş başarısız oldu.';
        debugPrint('Login başarısız: $message');
        throw Exception(message);
      }
    } on DioException catch (e) {
      debugPrint('Login DioException: \\${e.message}');
      debugPrint('Response data: \\${e.response?.data}');
      throw Exception(e.response?.data?['message'] ?? 'Giriş başarısız oldu');
    } catch (e) {
      debugPrint('Login beklenmeyen hata: $e');
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  // Biyometrik doğrulama ile giriş
  Future<bool> loginWithBiometrics() async {
    try {
      debugPrint('Biyometrik giriş süreci başlatılıyor...');
      
      // Enhanced biometric authentication check
      final canAuthenticate = await _biometricService.canAuthenticateEnhanced();
      if (!canAuthenticate) {
        debugPrint('Biyometrik doğrulama kullanılamıyor veya etkinleştirilmemiş');
        return false;
      }
      
      // Refresh token var mı kontrol et
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        debugPrint('Kayıtlı refresh token bulunamadı, normal giriş gerekiyor');
        return false;
      }

      // Refresh token süresi kontrolü
      final refreshTokenExpiry = await _secureStorage.getRefreshTokenExpiry();
      if (refreshTokenExpiry != null) {
        final expiry = DateTime.parse(refreshTokenExpiry);
        final now = DateTime.now();
        
        if (now.isAfter(expiry)) {
          debugPrint('Refresh token süresi dolmuş, yeniden giriş yapmanız gerekiyor');
          return false;
        }
        
        debugPrint('Refresh token geçerli, süresi: $expiry');
      }
      
      // Enhanced biometric authentication
      debugPrint('Biyometrik doğrulama isteği gönderiliyor...');
      final isAuthenticated = await _biometricService.authenticateEnhanced(
        reason: 'Giriş yapmak için biyometrik doğrulama kullanın',
        description: 'Devam etmek için parmak izi kullanın',
      );
      
      if (!isAuthenticated) {
        debugPrint('Biyometrik doğrulama başarısız veya kullanıcı tarafından iptal edildi');
        return false;
      }
      
      debugPrint('Biyometrik doğrulama başarılı, refresh token ile yeni access token alınıyor');
      
      // Token servisini ve API servisini yapılandır
      _apiService.setupTokenInterceptor();
      
      // Biyometrik doğrulama başarılıysa, refresh token ile yeni access token al
      final refreshSuccess = await _tokenService.refreshAccessToken();
      
      if (refreshSuccess) {
        debugPrint('Token yenileme başarılı, giriş yapılıyor');
        return true;
      } else {
        debugPrint('Token yenileme başarısız, yeni access token alınamadı');
        
        // Access token ve refresh token'ı kontrol et
        final accessToken = await _secureStorage.getAccessToken();
        final refreshTokenAgain = await _secureStorage.getRefreshToken();
        
        if (accessToken != null && refreshTokenAgain != null) {
          debugPrint('Mevcut token bilgileri hala geçerli, giriş işlemi devam ediyor');
          return true;
        }
        
        debugPrint('Token bilgileri geçersiz, normal giriş gerekiyor');
        return false;
      }
    } catch (e) {
      debugPrint('Biyometrik giriş hatası: $e');
      return false;
    }
  }

  // Kayıt API isteği
  Future<ResponseMessage> register(
    String firstName,
    String lastName,
    String telephone,
    String password,
  ) async {
    try {
      final requestBody = {
        'firstName': firstName,
        'lastName': lastName,
        'telephone': telephone,
        'password': password,
      };

      final response = await http
          .post(
            Uri.parse(ApiConstants.baseUrl + ApiConstants.signUpEndpoint),
            headers: {'Content-Type': ApiConstants.contentType},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return ResponseMessage.fromJson(data);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return ResponseMessage.error(
          errorData['message'] ?? 'Kayıt başarısız. Lütfen tekrar deneyin.',
        );
      }
    } catch (e) {
      return ResponseMessage.error('Bağlantı hatası: $e');
    }
  }

  // Cihaz bilgisini al
  Future<String> getDeviceInfo() async {
    try {
      // Gerçek cihaz bilgilerini almak için device_info_plus paketi kullanılabilir
      // Bu örnekte basit bir bilgi döndürüyoruz
      final deviceModel = Platform.isAndroid ? 'Android Device' : 
                         Platform.isIOS ? 'iOS Device' : 'Unknown Device';
      final osVersion = Platform.operatingSystemVersion;
      return '$deviceModel ($osVersion)';
    } catch (e) {
      debugPrint('Cihaz bilgisi alınamadı: $e');
      return 'Unknown Device';
    }
  }

  // IP adresini al
  Future<String> getIpAddress() async {
    try {
      // Gerçek IP adresi almak için harici bir servis kullanılabilir
      final response = await http.get(Uri.parse(ApiConstants.ipifyUrl));
      if (response.statusCode == 200) {
        return response.body.trim();
      }
      return '192.168.1.100'; // Varsayılan değer
    } catch (e) {
      debugPrint('IP adresi alınamadı: $e');
      return '192.168.1.100';
    }
  }
  
  // Uygulama sürümünü al
  Future<String> getAppVersion() async {
    try {
      // Gerçek uygulamada package_info_plus paketi kullanılabilir
      // Bu örnekte sabit bir değer dönüyoruz
      return '1.0.0';
    } catch (e) {
      debugPrint('Uygulama sürümü alınamadı: $e');
      return '1.0.0';
    }
  }
  
  // Platform bilgisini al
  String getPlatform() {
    try {
      return Platform.operatingSystem;
    } catch (e) {
      debugPrint('Platform bilgisi alınamadı: $e');
      return 'unknown';
    }
  }

  // Token ve kullanıcı bilgilerini kaydet
  Future<void> saveAuthData(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();

    if (authResponse.token != null) {
      await prefs.setString(tokenKey, authResponse.token!);
    }

    if (authResponse.refreshToken != null) {
      await prefs.setString(refreshTokenKey, authResponse.refreshToken!);
    }

    if (authResponse.user != null) {
      final userData = jsonEncode({
        'id': authResponse.user!.id,
        'firstName': authResponse.user!.firstName,
        'lastName': authResponse.user!.lastName,
        'telephone': authResponse.user!.telephone,
        'email': authResponse.user!.email,
      });

      await prefs.setString(userKey, userData);
    }
  }

  // Token bilgisini al
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Kullanıcı bilgisini al
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(userKey);

    if (userData != null) {
      final Map<String, dynamic> userMap = jsonDecode(userData);
      return User.fromJson(userMap);
    }

    return null;
  }

  // Oturum kontrolü
  Future<bool> isLoggedIn() async {
    return await _tokenService.hasValidTokens();
  }

  // Çıkış yap
  Future<ResponseMessage> logout() async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      final refreshToken = await _secureStorage.getRefreshToken();
      
      debugPrint('Logout başlatılıyor, refresh token mevcut mu: ${refreshToken != null}');
      
      // Refresh token'ın varlığını ve geçerliliğini kontrol et
      bool refreshTokenValid = false;
      final refreshTokenExpiry = await _secureStorage.getRefreshTokenExpiry();
      
      if (refreshToken != null && refreshTokenExpiry != null) {
        final expiry = DateTime.parse(refreshTokenExpiry);
        refreshTokenValid = DateTime.now().isBefore(expiry);
        debugPrint('Refresh token geçerli mi: $refreshTokenValid, sona erme: $expiry');
      }
      
      // API'ye logout isteği atma - refresh token'ı korumak için
      // Backend'e logout isteği gönderilmiyor çünkü refresh token'ı silmemeli
      debugPrint('Frontend logout: Sadece access token temizleniyor, refresh token korunuyor');
      
      // Sadece access token'ı temizle, refresh token'ı koru
      await _secureStorage.clearAccessToken();
      
      // Check refresh token is still present
      final remainingToken = await _secureStorage.getRefreshToken();
      debugPrint('Logout sonrası refresh token durumu: ${remainingToken != null ? "Mevcut" : "Yok"}');
      
      // Hızlı giriş ekranına yönlendir
      if (refreshTokenValid && navigatorKey.currentContext != null) {
        Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
          AppRoutes.refreshLogin, (route) => false);
      }
      
      return ResponseMessage(
        success: true,
        message: refreshTokenValid 
          ? 'Çıkış yapıldı, oturum bilgileriniz korunuyor.'
          : 'Çıkış yapıldı, tekrar giriş yapmanız gerekecek.',
        data: {'refreshTokenValid': refreshTokenValid},
      );
    } catch (e) {
      // Hata olsa bile, sadece access token'ı temizle
      await _secureStorage.clearAccessToken();
      debugPrint('Logout hatası: $e');
      
      // Hızlı giriş ekranına yönlendir (hata olsa bile)
      if (navigatorKey.currentContext != null) {
        final refreshToken = await _secureStorage.getRefreshToken();
        if (refreshToken != null) {
          Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
            AppRoutes.refreshLogin, (route) => false);
        } else {
          Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
            AppRoutes.login, (route) => false);
        }
      }
      
      return ResponseMessage(
        success: true,
        message: 'Çıkış yapıldı.',
      );
    }
  }

  // Biyometrik doğrulama için izin iste
  Future<bool> _askForBiometricPermission() async {
    try {
      // Cihaz biyometrik doğrulamayı destekliyor mu?
      final isDeviceSupported = await _biometricService.isBiometricAvailable();
      if (!isDeviceSupported) {
        return false;
      }
      
      // Kullanıcı daha önce biyometrik doğrulamayı etkinleştirmiş mi?
      final isBiometricEnabled = await _biometricService.isBiometricEnabled();
      if (isBiometricEnabled) {
        return true; // Zaten etkinleştirilmiş
      }
      
      // Biyometrik doğrulamayı etkinleştir
      return await _biometricService.enableBiometricAuthentication();
    } catch (e) {
      debugPrint('Biyometrik izin hatası: $e');
      return false;
    }
  }

  // Biyometrik doğrulama kullanılabilir mi?
  Future<bool> canUseBiometricAuth() async {
    return await _biometricService.canAuthenticateEnhanced();
  }

  // Biyometrik doğrulamayı devre dışı bırak
  Future<void> disableBiometricAuth() async {
    await _biometricService.disableBiometricAuthentication();
  }

  // Re-enable biometric after successful password login
  Future<void> enableBiometricAfterSuccessfulLogin() async {
    await _biometricService.enableBiometricAfterSuccessfulLogin();
  }

  // Get biometric status for debugging
  Future<Map<String, dynamic>> getBiometricStatus() async {
    return await _biometricService.getBiometricStatusInfo();
  }

  // Kullanıcı bilgilerini API'den al
  Future<User?> getUserDetails() async {
    try {
      final response = await _apiService.get('/user/profile');
      
      if (response.statusCode == 200 && response.data != null) {
        return User.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Kullanıcı bilgileri getirme hatası: $e');
      return null;
    }
  }

  // Uygulama başlangıcında token kontrolü ve yenileme
  Future<bool> checkAndRefreshToken() async {
    try {
      // Refresh token kontrolü
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        debugPrint('Refresh token bulunamadı, yeniden giriş yapmanız gerekiyor');
        return false;
      }

      // Refresh token expiry kontrolü
      final refreshTokenExpiry = await _secureStorage.getRefreshTokenExpiry();
      if (refreshTokenExpiry != null) {
        final expiry = DateTime.parse(refreshTokenExpiry);
        final now = DateTime.now();
        
        if (now.isAfter(expiry)) {
          debugPrint('Refresh token süresi dolmuş, yeniden giriş yapmanız gerekiyor');
          return false;
        }
        
        debugPrint('Refresh token hala geçerli, süresi: $expiry');
      }

      // Access token kontrolü
      final isAboutToExpire = await _tokenService.isAccessTokenAboutToExpire();
      if (isAboutToExpire) {
        debugPrint('Access token süresi dolmuş veya dolmak üzere, yenileniyor...');
        
        // Token servisini kullanarak token yenileme
        final refreshed = await _tokenService.refreshAccessToken();
        if (!refreshed) {
          debugPrint('Token yenileme başarısız, yeniden giriş yapmanız gerekiyor');
          return false;
        }
        
        debugPrint('Token başarıyla yenilendi, oturum aktif');
      } else {
        debugPrint('Access token hala geçerli, yenileme gerekmiyor');
      }

      return true;
    } catch (e) {
      debugPrint('Token kontrolü ve yenileme hatası: $e');
      return false;
    }
  }

  // Token bilgilerini temizle (çıkış yap)
  Future<void> clearTokens() async {
    try {
      // Tüm yerel depolanmış verileri temizle
      await _secureStorage.clearAll();
      
      // Biyometrik ayarı sıfırla
      await _biometricService.disableBiometricAuthentication();
      
      debugPrint('Token bilgileri başarıyla temizlendi');
    } catch (e) {
      debugPrint('Token temizleme hatası: $e');
      // Hata olsa bile devam et, kullanıcı login sayfasına yönlendirilecek
      throw e;
    }
  }

  // Uygulama içinde token kontrolü ve geçersizse login sayfasına yönlendirme
  Future<bool> checkTokenAndRedirect() async {
    try {
      // Mevcut route kontrolü
      final currentRoute = getCurrentRoute();
      if (isTokenExemptRoute(currentRoute)) {
        debugPrint('Token kontrolünden muaf sayfa: $currentRoute, kontrol yapılmıyor');
        return true;
      }
      
      // Token servisinden token kontrolü yap
      final hasValidTokens = await _tokenService.hasValidTokens();
      
      if (!hasValidTokens) {
        // Sessizce token bilgilerini temizle
        await clearTokens();
        
        debugPrint('Token geçersiz, ancak otomatik yönlendirme yapılmıyor');
        return false;
      }
      
      return true;
    } catch (e) {
      // Hata durumunda da sessizce login sayfasına yönlendir
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorKey.currentContext != null) {
          Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });
      
      return false;
    }
  }

  // Telefon numarası doğrulama kodu kontrolü (TokenResponseDTO ile)
  Future<String> verifyPhoneNumber(int code) async {
    try {
      final response = await _apiService.post(
        '/user/verify/phone',
        data: {'code': code},
        useLoginDio: true,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data['success'] == true) {
          return response.data['message'] ?? 'Telefon numaranız başarıyla doğrulandı!';
        } else {
          final message = response.data['message'] ?? 'Doğrulama başarısız oldu.';
          throw Exception(message);
        }
      } else {
        final message = response.data?['message'] ?? 'Doğrulama başarısız oldu.';
        throw Exception(message);
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Bağlantı hatası');
    } catch (e) {
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  // Yeniden doğrulama kodu gönder
  Future<ResponseMessage> resendVerificationCode(String phoneNumber) async {
    try {
      debugPrint('Yeniden doğrulama kodu gönderiliyor: $phoneNumber');
      
      // Dio kullanarak istek gönder - daha güvenilir hata işleme için
      final response = await _apiService.post(
        ApiConstants.resendCodeEndpoint, // Doğru endpoint: /auth/resend-verify-code
        queryParameters: {'telephone': phoneNumber}, // Data yerine queryParameters kullan
        useLoginDio: true,
      );
      
      debugPrint('Doğrulama kodu yanıtı: ${response.statusCode} - ${response.data}');
      
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          return ResponseMessage.fromJson(response.data);
        } else {
          return ResponseMessage.success('Doğrulama kodu gönderildi');
        }
      } else {
        final message = response.data?['message'] ?? 'Kod gönderme işlemi başarısız oldu.';
        return ResponseMessage.error(message);
      }
    } on DioException catch (e) {
      debugPrint('Dio hatası: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      
      String errorMsg = 'Bağlantı hatası';
      if (e.response?.data != null && e.response?.data is Map) {
        errorMsg = e.response?.data['message'] ?? errorMsg;
      }
      return ResponseMessage.error(errorMsg);
    } catch (e) {
      debugPrint('Genel hata: $e');
      return ResponseMessage.error('Bağlantı hatası: $e');
    }
  }

  // Giriş başarılı olduğunda kullanıcı bilgilerini kaydet
  Future<void> _saveUserInfo(Map<String, dynamic> userData) async {
    try {
      debugPrint('Kullanıcı bilgileri kaydediliyor: $userData');
      
      // Kullanıcı bilgilerini kontrol et - farklı API formatlarını destekle
      if (userData.containsKey('firstName')) {
        await _secureStorage.setUserFirstName(userData['firstName']);
        debugPrint('Kullanıcı adı (firstName) kaydedildi: ${userData['firstName']}');
      } else if (userData.containsKey('name')) {
        await _secureStorage.setUserFirstName(userData['name']);
        debugPrint('Kullanıcı adı (name) kaydedildi: ${userData['name']}');
      }
      
      if (userData.containsKey('lastName')) {
        await _secureStorage.setUserLastName(userData['lastName']);
        debugPrint('Kullanıcı soyadı (lastName) kaydedildi: ${userData['lastName']}');
      } else if (userData.containsKey('surname')) {
        await _secureStorage.setUserLastName(userData['surname']);
        debugPrint('Kullanıcı soyadı (surname) kaydedildi: ${userData['surname']}');
      }
      
      // Telefon numarasını da kaydet
      if (userData.containsKey('telephone')) {
        await _secureStorage.setUserPhone(userData['telephone']);
        debugPrint('Kullanıcı telefonu kaydedildi: ${userData['telephone']}');
      } else if (userData.containsKey('phone')) {
        await _secureStorage.setUserPhone(userData['phone']);
        debugPrint('Kullanıcı telefonu kaydedildi: ${userData['phone']}');
      }
      
      // Tüm kullanıcı bilgilerini JSON olarak sakla (opsiyonel)
      if (userData.isNotEmpty) {
        await _secureStorage.setUserData(jsonEncode(userData));
        debugPrint('Tüm kullanıcı verileri JSON olarak kaydedildi');
      }
    } catch (e) {
      debugPrint('Kullanıcı bilgileri kaydedilirken hata: $e');
    }
  }

  // Test method to check if the issue is structural
  Future<String> testRefreshLogin(String password) async {
    return 'Test method works';
  }

  // RefreshLogin ile giriş yap (refresh token ve şifre ile)
  Future<TokenResponseDTO> refreshLogin(String password) async {
    try {
      debugPrint('RefreshLogin isteği gönderiliyor...');
      
      // Refresh token kontrolü
      final refreshToken = await _secureStorage.getRefreshToken();
      debugPrint('Refresh token değeri: ${refreshToken != null ? refreshToken.substring(0, Math.min(10, refreshToken.length))+'...' : 'null'}');
      
      if (refreshToken == null) {
        debugPrint('Refresh token bulunamadı, normal giriş gerekiyor');
        throw Exception('Oturum bilgisi bulunamadı. Lütfen tekrar giriş yapın.');
      }
      
      // Kullanıcı telefon numarasını al (kullanılabilirse)
      String? userPhone;
      try {
        userPhone = await _secureStorage.getUserPhone();
        debugPrint('🔍 Refresh login için telefon numarası: $userPhone');
        if (userPhone == null) {
          debugPrint('⚠️ Telefon numarası bulunamadı, refresh login başarısız olabilir');
        }
      } catch (e) {
        debugPrint('Telefon numarası alınamadı, devam ediliyor: $e');
      }
      
      // Cihaz ve IP bilgilerini al
      final deviceInfo = await getDeviceInfo();
      final ipAddress = await getIpAddress();
      final appVersion = await getAppVersion();
      final platform = getPlatform();
      
      // İstek gövdesini logla - backend'in beklediği formatta
      Map<String, dynamic> requestBody;
      
      // Postman'de çalışan format - sadece refreshToken ve password
      requestBody = {
        'refreshToken': refreshToken,
        'password': password,
      };
      
      // Telefon numarası varsa ekle
      if (userPhone != null) {
        requestBody['telephone'] = userPhone;
        debugPrint('👍 Telefon numarası refresh login isteğine eklendi');
      }
      
      debugPrint('⭐ REFRESH LOGIN REQUEST DETAILS (Simple Format) ⭐');
      debugPrint('Endpoint: ${ApiConstants.baseUrl}${ApiConstants.refreshLoginEndpoint}');
      debugPrint('Request Body: ${jsonEncode(requestBody).replaceAll('"password":"$password"', '"password":"*****"')}');
      
      // İsteği gönder
      final response = await _apiService.post(
        ApiConstants.refreshLoginEndpoint,
        data: requestBody,
        useLoginDio: true, // Token interceptor kullanma
      );
      
      debugPrint('⭐ REFRESH LOGIN RESPONSE ⭐');
      debugPrint('Status Code: ${response.statusCode}');
      
      // Response body'yi güvenli bir şekilde log'la
      if (response.data != null) {
        if (response.data is Map) {
          // Clone the map to avoid modification issues
          final Map<String, dynamic> safeResponseData = Map.from(response.data);
          
          // Mask any tokens in the response for logging
          if (safeResponseData.containsKey('accessToken') && safeResponseData['accessToken'] is String) {
            final token = safeResponseData['accessToken'] as String;
            safeResponseData['accessToken'] = '${token.substring(0, Math.min(10, token.length))}...';
          }
          
          if (safeResponseData.containsKey('refreshToken') && safeResponseData['refreshToken'] is String) {
            final token = safeResponseData['refreshToken'] as String;
            safeResponseData['refreshToken'] = '${token.substring(0, Math.min(10, token.length))}...';
          }
          
          debugPrint('Response Body: $safeResponseData');
        } else {
          debugPrint('Response Body (not a map): ${response.data}');
        }
      } else {
        debugPrint('Response Body: null');
      }
      
      // Eğer ilk deneme "Token bulunamadı" hatasıyla başarısız olduysa, alternatif formatı dene
      if (response.statusCode == 200 && response.data != null && 
          response.data['message'] == 'Token bulunamadı') {
        
        debugPrint('⚠️ First attempt failed with "Token bulunamadı". Trying alternative format...');
        
        // Format 2: Try using token field instead of refreshToken
        requestBody = {
          'token': refreshToken,  // Try with 'token' field instead of 'refreshToken'
          'password': password,
          'deviceInfo': deviceInfo,
          'ipAddress': ipAddress,
          'appVersion': appVersion,
          'platform': platform,
        };
        
        debugPrint('Alternative Request Body: ${jsonEncode(requestBody).replaceAll('"password":"$password"', '"password":"*****"')}');
        
        final altResponse = await _apiService.post(
          ApiConstants.refreshLoginEndpoint,
          data: requestBody,
          useLoginDio: true,
        );
        
        debugPrint('⭐ ALTERNATIVE REFRESH LOGIN RESPONSE ⭐');
        debugPrint('Status Code: ${altResponse.statusCode}');
        debugPrint('Response Body: ${altResponse.data}');
        
        // Use the alternative response if it succeeded
        if (altResponse.statusCode == 200 && altResponse.data != null && 
            altResponse.data['success'] == true) {
          return await _processRefreshLoginResponse(altResponse);
        }
        
        // Eğer hala başarısız olduysa, bir format daha dene
        debugPrint('⚠️ Second attempt failed. Trying format with Authorization header...');
        
        // Format 3: Try sending token in Authorization header
        requestBody = {
          'password': password,
          'deviceInfo': deviceInfo,
          'ipAddress': ipAddress,
          'appVersion': appVersion,
          'platform': platform,
        };
        
        final headerOptions = Options(
          headers: {
            'Authorization': 'Bearer $refreshToken',
          },
        );
        
        final headerResponse = await _apiService.post(
          ApiConstants.refreshLoginEndpoint,
          data: requestBody,
          options: headerOptions,
          useLoginDio: true,
        );
        
        debugPrint('⭐ HEADER-BASED REFRESH LOGIN RESPONSE ⭐');
        debugPrint('Status Code: ${headerResponse.statusCode}');
        debugPrint('Response Body: ${headerResponse.data}');
        
        // Use this response if it succeeded
        if (headerResponse.statusCode == 200 && headerResponse.data != null && 
            headerResponse.data['success'] == true) {
          return await _processRefreshLoginResponse(headerResponse);
        }
        
        // Tüm denemeler başarısız olduysa, orijinal hatayı fırlat
        throw Exception(response.data['message'] ?? 'Giriş başarısız oldu.');
      }
      
      // Eğer yanıt başarılıysa, orijinal yanıtı işle
      if (response.statusCode == 200 && response.data != null) {
        // Check if this is an error response
        if (response.data['success'] == false) {
          final message = response.data['message'] ?? 'Giriş başarısız oldu.';
          debugPrint('RefreshLogin başarısız: $message');
          
          // If token is not found, clear all tokens and redirect to login
          if (message.contains('Token bulunamadı') || message.contains('Token not found')) {
            debugPrint('🚫 Backend token hatası: $message');
            debugPrint('🔍 Refresh token backend\'de bulunamadı, tüm tokenları temizliyoruz...');
            
            // Clear all tokens since backend doesn't recognize our refresh token
            await _secureStorage.clearTokens();
            
            // Throw a user-friendly error message
            throw Exception('Oturum bilgileriniz geçersiz. Lütfen tekrar giriş yapın.');
          }
          
          throw Exception(message);
        }
        
        // Success response - check if it has token field (refresh login response)
        if (response.data.containsKey('token') && response.data.containsKey('tokenType')) {
          debugPrint('✅ Refresh login başarılı - direkt token response alındı');
          return await _processRefreshLoginResponse(response);
        }
        
        // Regular login response
        return _processSuccessResponse(response);
      } else {
        final message = response.data?['message'] ?? 'Giriş başarısız oldu.';
        debugPrint('RefreshLogin başarısız: $message');
        throw Exception(message);
      }
    } on DioException catch (e) {
      debugPrint('RefreshLogin DioException: ${e.message}');
      debugPrint('Response data: ${e.response?.data}');
      throw Exception(e.response?.data?['message'] ?? 'Giriş başarısız oldu');
    } catch (e) {
      debugPrint('RefreshLogin beklenmeyen hata: $e');
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  // Refresh login response'u işle (sadece access token döner)
  Future<TokenResponseDTO> _processRefreshLoginResponse(Response response) async {
    try {
      debugPrint('⭐ Processing Refresh Login Response ⭐');
      debugPrint('Response Data Type: ${response.data.runtimeType}');
      debugPrint('Response Data: ${response.data}');
      
      if (response.data is! Map<String, dynamic>) {
        throw Exception('Geçersiz API yanıtı: Beklenen format Map<String, dynamic> fakat ${response.data.runtimeType} alındı');
      }
      
      // Refresh login sadece access token döner
      var accessTokenData = response.data;
      
      if (accessTokenData == null) {
        throw Exception('Access token bilgileri eksik. Lütfen tekrar giriş yapın.');
      }
      
      // Telefon numarasını al ve kaydet - şifre sıfırlama sonrası tutarlılık için
      if (response.data.containsKey('user') && response.data['user'] is Map) {
        final user = response.data['user'];
        if (user.containsKey('telephone')) {
          final phone = user['telephone'];
          if (phone != null && phone is String) {
            await _secureStorage.setUserPhone(phone);
            debugPrint('✅ Refresh login response\'dan telefon numarası kaydedildi: $phone');
          }
        }
        
        // Kullanıcı adı ve soyadı da kaydet
        if (user.containsKey('firstName')) {
          final firstName = user['firstName'];
          if (firstName != null && firstName is String) {
            await _secureStorage.setUserFirstName(firstName);
          }
        }
        
        if (user.containsKey('lastName')) {
          final lastName = user['lastName'];
          if (lastName != null && lastName is String) {
            await _secureStorage.setUserLastName(lastName);
          }
        }
      }
      
      // Access Token işleme
      TokenDTO accessToken;
      if (accessTokenData is Map<String, dynamic>) {
        String tokenValue = accessTokenData['token'] as String;
        var expiresAt = accessTokenData['expiresAt'];
        
        DateTime expiry;
        if (expiresAt is String) {
          // ISO 8601 formatında string
          expiry = DateTime.parse(expiresAt);
        } else {
          // Varsayılan süre
          expiry = DateTime.now().add(const Duration(hours: 1));
        }
        
        accessToken = TokenDTO(
          token: tokenValue,
          expiredAt: expiry,
          issuedAt: accessTokenData['issuedAt'] != null ? 
                    DateTime.parse(accessTokenData['issuedAt']) : null,
          lastUsedAt: accessTokenData['lastUsedAt'] != null ? 
                    DateTime.parse(accessTokenData['lastUsedAt']) : null,
          ipAddress: accessTokenData['ipAddress'],
          deviceInfo: accessTokenData['deviceInfo'],
          tokenType: accessTokenData['tokenType'],
        );
      } else {
        throw Exception('Geçersiz access token formatı: $accessTokenData');
      }
      
      // Mevcut refresh token'ı kullan
      final existingRefreshToken = await _secureStorage.getRefreshToken();
      final existingRefreshTokenExpiry = await _secureStorage.getRefreshTokenExpiry();
      
      TokenDTO refreshToken = TokenDTO(
        token: existingRefreshToken ?? '',
        expiredAt: existingRefreshTokenExpiry != null ? 
                   DateTime.parse(existingRefreshTokenExpiry) : 
                   DateTime.now().add(const Duration(days: 30)),
      );
      
      // TokenResponseDTO oluştur
      final tokenResponse = TokenResponseDTO(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      
      // Sadece access token'ı güvenli depolamaya kaydet (refresh token'ı değiştirme)
      await _secureStorage.setAccessToken(tokenResponse.accessToken.token);
      await _secureStorage.setAccessTokenExpiry(tokenResponse.accessToken.expiredAt.toIso8601String());
      
      // Verify tokens were saved correctly
      _secureStorage.getAccessToken().then((token) {
        debugPrint('Saved access token: ${token != null ? token.substring(0, Math.min(10, token.length))+"..." : "null"}');
      });
      
      // Token interceptor'ı etkinleştir
      _apiService.setupTokenInterceptor();
      
      debugPrint('Refresh login token işleme başarılı');
      return tokenResponse;
    } catch (e) {
      debugPrint('Refresh login token işleme hatası: $e');
      throw Exception('Token işlenirken hata oluştu: $e');
    }
  }
  
  // Helper method to process successful login response
  TokenResponseDTO _processSuccessResponse(Response response) {
    try {
      // Detailed logging of response data for debugging
      debugPrint('⭐ Processing Login Response ⭐');
      debugPrint('Response Data Type: ${response.data.runtimeType}');
      debugPrint('Response Data Keys: ${response.data is Map ? (response.data as Map).keys.toList() : "Not a Map"}');
      
      // API yanıtı kontrol et
      if (response.data is! Map<String, dynamic>) {
        throw Exception('Geçersiz API yanıtı: Beklenen format Map<String, dynamic> fakat ${response.data.runtimeType} alındı');
      }
      
      /* Backend'den gelen token yapısı:
      {
        "token": "token-value",       // token değeri
        "issuedAt": timestamp,        // oluşturulma zamanı
        "expiresAt": timestamp,       // sona erme zamanı
        "lastUsedAt": timestamp,      // son kullanılma zamanı
        "ipAddress": "ip-address",    // IP adresi
        "deviceInfo": "device-info",  // cihaz bilgisi
        "tokenType": "TOKEN_TYPE"     // token tipi
      }
      */
      
      // Token'ların direkt varlığını kontrol et (farklı alan adlarını da kontrol et)
      var accessTokenData = response.data['accessToken'];
      var refreshTokenData = response.data['refreshToken'];
      
      // Alternative field names
      if (accessTokenData == null) {
        accessTokenData = response.data['token'] ?? response.data['access_token'];
        debugPrint('Using alternative field for access token: ${accessTokenData != null ? "Found" : "Not found"}');
      }
      
      if (refreshTokenData == null) {
        refreshTokenData = response.data['refresh_token'];
        debugPrint('Using alternative field for refresh token: ${refreshTokenData != null ? "Found" : "Not found"}');
      }
      
      // Tokens might be nested inside data property
      if ((accessTokenData == null || refreshTokenData == null) && response.data['data'] != null) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          debugPrint('Checking for tokens in data property');
          accessTokenData = data['accessToken'] ?? data['token'] ?? data['access_token'];
          refreshTokenData = data['refreshToken'] ?? data['refresh_token'];
        }
      }
      
      if (accessTokenData == null && refreshTokenData == null) {
        debugPrint('No tokens found in response: ${response.data}');
        throw Exception('Token bilgileri eksik. Lütfen tekrar giriş yapın.');
      }
      
      // If one token is missing, use the other one as a backup
      if (accessTokenData == null && refreshTokenData != null) {
        debugPrint('Only refresh token found, using it for both tokens temporarily');
        accessTokenData = refreshTokenData;
      } else if (refreshTokenData == null && accessTokenData != null) {
        debugPrint('Only access token found, using it for both tokens temporarily');
        refreshTokenData = accessTokenData;
      }
      
      // Extract token values based on backend format
      TokenDTO accessToken;
      TokenDTO refreshToken;
      
      // Access Token işleme
      if (accessTokenData is String) {
        // Düz string olarak gelmişse
        accessToken = TokenDTO(
          token: accessTokenData,
          expiredAt: DateTime.now().add(const Duration(hours: 1)),
        );
      } else if (accessTokenData is Map<String, dynamic>) {
        // Backend'in döndüğü format şeklinde gelmişse
        String tokenValue = accessTokenData['token'] as String;
        var expiresAt = accessTokenData['expiresAt'] ?? accessTokenData['expiredAt'];
        
        DateTime expiry;
        if (expiresAt is int) {
          // Unix timestamp (saniye cinsinden)
          expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
        } else if (expiresAt is String) {
          // ISO 8601 formatında string
          expiry = DateTime.parse(expiresAt);
        } else {
          // Varsayılan süre
          expiry = DateTime.now().add(const Duration(hours: 1));
        }
        
        accessToken = TokenDTO(
          token: tokenValue,
          expiredAt: expiry,
          issuedAt: accessTokenData['issuedAt'] != null ? 
                    (accessTokenData['issuedAt'] is int ? 
                    DateTime.fromMillisecondsSinceEpoch(accessTokenData['issuedAt'] * 1000) : 
                    DateTime.parse(accessTokenData['issuedAt'])) : null,
          lastUsedAt: accessTokenData['lastUsedAt'] != null ? 
                    (accessTokenData['lastUsedAt'] is int ? 
                    DateTime.fromMillisecondsSinceEpoch(accessTokenData['lastUsedAt'] * 1000) : 
                    DateTime.parse(accessTokenData['lastUsedAt'])) : null,
          ipAddress: accessTokenData['ipAddress'],
          deviceInfo: accessTokenData['deviceInfo'],
          tokenType: accessTokenData['tokenType'],
        );
      } else {
        throw Exception('Geçersiz access token formatı: $accessTokenData');
      }
      
      // Refresh Token işleme
      if (refreshTokenData is String) {
        // Düz string olarak gelmişse
        refreshToken = TokenDTO(
          token: refreshTokenData,
          expiredAt: DateTime.now().add(const Duration(days: 30)),
        );
      } else if (refreshTokenData is Map<String, dynamic>) {
        // Backend'in döndüğü format şeklinde gelmişse
        String tokenValue = refreshTokenData['token'] as String;
        var expiresAt = refreshTokenData['expiresAt'] ?? refreshTokenData['expiredAt'];
        
        DateTime expiry;
        if (expiresAt is int) {
          // Unix timestamp (saniye cinsinden)
          expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
        } else if (expiresAt is String) {
          // ISO 8601 formatında string
          expiry = DateTime.parse(expiresAt);
        } else {
          // Varsayılan süre
          expiry = DateTime.now().add(const Duration(days: 30));
        }
        
        refreshToken = TokenDTO(
          token: tokenValue,
          expiredAt: expiry,
          issuedAt: refreshTokenData['issuedAt'] != null ? 
                    (refreshTokenData['issuedAt'] is int ? 
                    DateTime.fromMillisecondsSinceEpoch(refreshTokenData['issuedAt'] * 1000) : 
                    DateTime.parse(refreshTokenData['issuedAt'])) : null,
          lastUsedAt: refreshTokenData['lastUsedAt'] != null ? 
                    (refreshTokenData['lastUsedAt'] is int ? 
                    DateTime.fromMillisecondsSinceEpoch(refreshTokenData['lastUsedAt'] * 1000) : 
                    DateTime.parse(refreshTokenData['lastUsedAt'])) : null,
          ipAddress: refreshTokenData['ipAddress'],
          deviceInfo: refreshTokenData['deviceInfo'],
          tokenType: refreshTokenData['tokenType'],
        );
      } else {
        throw Exception('Geçersiz refresh token formatı: $refreshTokenData');
      }
      
      // TokenResponseDTO oluştur
      final tokenResponse = TokenResponseDTO(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      
      // Token'ları güvenli depolamaya kaydet
      _secureStorage.setAccessToken(tokenResponse.accessToken.token);
      _secureStorage.setRefreshToken(tokenResponse.refreshToken.token);
      _secureStorage.setAccessTokenExpiry(tokenResponse.accessToken.expiredAt.toIso8601String());
      _secureStorage.setRefreshTokenExpiry(tokenResponse.refreshToken.expiredAt.toIso8601String());
      
      // Verify tokens were saved correctly
      _secureStorage.getAccessToken().then((token) {
        debugPrint('Saved access token: ${token != null ? token.substring(0, Math.min(10, token.length))+"..." : "null"}');
      });
      
      // Kullanıcı bilgilerini kaydet (eğer yanıtta varsa)
      if (response.data.containsKey('user')) {
        _saveUserInfo(response.data['user']);
      } else if (response.data.containsKey('data') && response.data['data'] is Map && response.data['data'].containsKey('user')) {
        _saveUserInfo(response.data['data']['user']);
      }
      
      // Token interceptor'ı etkinleştir
      _apiService.setupTokenInterceptor();
      
      debugPrint('Token işleme başarılı, access token ve refresh token kaydedildi');
      return tokenResponse;
    } catch (e) {
      debugPrint('Token işleme hatası: $e');
      throw Exception('Token işlenirken hata oluştu: $e');
    }
  }

  // Access token'ı yenile
  Future<bool> refreshAccessToken() async {
    try {
      debugPrint('AuthService: Access token yenileme isteği...');
      return await _tokenService.refreshAccessToken();
    } catch (e) {
      debugPrint('AuthService: Access token yenileme hatası: $e');
      return false;
    }
  }

  // Helper method to get current route
  String getCurrentRoute() {
    try {
      final context = navigatorKey.currentContext;
      if (context != null) {
        final route = ModalRoute.of(context);
        if (route != null && route.settings.name != null) {
          return route.settings.name!;
        }
      }
      return '';
    } catch (e) {
      debugPrint('getCurrentRoute hatası: $e');
      return '';
    }
  }

  // Helper method to check if current route is exempt from token checks
  bool isTokenExemptRoute(String route) {
    final exemptRoutes = [
      '/login',
      '/register',
      '/forgot-password',
      '/refresh-login',
      '/verification',
      '/welcome',
      '/',
    ];
    return exemptRoutes.contains(route);
  }

  // Token'ın varlığını kontrol et (isAuthenticated ile aynı işlevi görür)
  Future<bool> checkToken() async {
    final token = await _secureStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }
  
  // Kullanıcının giriş yapmış olup olmadığını kontrol et
  Future<bool> isAuthenticated() async {
    return await checkToken();
  }
}
