import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

enum ConnectionStatus { disconnected, connecting, connected }

class WebSocketService {
  WebSocketChannel? _channel;
  String? _socketUrl;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  Timer? _pingTimer;
  final Duration _pingInterval = const Duration(seconds: 30);

  // Bağlantı durumu için stream controller
  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();

  // Gelen mesajlar için stream controller
  final StreamController<dynamic> _messageController =
      StreamController<dynamic>.broadcast();

  // Getters
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  Stream<dynamic> get messageStream => _messageController.stream;
  ConnectionStatus get status => _status;

  // WebSocket bağlantısını başlatır
  Future<bool> connect(String url) async {
    if (_status == ConnectionStatus.connected) {
      return true;
    }

    _setStatus(ConnectionStatus.connecting);
    _socketUrl = url;

    try {
      _channel = IOWebSocketChannel.connect(
        Uri.parse(url),
        pingInterval: _pingInterval,
      );

      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          debugPrint('WebSocket hata: $error');
          _setStatus(ConnectionStatus.disconnected);
          _reconnect();
        },
        onDone: () {
          debugPrint('WebSocket bağlantısı kapandı');
          _setStatus(ConnectionStatus.disconnected);
          _reconnect();
        },
      );

      _setStatus(ConnectionStatus.connected);
      _startPingTimer();
      return true;
    } catch (e) {
      debugPrint('WebSocket bağlantı hatası: $e');
      _setStatus(ConnectionStatus.disconnected);
      _reconnect();
      return false;
    }
  }

  // Mesaj gönderme
  void send(dynamic message) {
    if (_status == ConnectionStatus.connected && _channel != null) {
      try {
        if (message is Map || message is List) {
          _channel!.sink.add(jsonEncode(message));
        } else {
          _channel!.sink.add(message.toString());
        }
      } catch (e) {
        debugPrint('Mesaj gönderme hatası: $e');
      }
    } else {
      debugPrint('WebSocket bağlı değil. Mesaj gönderilemiyor.');
    }
  }

  // Bağlantıyı kapat
  Future<void> disconnect() async {
    _stopPingTimer();
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }
    _setStatus(ConnectionStatus.disconnected);
  }

  // Bağlantıyı yeniden kur
  void _reconnect() {
    if (_status != ConnectionStatus.connecting && _socketUrl != null) {
      Future.delayed(const Duration(seconds: 5), () {
        connect(_socketUrl!);
      });
    }
  }

  // Gelen mesajları işle
  void _handleMessage(dynamic message) {
    try {
      // JSON mesajı olabilir, bu durumda decode et
      if (message is String) {
        try {
          final decodedMessage = jsonDecode(message);
          _messageController.add(decodedMessage);
          return;
        } catch (e) {
          // JSON değilse, string olarak işle
        }
      }

      // Normal metin veya diğer tür mesajlar
      _messageController.add(message);
    } catch (e) {
      debugPrint('Mesaj işleme hatası: $e');
    }
  }

  // Ping timerı başlat
  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(_pingInterval, (timer) {
      if (_status == ConnectionStatus.connected) {
        send({'type': 'ping'});
      }
    });
  }

  // Ping timerı durdur
  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  // Bağlantı durumunu güncelle
  void _setStatus(ConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(newStatus);
    }
  }

  // Service'i dispose et
  void dispose() {
    disconnect();
    _statusController.close();
    _messageController.close();
  }
}
