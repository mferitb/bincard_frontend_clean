import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmTokenService extends ChangeNotifier {
  String? _token;
  String? get token => _token;

  FcmTokenService() {
    _init();
  }

  Future<void> _init() async {
    await _getToken();
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _token = newToken;
      notifyListeners();
    });
  }

  Future<void> _getToken() async {
    _token = await FirebaseMessaging.instance.getToken();
    notifyListeners();
  }
} 