import 'dart:convert';
import 'dart:io';
import 'dart:math' as Math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:dio/dio.dart';
import 'secure_storage_service.dart';
import '../models/auth_model.dart';
import 'package:http/http.dart' as http;
import '../main.dart'; // navigatorKey için ekledik
import '../constants/api_constants.dart';
import '../routes.dart'; // AppRoutes için eklendi
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences için import eklendi

class TokenService {
  final SecureStorageService _secureStorage = SecureStorageService();
  final Dio _dio = Dio();
  
  // Token yenileme için ayarlar
  static const int _tokenRenewalThreshold = 10; // Tokenın süresinin dolmasına kaç saniye kala yenileme yapılacak (10 saniye)
  static const int _minRenewalInterval = 300; // İki yenileme arasında geçmesi gereken minimum süre (300 saniye = 5 dakika)
  static const String _lastTokenRenewalTimeKey = 'last_token_renewal_time'; // Son token yenileme zamanını kaydetmek için kullanılacak key
  
  // Singleton pattern
  static final TokenService _instance = TokenService._internal();
  
  factory TokenService() {
    return _instance;
  }
  
  TokenService._internal();
  
  // Login sayfasına yönlendirme metodu
  void _navigateToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentContext != null) {
        debugPrint('Kullanıcı login sayfasına yönlendiriliyor...');
        Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    });
  }
  
  // Access token süresi doluyor mu kontrolü (tokenın %75'i dolduğunda yenileme yap)
  Future<bool> isAccessTokenExpiringSoon() async {
    final accessToken = await _secureStorage.getAccessToken();
    
    if (accessToken == null) {
      return true; // Token yoksa, süresi dolmuş kabul et
    }
    
    try {
      final decodedToken = JwtDecoder.decode(accessToken);
      
      // Token'ın süresini kontrol et
      if (JwtDecoder.isExpired(accessToken)) {
        return true; // Token süresi dolmuş
      }
      
      // Token'ın kalan süresini hesapla
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
      final currentDate = DateTime.now();
      final remainingTime = expiryDate.difference(currentDate).inSeconds;
      
      // Token süresinin son %25'indeyse yakında dolacak kabul et
      final totalTime = decodedToken['exp'] - decodedToken['iat'];
      final expiryThreshold = totalTime * 0.25; // Son %25
      
      return remainingTime < expiryThreshold;
    } catch (e) {
      debugPrint('Token süresi kontrol edilirken hata: $e');
      return true; // Hata durumunda, süresi dolmuş kabul et
    }
  }
  
  // Access token'ı yenile
  Future<bool> refreshAccessToken() async {
    try {
      // Refresh token'ı al
      final refreshToken = await _secureStorage.getRefreshToken();
      
      if (refreshToken == null) {
        debugPrint('Refresh token bulunamadı, yenileme yapılamıyor');
        return false;
      }

      // Refresh token'ın süresi dolmuş mu kontrol et
      final refreshTokenExpiry = await _secureStorage.getRefreshTokenExpiry();
      if (refreshTokenExpiry != null) {
        final expiry = DateTime.parse(refreshTokenExpiry);
        final now = DateTime.now();
        
        if (now.isAfter(expiry)) {
          debugPrint('Refresh token süresi dolmuş, yenileme yapılamıyor');
          _navigateToLogin();
          return false;
        }
      }

      debugPrint('Token yenileme isteği hazırlanıyor...');
      
      final options = Options(
        headers: {
          'Content-Type': 'application/json',
        },
        validateStatus: (status) {
          return status! < 500; // 500'den küçük tüm durum kodlarını kabul et
        },
      );
      
      // Yeni API yapısına göre request body hazırla
      final requestBody = {
        'refreshToken': refreshToken
      };
      
      // Token yenileme isteği
      final response = await _dio.post(
        ApiConstants.baseUrl + ApiConstants.refreshTokenEndpoint,
        data: requestBody,
        options: options,
      );

      debugPrint('Token yenileme yanıtı alındı: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data != null) {
        debugPrint('Token yenileme başarılı, yanıt: ${response.data}');
        
        try {
          // Yeni API formatına göre yanıtı işle
          final accessToken = TokenDTO(
            token: response.data['token'],
            expiredAt: DateTime.parse(response.data['expiresAt']),
          );
          
          debugPrint('Alınan Access Token: ${accessToken.token.substring(0, Math.min(20, accessToken.token.length))}...');
          debugPrint('Alınan Access Token Süresi: ${accessToken.expiredAt}');
          
          // Yeni access token'ı kaydet
          await _secureStorage.setAccessToken(accessToken.token);
          await _secureStorage.setAccessTokenExpiry(accessToken.expiredAt.toIso8601String());
          
          // Son token yenileme zamanını kaydet
          await _saveLastTokenRenewalTime();
          
          debugPrint('Token başarıyla yenilendi, süresi: ${accessToken.expiredAt}');
          return true;
        } catch (e) {
          debugPrint('Token yanıtını işlerken hata: $e');
          return false;
        }
      } else {
        // Hata durumunu logla
        final statusCode = response.statusCode;
        final responseData = response.data;
        
        debugPrint('Token yenileme başarısız: Durum kodu: $statusCode');
        debugPrint('Yanıt: $responseData');
        
        // Token bulunamadı hatası veya 401/403 için tüm tokenları temizle ve login sayfasına yönlendir
        if (statusCode == 401 || statusCode == 403) {
          debugPrint('Yetkilendirme hatası, tokenlar temizleniyor...');
          await _secureStorage.clearTokens();
          
          // Login sayfasına yönlendir
          _navigateToLogin();
        }
        
        return false;
      }
    } on DioException catch (e) {
      debugPrint('Token yenileme DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Durum kodu: ${e.response?.statusCode}');
        debugPrint('Yanıt: ${e.response?.data}');
        
        // 401 veya 403 hata kodları için tokenları temizleyelim
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          debugPrint('Yetkilendirme hatası, tokenlar temizleniyor...');
          await _secureStorage.clearTokens();
          
          // Login sayfasına yönlendir
          _navigateToLogin();
        }
      }
      return false;
    } catch (e) {
      debugPrint('Token yenileme hatası: $e');
      return false;
    }
  }
  
  // Son token yenileme zamanını al
  Future<DateTime?> _getLastTokenRenewalTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRenewalTimeStr = prefs.getString(_lastTokenRenewalTimeKey);
      
      if (lastRenewalTimeStr != null) {
        final lastRenewalTime = DateTime.parse(lastRenewalTimeStr);
        debugPrint('Son token yenileme zamanı: $lastRenewalTimeStr');
        return lastRenewalTime;
      }
      debugPrint('Son token yenileme zamanı bulunamadı');
      return null;
    } catch (e) {
      debugPrint('Son token yenileme zamanı alınırken hata: $e');
      return null;
    }
  }
  
  // Son token yenileme zamanını kaydet
  Future<void> _saveLastTokenRenewalTime() async {
    try {
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastTokenRenewalTimeKey, now.toIso8601String());
      debugPrint('Son token yenileme zamanı kaydedildi: ${now.toIso8601String()}');
    } catch (e) {
      debugPrint('Son token yenileme zamanı kaydedilirken hata: $e');
    }
  }
  
  // Access token'ın süresi dolmak üzere mi kontrol et
  Future<bool> isAccessTokenAboutToExpire() async {
    try {
      // Önce mevcut sayfayı kontrol et - güvenli sayfalarda token yenileme yapmayalım
      final currentRoute = getCurrentRoute();
      if (isTokenExemptRoute(currentRoute)) {
        debugPrint('Güvenli sayfa: $currentRoute. Token kontrolü yapılmıyor.');
        return false; // Güvenli sayfalarda token yenileme yapmıyoruz
      }
      
      // Access token'ı doğrudan al
      final accessToken = await _secureStorage.getAccessToken();
      
      if (accessToken == null) {
        debugPrint('Access token bulunamadı, yenileme gerekiyor');
        return true; // Eğer token yoksa, yenileme yapmalıyız
      }
      
      // Son token yenileme zamanını kontrol et
      final lastRenewalTime = await _getLastTokenRenewalTime();
      if (lastRenewalTime != null) {
        final now = DateTime.now();
        final timeSinceLastRenewal = now.difference(lastRenewalTime).inSeconds;
        
        // Eğer son yenilemeden beri minimum süre geçmediyse, yenileme yapma
        if (timeSinceLastRenewal < _minRenewalInterval) {
          debugPrint('Son token yenilemeden beri sadece $timeSinceLastRenewal saniye geçti (minimum: $_minRenewalInterval). Yenileme atlanıyor.');
          return false;
        }
      }
      
      // JWT token'ı decode et ve süresi dolmuş mu kontrol et
      try {
        // Önce token'ın süresi dolmuş mu kontrol et
        if (JwtDecoder.isExpired(accessToken)) {
          debugPrint('Access token süresi dolmuş, yenileme gerekiyor');
          return true;
        }
        
        // Token'ın süresinin dolmasına kalan süreyi hesapla
        final decoded = JwtDecoder.decode(accessToken);
        final expiryTime = DateTime.fromMillisecondsSinceEpoch(decoded['exp'] * 1000);
        final now = DateTime.now();
        
        // Token'ın süresinin dolmasına kalan süre (saniye cinsinden)
        final remainingSeconds = expiryTime.difference(now).inSeconds;
        
        // Debug log ile kalan süreyi bildir (yalnızca kalan süre 2 dakikadan az olduğunda)
        if (remainingSeconds <= 120) {
          debugPrint('Access token süresinin dolmasına $remainingSeconds saniye kaldı (threshold: $_tokenRenewalThreshold)');
        }
        
        // Eğer kalan süre belirlenen threshold'dan azsa, token'ı yenilememiz gerekiyor
        final shouldRefresh = remainingSeconds <= _tokenRenewalThreshold;
        
        if (shouldRefresh) {
          debugPrint('Access token süresi eşiğine ulaşıldı (kalan süre: $remainingSeconds saniye, eşik: $_tokenRenewalThreshold saniye), yenileme gerekiyor');
        }
        
        return shouldRefresh;
      } catch (e) {
        debugPrint('JWT token decode hatası: $e');
        return true; // Hata durumunda güvenli tarafta kal ve yenileme yap
      }
    } catch (e) {
      debugPrint('Token süresi kontrolü hatası: $e');
      return true; // Hata durumunda güvenli tarafta kal ve yenileme yap
    }
  }
  
  // Access token'ın süresi dolmuş mu kontrol et
  Future<bool> isAccessTokenExpired() async {
    try {
      // Access token expiry tarihini al
      final expiryStr = await _secureStorage.getAccessTokenExpiry();
      
      if (expiryStr == null) {
        return true; // Eğer expiry bilgisi yoksa, token süresi dolmuş sayılır
      }
      
      final expiry = DateTime.parse(expiryStr);
      final now = DateTime.now();
      
      // Token süresi dolmuş mu?
      return now.isAfter(expiry);
    } catch (e) {
      debugPrint('Token expiry kontrolü hatası: $e');
      return true; // Hata durumunda güvenli tarafta kal
    }
  }

  // Refresh token'ın süresi dolmuş mu kontrol et
  Future<bool> isRefreshTokenExpired() async {
    try {
      // Refresh token expiry tarihini al
      final expiryStr = await _secureStorage.getRefreshTokenExpiry();
      
      if (expiryStr == null) {
        return true; // Eğer expiry bilgisi yoksa, token süresi dolmuş sayılır
      }
      
      final expiry = DateTime.parse(expiryStr);
      final now = DateTime.now();
      
      // Token süresi dolmuş mu?
      return now.isAfter(expiry);
    } catch (e) {
      debugPrint('Refresh token expiry kontrolü hatası: $e');
      return true; // Hata durumunda güvenli tarafta kal
    }
  }
  
  // Cihaz bilgisi al
  Future<String> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        return 'Android ${Platform.operatingSystemVersion}';
      } else if (Platform.isIOS) {
        return 'iOS ${Platform.operatingSystemVersion}';
      } else {
        return 'Flutter ${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
      }
    } catch (e) {
      return 'Flutter App';
    }
  }
  
  // IP adresi al
  Future<String> _getIpAddress() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.ipifyUrl));
      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (e) {
      debugPrint('IP adresi alınamadı: $e');
    }
    return '127.0.0.1';
  }
  
  // API istekleri için interceptor oluştur
  Interceptor get tokenInterceptor => InterceptorsWrapper(
    onRequest: (options, handler) async {
      // Login ve token yenileme istekleri için token kontrolü yapma
      if (options.path.contains('/auth/login') || options.path.contains('/auth/refresh')) {
        debugPrint('Login veya refresh isteği, token kontrolü yapılmıyor: ${options.path}');
        return handler.next(options);
      }
      
      // Mevcut rota kontrolü yap ve muaf sayfalar için token kontrolünü atla
      final currentRoute = getCurrentRoute();
      if (isTokenExemptRoute(currentRoute)) {
        debugPrint('Token kontrolünden muaf sayfa: $currentRoute, token kontrolü yapılmıyor');
        
        // Sadece Authorization header'ını ekleyelim (eğer varsa), token yenileme yapmadan
        final accessToken = await _secureStorage.getAccessToken();
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
          debugPrint('Muaf sayfada sadece mevcut token eklenip devam ediliyor');
        }
        
        return handler.next(options);
      }
      
      try {
        // Access token kontrolü
        final accessToken = await _secureStorage.getAccessToken();
        if (accessToken == null) {
          debugPrint('Access token bulunamadı, login olmadan devam ediliyor');
          // Token yoksa request'i olduğu gibi gönder, interceptor sadece uyarı verir
          return handler.next(options);
        }
        
        // Access token'ın süresi dolmak üzere mi kontrol et
        final isAboutToExpire = await isAccessTokenAboutToExpire();
        
        if (isAboutToExpire) {
          // Son yenilemeden beri yeterli süre geçmiş mi kontrol et
          final canRefreshNow = await _hasEnoughTimePassed();
          
          if (canRefreshNow) {
            debugPrint('Access token süresi dolmak üzere, yenileniyor...');
            // Token'ı yenile
            final refreshed = await refreshAccessToken();
            
            if (refreshed) {
              debugPrint('Token başarıyla yenilendi, isteğe devam ediliyor');
              // Son token yenileme zamanını kaydet (başarılı yenileme sonrası)
              await _saveLastTokenRenewalTime();
            } else {
              debugPrint('Token yenileme başarısız, ancak kullanıcı oturumuna müdahale edilmiyor');
              // Token yenileme başarısız olsa da kullanıcıyı login sayfasına yönlendirmiyoruz
              // Sadece mevcut token ile devam etmeye çalışıyoruz
            }
          } else {
            debugPrint('Token yenileme gerekiyor, ancak son yenilemeden beri yeterli süre geçmediği için atlanıyor');
          }
        } else {
          debugPrint('Token hala geçerli, yenileme gerekmiyor');
        }
        
        // İsteğe access token ekle
        final updatedAccessToken = await _secureStorage.getAccessToken();
        if (updatedAccessToken != null) {
          options.headers['Authorization'] = 'Bearer $updatedAccessToken';
          debugPrint('İsteğe access token eklendi');
        } else {
          // Sessizce login sayfasına yönlendir, hata gösterme
          _navigateToLogin();
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
            ),
          );
        }
        
        return handler.next(options);
      } catch (e) {
        // Sessizce login sayfasına yönlendir, hata gösterme
        _navigateToLogin();
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
          ),
        );
      }
    },
    onError: (error, handler) async {
      // 401 hatası alındıysa token yenilemeyi dene
      if (error.response?.statusCode == 401 || error.response?.statusCode == 403) {
        // Login ve refresh istekleri için yenileme yapma
        if (error.requestOptions.path.contains('/auth/login') || 
            error.requestOptions.path.contains('/auth/refresh')) {
          debugPrint('Login veya refresh isteği için token yenileme yapılmıyor');
          return handler.next(error);
        }
        
        debugPrint('${error.response?.statusCode} hatası alındı, token yenileniyor...');
        
        try {
          // Token'ı yenile
          final refreshed = await refreshAccessToken();
          
          if (refreshed) {
            // Yeni token ile isteği tekrar gönder
            final accessToken = await _secureStorage.getAccessToken();
            if (accessToken == null) {
              debugPrint('Token yenileme sonrası access token bulunamadı, hata döndürülüyor');
              return handler.next(error);
            }
            
            error.requestOptions.headers['Authorization'] = 'Bearer $accessToken';
            
            // İsteği tekrar oluştur
            final opts = Options(
              method: error.requestOptions.method,
              headers: error.requestOptions.headers,
            );
            
            debugPrint('İstek yeni token ile tekrar gönderiliyor...');
            
            try {
              final response = await _dio.request(
                error.requestOptions.uri.toString(),
                options: opts,
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
              );
              
              debugPrint('İstek başarıyla yeniden gönderildi');
              return handler.resolve(response);
            } catch (retryError) {
              debugPrint('İstek tekrar gönderilirken hata oluştu: $retryError');
              return handler.next(error);
            }
          } else {
            debugPrint('Token yenileme başarısız, orijinal hata döndürülüyor');
            return handler.next(error);
          }
        } catch (e) {
          debugPrint('Token yenileme sırasında hata oluştu: $e');
          return handler.next(error);
        }
      }
      
      return handler.next(error);
    },
  );
  
  // Geçerli bir token var mı kontrolü
  Future<bool> hasValidTokens() async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      final refreshToken = await _secureStorage.getRefreshToken();
      
      // Eğer refresh token yoksa veya süresi dolmuşsa, sadece false döndür
      if (refreshToken == null || await isRefreshTokenExpired()) {
        debugPrint('Refresh token yok veya süresi dolmuş, oturum geçersiz');
        await _secureStorage.clearAll();
        return false;
      }
      
      if (accessToken == null) {
        debugPrint('Access token yok, oturum geçersiz');
        return false;
      }
      
      // JWT token'ların geçerliliğini kontrol et
      try {
        // Access token geçerli mi kontrol et
        final isAccessTokenExpired = JwtDecoder.isExpired(accessToken);
        
        if (!isAccessTokenExpired) {
          debugPrint('Access token geçerli, oturum aktif');
          return true; // Access token geçerli
        }
        
        // Access token süresi dolmuş, refresh token geçerli mi kontrol et
        final isRefreshTokenExpired = JwtDecoder.isExpired(refreshToken);
        
        if (isRefreshTokenExpired) {
          debugPrint('Refresh token süresi dolmuş, oturum geçersiz');
          await _secureStorage.clearAll();
          return false; // Her iki token da geçersiz
        }
        
        debugPrint('Access token süresi dolmuş, refresh token geçerli, token yenileniyor');
        // Refresh token geçerli, yeni access token almayı dene
        return await refreshAccessToken();
      } catch (e) {
        debugPrint('JWT token decode hatası: $e');
        await _secureStorage.clearAll();
        return false; // JWT decode hatası, güvenli tarafta kal
      }
    } catch (e) {
      debugPrint('Token kontrolü hatası: $e');
      await _secureStorage.clearAll();
      return false; // Genel bir hata, güvenli tarafta kal
    }
  }
  
  // Kullanıcı login kontrolü ve gerekli durumlarda yönlendirme
  Future<bool> checkAuthenticationAndRedirect() async {
    final hasValidTokens = await this.hasValidTokens();
    
    if (!hasValidTokens) {
      debugPrint('Kullanıcı oturumu geçersiz, login sayfasına yönlendiriliyor');
      _navigateToLogin();
      return false;
    }
    
    return true;
  }

  // Token'dan user ID bilgisini alma
  Future<int?> getUserIdFromToken() async {
    final accessToken = await _secureStorage.getAccessToken();
    
    if (accessToken == null) {
      return null;
    }
    
    try {
      final decodedToken = JwtDecoder.decode(accessToken);
      return decodedToken['userId'];
    } catch (e) {
      debugPrint('Token decode hatası: $e');
      return null;
    }
  }
  
  // Token'dan kullanıcı rollerini alma
  Future<List<String>> getUserRolesFromToken() async {
    final accessToken = await _secureStorage.getAccessToken();
    
    if (accessToken == null) {
      return [];
    }
    
    try {
      final decodedToken = JwtDecoder.decode(accessToken);
      final roles = decodedToken['roles'];
      
      if (roles is List) {
        return roles.cast<String>();
      }
      
      return [];
    } catch (e) {
      debugPrint('Token decode hatası: $e');
      return [];
    }
  }
  
  // Tokenleri temizle (çıkış yapma durumunda)
  Future<void> clearTokens() async {
    await _secureStorage.clearTokens();
  }

  /// Access token'ın süresi dolmasına 1 dakika kala otomatik yenileme
  Future<void> refreshAccessTokenIfNeeded() async {
    final expiryStr = await _secureStorage.getAccessTokenExpiry();
    if (expiryStr == null) return;

    final expiry = DateTime.parse(expiryStr);
    final now = DateTime.now();
    final difference = expiry.difference(now);

    if (difference.inSeconds < 60) { // 1 dakika kala
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) return;

      try {
        final response = await Dio().post(
          ApiConstants.baseUrl + ApiConstants.refreshTokenEndpoint,
          data: {'refreshToken': refreshToken},
          options: Options(headers: {'Content-Type': 'application/json'}),
        );

        if (response.statusCode == 200 && response.data != null) {
          final newAccessToken = response.data['token'];
          final newExpiresAt = response.data['expiresAt'];
          if (newAccessToken != null && newExpiresAt != null) {
            await _secureStorage.setAccessToken(newAccessToken);
            await _secureStorage.setAccessTokenExpiry(newExpiresAt);
            debugPrint('Yeni access token otomatik olarak kaydedildi.');
          }
        }
      } catch (e) {
        debugPrint('Access token otomatik yenileme hatası: $e');
      }
    }
  }

  /// Sade http ile access token yenileme fonksiyonu
  Future<void> refreshAccessTokenSimple() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null) return;

    // Refresh token'ın süresi dolmuş mu kontrol et
    final refreshTokenExpiry = await _secureStorage.getRefreshTokenExpiry();
    if (refreshTokenExpiry != null) {
      final expiry = DateTime.parse(refreshTokenExpiry);
      final now = DateTime.now();
      
      if (now.isAfter(expiry)) {
        debugPrint('Refresh token süresi dolmuş, yenileme yapılamıyor');
        _navigateToLogin();
        return;
      }
    }

    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.refreshTokenEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "refreshToken": refreshToken
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _secureStorage.setAccessToken(data['token']);
      await _secureStorage.setAccessTokenExpiry(data['expiresAt']);
      debugPrint('Access token başarıyla yenilendi');
    } else {
      debugPrint("Token yenileme başarısız: ${response.body}");
      
      // 401 veya 403 hata kodları için tokenları temizleyelim
      if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('Yetkilendirme hatası, tokenlar temizleniyor...');
        await _secureStorage.clearTokens();
        
        // Login sayfasına yönlendir
        _navigateToLogin();
      }
    }
  }

  // Son yenilemeden sonra geçen süreyi kontrol et
  Future<bool> _hasEnoughTimePassed() async {
    final lastRenewalTime = await _getLastTokenRenewalTime();
    if (lastRenewalTime == null) {
      debugPrint('Son token yenileme zamanı bulunamadı, ilk defa yenileme yapılacak');
      return true; // Eğer daha önce bir yenileme yapılmamışsa, yenilemeye izin ver
    }
    
    final now = DateTime.now();
    final timeSinceLastRenewal = now.difference(lastRenewalTime).inSeconds;
    
    // Eğer son yenilemeden beri minimum süre geçmediyse, yenileme yapma
    if (timeSinceLastRenewal < _minRenewalInterval) {
      debugPrint('Son token yenilemeden beri sadece $timeSinceLastRenewal saniye geçti (minimum: $_minRenewalInterval). Yenileme için henüz erken.');
      return false;
    }
    
    debugPrint('Son token yenilemeden beri $timeSinceLastRenewal saniye geçti, yenileme yapılabilir');
    return true;
  }

  // Mevcut sayfayı al
  String getCurrentRoute() {
    if (navigatorKey.currentContext != null) {
      final route = ModalRoute.of(navigatorKey.currentContext!);
      if (route != null) {
        return route.settings.name ?? '';
      }
    }
    return '';
  }
  
  // Token kontrolünden muaf sayfaları kontrol et
  bool isTokenExemptRoute(String route) {
    // Muaf sayfalar listesi
    final exemptRoutes = [
      AppRoutes.login,                      // '/login'
      AppRoutes.refreshLogin,               // '/refresh-login'
      AppRoutes.register,                   // '/register'
      AppRoutes.verification,               // '/verification'
      AppRoutes.forgotPassword,             // '/forgot-password'
      AppRoutes.resetPassword,              // '/reset-password'
      AppRoutes.loginSmsVerify,             // '/login-sms-verify'
      AppRoutes.forgotPasswordSmsVerify,    // '/forgot-password-sms-verify'
      // Ek muaf sayfalar buraya eklenebilir
    ];
    
    return exemptRoutes.contains(route);
  }
}