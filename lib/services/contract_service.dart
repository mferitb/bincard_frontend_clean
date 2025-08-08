import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/contract_model.dart';
import '../models/contract_type.dart';
import '../constants/api_constants.dart';

class ContractService {
  final Dio _dio = Dio();
  
  // Singleton pattern
  static final ContractService _instance = ContractService._internal();
  
  factory ContractService() {
    return _instance;
  }
  
  ContractService._internal();

  /// Tüm aktif sözleşmeleri getir
  /// Bu endpoint public olduğu için token gerektirmez
  Future<List<ContractDTO>> getActiveContracts() async {
    try {
      debugPrint('Aktif sözleşmeler getiriliyor...');
      
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.contractsEndpoint}',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        debugPrint('Sözleşmeler başarıyla alındı: ${response.data}');
        
        final List<dynamic> contractsJson = response.data;
        final List<ContractDTO> contracts = contractsJson
            .map((json) => ContractDTO.fromJson(json))
            .toList();
        
        debugPrint('${contracts.length} adet aktif sözleşme bulundu');
        return contracts;
      } else {
        debugPrint('Sözleşmeler alınamadı: ${response.statusCode}');
        throw Exception('Sözleşmeler alınamadı');
      }
    } on DioException catch (e) {
      debugPrint('Sözleşmeler getirme DioException: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      throw Exception(e.response?.data?['message'] ?? 'Bağlantı hatası');
    } catch (e) {
      debugPrint('Sözleşmeler getirme hatası: $e');
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  /// Belirli bir sözleşmeyi ID ile getir
  Future<ContractDTO> getContractById(int contractId) async {
    try {
      debugPrint('ID $contractId ile sözleşme getiriliyor...');
      
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.contractsEndpoint}/$contractId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        debugPrint('Sözleşme başarıyla alındı: ${response.data}');
        return ContractDTO.fromJson(response.data);
      } else {
        debugPrint('Sözleşme alınamadı: ${response.statusCode}');
        throw Exception('Sözleşme bulunamadı');
      }
    } on DioException catch (e) {
      debugPrint('Sözleşme getirme DioException: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Sözleşme bulunamadı');
      }
      throw Exception(e.response?.data?['message'] ?? 'Bağlantı hatası');
    } catch (e) {
      debugPrint('Sözleşme getirme hatası: $e');
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  /// Belirli bir tip için en güncel sözleşmeyi getir
  Future<ContractDTO> getLatestContractByType(ContractType contractType) async {
    try {
      debugPrint('${contractType.value} tipinde sözleşme getiriliyor...');
      
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.contractsEndpoint}/type/${contractType.value}',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        debugPrint('${contractType.displayName} sözleşmesi başarıyla alındı');
        return ContractDTO.fromJson(response.data);
      } else {
        debugPrint('Sözleşme alınamadı: ${response.statusCode}');
        throw Exception('${contractType.displayName} bulunamadı');
      }
    } on DioException catch (e) {
      debugPrint('Sözleşme getirme DioException: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('${contractType.displayName} bulunamadı');
      }
      throw Exception(e.response?.data?['message'] ?? 'Bağlantı hatası');
    } catch (e) {
      debugPrint('Sözleşme getirme hatası: $e');
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  /// Üyelik sözleşmesinin en güncel halini getir
  Future<ContractDTO> getMembershipContract() async {
    try {
      debugPrint('Üyelik sözleşmesi getiriliyor...');
      
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.contractsEndpoint}/membership',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        debugPrint('Üyelik sözleşmesi başarıyla alındı');
        return ContractDTO.fromJson(response.data);
      } else {
        debugPrint('Üyelik sözleşmesi alınamadı: ${response.statusCode}');
        throw Exception('Üyelik sözleşmesi bulunamadı');
      }
    } on DioException catch (e) {
      debugPrint('Üyelik sözleşmesi getirme DioException: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Üyelik sözleşmesi bulunamadı');
      }
      throw Exception(e.response?.data?['message'] ?? 'Bağlantı hatası');
    } catch (e) {
      debugPrint('Üyelik sözleşmesi getirme hatası: $e');
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  /// KVKK Aydınlatma Metninin en güncel halini getir
  Future<ContractDTO> getKvkkIllumination() async {
    try {
      debugPrint('KVKK Aydınlatma Metni getiriliyor...');
      
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.contractsEndpoint}/kvkk-illumination',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        debugPrint('KVKK Aydınlatma Metni başarıyla alındı');
        return ContractDTO.fromJson(response.data);
      } else {
        debugPrint('KVKK Aydınlatma Metni alınamadı: ${response.statusCode}');
        throw Exception('KVKK Aydınlatma Metni bulunamadı');
      }
    } on DioException catch (e) {
      debugPrint('KVKK Aydınlatma Metni getirme DioException: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('KVKK Aydınlatma Metni bulunamadı');
      }
      throw Exception(e.response?.data?['message'] ?? 'Bağlantı hatası');
    } catch (e) {
      debugPrint('KVKK Aydınlatma Metni getirme hatası: $e');
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  /// Kişisel Veri İşleme İzni sözleşmesinin en güncel halini getir
  Future<ContractDTO> getDataProcessingConsent() async {
    try {
      debugPrint('Veri İşleme İzni getiriliyor...');
      
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.contractsEndpoint}/data-processing-consent',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        debugPrint('Veri İşleme İzni başarıyla alındı');
        return ContractDTO.fromJson(response.data);
      } else {
        debugPrint('Veri İşleme İzni alınamadı: ${response.statusCode}');
        throw Exception('Veri İşleme İzni bulunamadı');
      }
    } on DioException catch (e) {
      debugPrint('Veri İşleme İzni getirme DioException: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Veri İşleme İzni bulunamadı');
      }
      throw Exception(e.response?.data?['message'] ?? 'Bağlantı hatası');
    } catch (e) {
      debugPrint('Veri İşleme İzni getirme hatası: $e');
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  /// Gizlilik Politikasının en güncel halini getir
  Future<ContractDTO> getPrivacyPolicy() async {
    try {
      debugPrint('Gizlilik Politikası getiriliyor...');
      
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.contractsEndpoint}/privacy-policy',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        debugPrint('Gizlilik Politikası başarıyla alındı');
        return ContractDTO.fromJson(response.data);
      } else {
        debugPrint('Gizlilik Politikası alınamadı: ${response.statusCode}');
        throw Exception('Gizlilik Politikası bulunamadı');
      }
    } on DioException catch (e) {
      debugPrint('Gizlilik Politikası getirme DioException: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Gizlilik Politikası bulunamadı');
      }
      throw Exception(e.response?.data?['message'] ?? 'Bağlantı hatası');
    } catch (e) {
      debugPrint('Gizlilik Politikası getirme hatası: $e');
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  /// Kullanım Koşullarının en güncel halini getir
  Future<ContractDTO> getTermsOfUse() async {
    try {
      final url = '${ApiConstants.baseUrl}${ApiConstants.contractsEndpoint}/terms-of-use';
      debugPrint('Kullanım Koşulları getiriliyor...');
      debugPrint('API URL: $url');
      
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        debugPrint('Kullanım Koşulları başarıyla alındı');
        return ContractDTO.fromJson(response.data);
      } else {
        debugPrint('Kullanım Koşulları alınamadı: ${response.statusCode}');
        throw Exception('Kullanım Koşulları bulunamadı');
      }
    } on DioException catch (e) {
      debugPrint('Kullanım Koşulları getirme DioException: ${e.message}');
      debugPrint('Response status: ${e.response?.statusCode}');
      debugPrint('Response data: ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        throw Exception('Kullanım Koşulları bulunamadı');
      }
      throw Exception(e.response?.data?['message'] ?? 'Bağlantı hatası');
    } catch (e) {
      debugPrint('Kullanım Koşulları getirme hatası: $e');
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }
}
