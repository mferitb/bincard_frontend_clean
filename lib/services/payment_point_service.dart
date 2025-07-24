import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment_point_model.dart';
import '../constants/api_constants.dart';

class PaymentPointService {
  static final String baseUrl = ApiConstants.baseUrl;

  // getAllPaymentPoints fonksiyonu kaldırıldı. Artık paymentPointBase endpointi kullanılmıyor.

  Future<PaymentPoint> getPaymentPointById(int id) async {
    final response = await http.get(Uri.parse(baseUrl + ApiConstants.paymentPointById(id)));
    print('getPaymentPointById yanıtı: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data != null && data['data'] != null) {
        return PaymentPoint.fromJson(data['data']);
      } else {
        print('getPaymentPointById: data veya data["data"] null!');
        throw Exception('Ödeme noktası verisi eksik veya hatalı');
      }
    } else {
      print('getPaymentPointById: HTTP hata ${response.statusCode}');
      throw Exception('Ödeme noktası alınamadı');
    }
  }

  Future<List<PaymentPoint>> searchPaymentPoints({
    required String query,
    required double latitude,
    required double longitude,
    int page = 0,
  }) async {
    final url = baseUrl + ApiConstants.paymentPointSearch +
        '?query=${Uri.encodeComponent(query)}&latitude=$latitude&longitude=$longitude&page=$page';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: '{}', // Boş body
    );
    print('searchPaymentPoints yanıtı: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data != null && data['data'] != null && data['data']['content'] != null) {
        final List content = data['data']['content'];
        return content.map((e) => PaymentPoint.fromJson(e)).toList();
      } else {
        print('searchPaymentPoints: data, data["data"] veya data["data"]["content"] null!');
        return [];
      }
    } else {
      print('searchPaymentPoints: HTTP hata ${response.statusCode}');
      throw Exception('Ödeme noktası araması başarısız');
    }
  }

  Future<List<PaymentPoint>> getNearbyPaymentPoints({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int page = 0,
    int size = 10,
  }) async {
    final url = baseUrl + ApiConstants.paymentPointNearby +
        '?latitude=$latitude&longitude=$longitude&radiusKm=$radiusKm&page=$page&size=$size&sort=distance,asc';
    final response = await http.get(Uri.parse(url));
    print('getNearbyPaymentPoints yanıtı: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data != null && data['data'] != null && data['data']['content'] != null) {
        final List content = data['data']['content'];
        return content.map((e) => PaymentPoint.fromJson(e)).toList();
      } else {
        print('getNearbyPaymentPoints: data, data["data"] veya data["data"]["content"] null!');
        return [];
      }
    } else {
      print('getNearbyPaymentPoints: HTTP hata ${response.statusCode}');
      throw Exception('Yakındaki ödeme noktaları alınamadı');
    }
  }

  Future<List<PaymentPoint>> getByCity(String city) async {
    final response = await http.get(Uri.parse(baseUrl + ApiConstants.paymentPointByCity(city)));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List content = data['data']['content'];
      return content.map((e) => PaymentPoint.fromJson(e)).toList();
    } else {
      throw Exception('Şehir bazlı ödeme noktaları alınamadı');
    }
  }

  Future<List<PaymentPoint>> getByPaymentMethod(String paymentMethod) async {
    final response = await http.get(Uri.parse(baseUrl + ApiConstants.paymentPointByPaymentMethod(paymentMethod)));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List content = data['data']['content'];
      return content.map((e) => PaymentPoint.fromJson(e)).toList();
    } else {
      throw Exception('Ödeme yöntemi bazlı ödeme noktaları alınamadı');
    }
  }
} 