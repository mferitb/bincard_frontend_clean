import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class NotificationService {
  static const _fcmTokenSentKey = 'fcm_token_sent';
  static const _lastPermissionRequestKey = 'last_notification_permission_request';
  Timer? _retryTimer;

  /// Login sonrası çağrılır. Bildirim izni istenir, izin verilirse FCM tokenı API'ye gönderilir.
  Future<String?> handleNotificationFlow() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastAskedString = prefs.getString(_lastPermissionRequestKey);
    final lastAsked = lastAskedString != null ? DateTime.tryParse(lastAskedString) : null;

    // Bildirim izni kapalıysa ve bugün sorulmadıysa tekrar sor
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      if (lastAsked == null ||
          lastAsked.year != now.year ||
          lastAsked.month != now.month ||
          lastAsked.day != now.day) {
        final result = await Permission.notification.request();
        await prefs.setString(_lastPermissionRequestKey, now.toIso8601String());
        if (!result.isGranted) {
          debugPrint('Kullanıcı bildirim izni vermedi.');
          return null;
        }
      } else {
        debugPrint('Bildirim izni kapalı ve bugün zaten sorulmuş.');
        return null;
      }
    }

    // Bildirim izni açık, FCM tokenı gönder
    return await _sendFcmTokenWithRetry();
  }

  /// FCM tokenı API'ye başarılı olana kadar gönderir, tokenı ekrana yazdırmak için döndürür
  Future<String?> _sendFcmTokenWithRetry() async {
    final prefs = await SharedPreferences.getInstance();
    final sent = prefs.getBool(_fcmTokenSentKey) ?? false;
    if (sent) return null; // Başarılıysa tekrar gönderme

    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) {
      debugPrint('FCM token alınamadı!');
      return null;
    } else {
      debugPrint('FCM token alındı: $fcmToken');
    }

    final success = await sendFcmTokenToApi(fcmToken);
    if (success) {
      await prefs.setBool(_fcmTokenSentKey, true);
      _retryTimer?.cancel();
    } else {
      await prefs.setBool(_fcmTokenSentKey, false);
      // 1 dakika sonra tekrar dene
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(minutes: 1), () async {
        debugPrint('FCM token tekrar gönderiliyor (otomatik retry)...');
        await _sendFcmTokenWithRetry();
      });
    }
    return fcmToken;
  }

  /// FCM tokenı PATCH ile query parametre olarak ve accessToken'ı Bearer header ile API'ye gönderir
  Future<bool> sendFcmTokenToApi(String fcmToken) async {
    try {
      // 1. Access Token al
      final secureStorage = SecureStorageService();
      final accessToken = await secureStorage.getAccessToken(); 

      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('[sendFcmTokenToApi] ❌ Access token bulunamadı, istek gönderilmeyecek.');
        return false;
      }

      // 2. URL oluştur
      final url = 'http://192.168.174.214:8080/v1/api/user/update-fcm-token?fcmToken=$fcmToken';
      debugPrint('[sendFcmTokenToApi] 🔗 URL: $url');
      debugPrint('[sendFcmTokenToApi] 🔐 Authorization: Bearer ${accessToken.substring(0, 10)}...');
      debugPrint('[sendFcmTokenToApi] 🚀 FCM token gönderiliyor: $fcmToken');

      // 3. Dio ile PATCH isteği
      final dio = Dio();
      final response = await dio.patch(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      // 4. Yanıt kontrol
      if (response.statusCode == 200 && response.data == true) {
        debugPrint('[sendFcmTokenToApi] ✅ FCM token güncelleme başarılı.');
        return true;
      } else {
        debugPrint('[sendFcmTokenToApi] ⚠️ FCM token güncelleme başarısız. Yanıt: ${response.data}');
        return false;
      }
    } catch (e) {
      debugPrint('[sendFcmTokenToApi] 🛑 Hata oluştu: $e');
      return false;
    }
  }

  // Bildirimleri getir
  Future<Response> getNotifications({String type = 'SUCCESS', int page = 0, int size = 10}) async {
    final dio = Dio();
    final accessToken = await SecureStorageService().getAccessToken();
    final url = '${ApiConstants.baseUrl}${ApiConstants.notifications}?type=$type&page=$page&size=$size';
    return await dio.get(
      url,
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
  }

  // Bildirim detayını getir
  Future<Response> getNotificationDetail(int id) async {
    final dio = Dio();
    final accessToken = await SecureStorageService().getAccessToken();
    final url = '${ApiConstants.baseUrl}${ApiConstants.notificationDetail(id)}';
    return await dio.get(
      url,
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
  }

  // Bildirimi sil
  Future<Response> deleteNotification(int id) async {
    final dio = Dio();
    final accessToken = await SecureStorageService().getAccessToken();
    final url = '${ApiConstants.baseUrl}${ApiConstants.notificationDetail(id)}';
    return await dio.delete(
      url,
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
  }

  // Bildirim sayısını getir
  Future<Response> getNotificationCount() async {
    final dio = Dio();
    final accessToken = await SecureStorageService().getAccessToken();
    final url = '${ApiConstants.baseUrl}${ApiConstants.notificationCount}';
    return await dio.get(
      url,
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
  }

} 