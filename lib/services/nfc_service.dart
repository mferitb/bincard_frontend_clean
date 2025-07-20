import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  static final NfcService _instance = NfcService._internal();
  factory NfcService() => _instance;
  NfcService._internal();

  final ValueNotifier<dynamic> result = ValueNotifier(null);

  // NFC kullanılabilir mi kontrol et
  Future<bool> isAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      debugPrint('NFC kontrol hatası: $e');
      return false;
    }
  }

  // NFC okuma oturumunu başlat
  Future<void> startNfcSession({
    required void Function(NfcTag) onTagDiscovered,
    void Function(String)? onError,
  }) async {
    try {
      if (!await isAvailable()) {
        onError?.call('NFC özelliği bu cihazda kullanılamıyor.');
        return;
      }

      await NfcManager.instance.startSession(
        onDiscovered: onTagDiscovered,
        pollingOptions: <NfcPollingOption>{
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
      );
    } catch (e) {
      debugPrint('NFC başlatma hatası: $e');
      onError?.call('NFC başlatılamadı: $e');
    }
  }

  // Kredi kartı okuma oturumu başlat (simüle edilmiş)
  Future<void> startCreditCardReading({
    required void Function(Map<String, dynamic>) onCardRead,
    void Function(String)? onError,
  }) async {
    try {
      if (!await isAvailable()) {
        onError?.call('NFC özelliği bu cihazda kullanılamıyor.');
        return;
      }

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            // Gerçek bir uygulamada burada NFC tag'den veri okunacaktır
            // Biz simüle edilmiş kart bilgileri döndüreceğiz
            final Map<String, dynamic> cardData = _simulateCreditCardData(tag);

            // Başarılı okuma
            onCardRead(cardData);

            // Okuma işlemi tamamlandı, oturumu kapat
            await NfcManager.instance.stopSession();
          } catch (e) {
            debugPrint('Kart okuma hatası: $e');
            onError?.call('Kart okuma hatası: $e');
            await NfcManager.instance.stopSession();
          }
        },
        pollingOptions: <NfcPollingOption>{
          NfcPollingOption.iso14443, // EMV kart standardı
        },
      );
    } catch (e) {
      debugPrint('NFC başlatma hatası: $e');
      onError?.call('NFC başlatılamadı: $e');
    }
  }

  // NFC oturumunu durdur
  Future<void> stopNfcSession() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      debugPrint('NFC durdurma hatası: $e');
    }
  }

  // Simüle edilmiş kredi kartı bilgileri oluştur
  Map<String, dynamic> _simulateCreditCardData(NfcTag tag) {
    // NFC ID'sinden bir hash değeri oluştur (simülasyon için)
    final int hashCode = tag.hashCode;

    // Kartın türünü rasgele belirle
    final List<String> cardTypes = ['Visa', 'MasterCard', 'AmericanExpress'];
    final String cardType = cardTypes[hashCode % cardTypes.length];

    // Son 4 haneyi simüle et
    final String lastFourDigits = _generateLastFourDigits();

    // Kart numarası formatını belirle
    String cardNumber;
    if (cardType == 'Visa') {
      cardNumber = '4*** **** **** $lastFourDigits';
    } else if (cardType == 'MasterCard') {
      cardNumber = '5*** **** **** $lastFourDigits';
    } else {
      cardNumber = '3*** ****** $lastFourDigits';
    }

    // Kart bilgilerini oluştur
    return {
      'cardType': cardType,
      'cardNumber': cardNumber,
      'expiryDate': '${_generateMonth()}/${_generateYear()}',
      'holderName': 'KART SAHİBİ',
      'cvv': '', // CVV asla NFC ile okunmaz, kullanıcı girmelidir
    };
  }

  // Son 4 haneyi simüle et
  String _generateLastFourDigits() {
    return (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
  }

  // Ay simüle et (01-12)
  String _generateMonth() {
    final month = 1 + (DateTime.now().microsecondsSinceEpoch % 12);
    return month.toString().padLeft(2, '0');
  }

  // Yıl simüle et (gelecek 5 yıl içinde)
  String _generateYear() {
    final currentYear = DateTime.now().year % 100; // Son iki hane
    final year =
        currentYear + (1 + (DateTime.now().microsecondsSinceEpoch % 5));
    return year.toString();
  }

  // Dispose metodu
  void dispose() {
    stopNfcSession();
  }
}
