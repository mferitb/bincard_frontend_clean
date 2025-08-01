import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/auth_model.dart';
import 'token_service.dart';
import 'secure_storage_service.dart';
import '../constants/api_constants.dart';

class UserService {
  final Dio _dio = Dio();
  final TokenService _tokenService = TokenService();
  final SecureStorageService _secureStorage = SecureStorageService();
  
  // Singleton pattern
  static final UserService _instance = UserService._internal();
  
  factory UserService() {
    return _instance;
  }
  
  UserService._internal() {
    _dio.interceptors.add(_tokenService.tokenInterceptor);
  }
  
  // Kullanıcı kaydı (sign-up)
  Future<ResponseMessage> signUp(String firstName, String lastName, String phoneNumber, String password) async {
    try {
      final createUserRequest = {
        'firstName': firstName,
        'lastName': lastName,
        'telephone': phoneNumber,
        'password': password
      };
      
      debugPrint('Kullanıcı kaydı yapılıyor: $phoneNumber');
      
      final response = await _dio.post(
        ApiConstants.baseUrl + ApiConstants.signUpEndpoint,
        data: createUserRequest,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Kullanıcı kaydı başarılı: ${response.data}');
        return ResponseMessage.fromJson(response.data);
      } else {
        debugPrint('Kullanıcı kaydı başarısız: ${response.statusCode} - ${response.data}');
        return ResponseMessage.error('Kayıt işlemi başarısız: ${response.data['message'] ?? 'Bilinmeyen hata'}');
      }
    } on DioException catch (e) {
      debugPrint('Kullanıcı kaydı DioException: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      return ResponseMessage.error(e.response?.data?['message'] ?? 'Bağlantı hatası');
    } catch (e) {
      debugPrint('Kullanıcı kaydı hatası: $e');
      return ResponseMessage.error('Beklenmeyen bir hata oluştu: $e');
    }
  }
  
  // Telefon numarası doğrulama
  Future<ResponseMessage> verifyPhoneNumber(int code) async {
    try {
      debugPrint('Telefon doğrulama kodu gönderiliyor: $code');
      
      final formData = FormData.fromMap({
        'code': code,
      });
      
      final response = await _dio.post(
        ApiConstants.baseUrl + ApiConstants.verifyPhoneEndpoint,
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
      
      if (response.statusCode == 200) {
        debugPrint('Telefon doğrulama başarılı: ${response.data}');
        return ResponseMessage.fromJson(response.data);
      } else {
        debugPrint('Telefon doğrulama başarısız: ${response.statusCode} - ${response.data}');
        return ResponseMessage.error('Doğrulama başarısız: ${response.data['message'] ?? 'Bilinmeyen hata'}');
      }
    } on DioException catch (e) {
      debugPrint('Telefon doğrulama DioException: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      return ResponseMessage.error(e.response?.data?['message'] ?? 'Bağlantı hatası');
    } catch (e) {
      debugPrint('Telefon doğrulama hatası: $e');
      return ResponseMessage.error('Beklenmeyen bir hata oluştu: $e');
    }
  }
  
  // Doğrulama kodunu yeniden gönder
  Future<ResponseMessage> resendCode(String phoneNumber) async {
    try {
      debugPrint('Doğrulama kodu yeniden isteniyor: $phoneNumber');
      
      final formData = FormData.fromMap({
        'phoneNumber': phoneNumber,
      });
      
      final response = await _dio.post(
        ApiConstants.baseUrl + ApiConstants.resendCodeEndpoint,
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
      
      if (response.statusCode == 200) {
        debugPrint('Kod yeniden gönderme başarılı: ${response.data}');
        return ResponseMessage.fromJson(response.data);
      } else {
        debugPrint('Kod yeniden gönderme başarısız: ${response.statusCode} - ${response.data}');
        return ResponseMessage.error('Kod gönderme başarısız: ${response.data['message'] ?? 'Bilinmeyen hata'}');
      }
    } on DioException catch (e) {
      debugPrint('Kod yeniden gönderme DioException: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      return ResponseMessage.error(e.response?.data?['message'] ?? 'Bağlantı hatası');
    } catch (e) {
      debugPrint('Kod yeniden gönderme hatası: $e');
      return ResponseMessage.error('Beklenmeyen bir hata oluştu: $e');
    }
  }
  
  // Kullanıcı profil bilgilerini getir (GET mapping: /v1/api/user/profile)
  // ÖNCELİK: Her zaman API'den al, SecureStorage ile karşılaştır, farklıysa güncelle
  Future<UserProfile> getUserProfile() async {
    try {
      // Access token al
      final accessToken = await _secureStorage.getAccessToken();
      
      if (accessToken == null) {
        throw Exception('Access token bulunamadı');
      }
      
      debugPrint('🎯 ÖNCELİK: API\'den profil bilgileri getiriliyor...');
      
      // Cache busting için timestamp parametresi ekle
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = '${ApiConstants.baseUrl}${ApiConstants.userProfileEndpoint}?_t=$timestamp';
      
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
        ),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        debugPrint('✅ API\'den profil bilgileri başarıyla alındı');
        
        // 🔍 Raw API response'u logla
        final Map<String, dynamic> userData = response.data;
        debugPrint('🔍 RAW API RESPONSE: $userData');
        debugPrint('🔍 API Name field: ${userData['name']}');
        debugPrint('🔍 API Surname field: ${userData['surname']}');
        
        // JSON yanıtını UserProfile modeline dönüştür
        final userProfile = UserProfile.fromJson(userData);
        
        // 🔍 Parsed model'i logla
        debugPrint('🔍 PARSED MODEL - Name: ${userProfile.name}, Surname: ${userProfile.surname}');
        
        // 📱 Mevcut SecureStorage verilerini kontrol et
        final storedName = await _secureStorage.getUserFirstName();
        final storedSurname = await _secureStorage.getUserLastName();
        debugPrint('🔍 SecureStorage - Ad: $storedName, Soyad: $storedSurname');
        
        // 🔄 API ile SecureStorage verilerini karşılaştır
        final apiName = userProfile.name ?? '';
        final apiSurname = userProfile.surname ?? '';
        
        if (apiName != storedName || apiSurname != storedSurname) {
          debugPrint('⚠️ API ve SecureStorage verileri FARKLI! SecureStorage güncelleniyor...');
          debugPrint('⚠️ API: $apiName $apiSurname');
          debugPrint('⚠️ SecureStorage: $storedName $storedSurname');
          
          // SecureStorage'ı API verisiyle güncelle
          await _secureStorage.setUserFirstName(apiName);
          await _secureStorage.setUserLastName(apiSurname);
          
          // Double-check
          final updatedName = await _secureStorage.getUserFirstName();
          final updatedSurname = await _secureStorage.getUserLastName();
          debugPrint('✅ SecureStorage güncellendi - Ad: $updatedName, Soyad: $updatedSurname');
        } else {
          debugPrint('✅ API ve SecureStorage verileri UYUMLU - güncelleme gerekmiyor');
        }
        
        // Kullanıcı telefon bilgisini SecureStorage'a kaydet
        if (userData['userNumber'] != null) {
          await _secureStorage.setUserPhone(userData['userNumber']);
        }
        
        debugPrint('🎯 RETURN: API verisi döndürülüyor - ${userProfile.name} ${userProfile.surname}');
        return userProfile;
      } else {
        throw Exception('Profil bilgileri alınamadı');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        debugPrint('Token süresi dolmuş, yenileniyor...');
        // Token yenileme işlemi tokenInterceptor tarafından otomatik yapılacak
        // Bu noktada yeniden deneme yapabiliriz
        return await _retryGetUserProfile();
      }
      
      debugPrint('Profil getirme hatası (DioException): ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      throw Exception('Profil bilgileri alınamadı: ${e.message}');
    } catch (e) {
      debugPrint('Profil getirme hatası: $e');
      throw Exception('Profil bilgileri alınamadı: $e');
    }
  }
  
  // Profil bilgilerini almayı yeniden dene (token yenilendikten sonra)
  Future<UserProfile> _retryGetUserProfile() async {
    try {
      // Refresh token ile yeni access token al
      final refreshSuccess = await _tokenService.refreshAccessToken();
      
      if (!refreshSuccess) {
        throw Exception('Token yenilenemedi');
      }
      
      final newAccessToken = await _secureStorage.getAccessToken();
      
      if (newAccessToken == null) {
        throw Exception('Yeni access token alınamadı');
      }
      
      debugPrint('Token yenilendi, profil bilgileri tekrar getiriliyor...');
      
      // Cache busting için timestamp parametresi ekle
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = '${ApiConstants.baseUrl}${ApiConstants.userProfileEndpoint}?_t=$timestamp';
      
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $newAccessToken',
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
        ),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        debugPrint('Profil bilgileri başarıyla alındı (retry)');
        
        // JSON yanıtını UserProfile modeline dönüştür
        final Map<String, dynamic> userData = response.data;
        final userProfile = UserProfile.fromJson(userData);
        
        // 📱 Mevcut SecureStorage verilerini kontrol et
        final storedName = await _secureStorage.getUserFirstName();
        final storedSurname = await _secureStorage.getUserLastName();
        
        // 🔄 API ile SecureStorage verilerini karşılaştır ve güncelle
        final apiName = userProfile.name ?? '';
        final apiSurname = userProfile.surname ?? '';
        
        if (apiName != storedName || apiSurname != storedSurname) {
          debugPrint('⚠️ Retry: API ve SecureStorage verileri farklı! SecureStorage güncelleniyor...');
          await _secureStorage.setUserFirstName(apiName);
          await _secureStorage.setUserLastName(apiSurname);
          debugPrint('✅ Retry: SecureStorage güncellendi');
        }
        
        // Kullanıcı telefon bilgisini SecureStorage'a kaydet
        if (userData['userNumber'] != null) {
          await _secureStorage.setUserPhone(userData['userNumber']);
        }
        
        return userProfile;
      } else {
        throw Exception('Profil bilgileri alınamadı');
      }
    } catch (e) {
      debugPrint('Profil bilgileri yeniden getirme hatası: $e');
      throw Exception('Profil bilgileri alınamadı: $e');
    }
  }
  
  // Kullanıcı profil bilgilerini güncelle (PUT mapping: /v1/api/user/profile)
  Future<ResponseMessage> updateUserProfile(UpdateUserRequest updateRequest) async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      
      if (accessToken == null) {
        throw Exception('Access token bulunamadı');
      }
      
      // Profil güncellemesi için UpdateProfileRequest olarak verileri hazırla
      final jsonData = {
        'name': updateRequest.name,
        'surname': updateRequest.surname
       };
      
      // Email bilgisi varsa ekle
      if (updateRequest.email != null && updateRequest.email!.isNotEmpty) {
        jsonData['email'] = updateRequest.email;
      }
      
      debugPrint('Profil güncelleme isteği: $jsonData');
      
      final response = await _dio.put(
        ApiConstants.baseUrl + ApiConstants.userProfileEndpoint,
        data: jsonData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        debugPrint('Profil güncelleme başarılı: ${response.data}');
        
        // Güncelleme başarılı olduktan sonra kısa bir delay ekle
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Güncellemeden hemen sonra SecureStorage'ı güncelle
        try {
          if (updateRequest.name != null) {
            await _secureStorage.setUserFirstName(updateRequest.name!);
            debugPrint('SecureStorage güncellendi - Ad: ${updateRequest.name}');
          }
          if (updateRequest.surname != null) {
            await _secureStorage.setUserLastName(updateRequest.surname!);
            debugPrint('SecureStorage güncellendi - Soyad: ${updateRequest.surname}');
          }
        } catch (e) {
          debugPrint('SecureStorage güncelleme hatası: $e');
        }
        
        return ResponseMessage.fromJson(response.data);
      } else {
        debugPrint('Profil güncelleme başarısız: ${response.statusCode} - ${response.data}');
        return ResponseMessage.error('Güncelleme başarısız: ${response.data['message'] ?? 'Bilinmeyen hata'}');
      }
    } on DioException catch (e) {
      debugPrint('Profil güncelleme DioException: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      return ResponseMessage.error(e.response?.data?['message'] ?? 'Bağlantı hatası');
    } catch (e) {
      debugPrint('Profil güncelleme hatası: $e');
      return ResponseMessage.error('Beklenmeyen bir hata oluştu: $e');
    }
  }
  
  // Profil fotoğrafını güncelle - ayrı bir endpoint kullanarak (PUT mapping: /v1/api/user/profile/photo)
  Future<ResponseMessage> updateProfilePhoto(File profilePhoto) async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      
      if (accessToken == null) {
        throw Exception('Access token bulunamadı');
      }
      
      // Profil fotoğrafını yükle
      final fileName = profilePhoto.path.split('/').last;
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          profilePhoto.path,
          filename: fileName,
        ),
      });
      
      final response = await _dio.put(
        ApiConstants.baseUrl + ApiConstants.updateProfilePhotoEndpoint,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        debugPrint('Profil fotoğrafı güncelleme başarılı: ${response.data}');
        return ResponseMessage.fromJson(response.data);
      } else {
        debugPrint('Profil fotoğrafı güncelleme başarısız: ${response.statusCode} - ${response.data}');
        return ResponseMessage.error('Fotoğraf güncelleme başarısız: ${response.data['message'] ?? 'Bilinmeyen hata'}');
      }
    } on DioException catch (e) {
      debugPrint('Profil fotoğrafı güncelleme DioException: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      return ResponseMessage.error(e.response?.data?['message'] ?? 'Bağlantı hatası');
    } catch (e) {
      debugPrint('Profil fotoğrafı güncelleme hatası: $e');
      return ResponseMessage.error('Beklenmeyen bir hata oluştu: $e');
    }
  }
  
  // Şifre değiştirme - PUT mapping: /v1/api/user/password/change
  Future<ResponseMessage> changePassword(String currentPassword, String newPassword) async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      
      if (accessToken == null) {
        throw Exception('Access token bulunamadı');
      }
      
      // Şifre değiştirme isteği için ChangePasswordRequest olarak verileri hazırla
      final jsonData = {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };
      
      debugPrint('Şifre değiştirme isteği gönderiliyor...');
      
      final response = await _dio.put(
        ApiConstants.baseUrl + ApiConstants.changePasswordEndpoint,
        data: jsonData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        debugPrint('Şifre değiştirme başarılı: ${response.data}');
        return ResponseMessage.fromJson(response.data);
      } else {
        debugPrint('Şifre değiştirme başarısız: ${response.statusCode} - ${response.data}');
        return ResponseMessage.error('Şifre değiştirme başarısız: ${response.data['message'] ?? 'Bilinmeyen hata'}');
      }
    } on DioException catch (e) {
      debugPrint('Şifre değiştirme DioException: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      
      // API'den gelen hata mesajlarını kontrol et
      if (e.response?.data != null && e.response?.data['message'] != null) {
        final errorMessage = e.response?.data['message'];
        
        // Özel hata durumlarını kontrol et
        if (errorMessage.toString().contains('Incorrect current password')) {
          return ResponseMessage.error('Mevcut şifreniz yanlış');
        } else if (errorMessage.toString().contains('Passwords do not match')) {
          return ResponseMessage.error('Şifreler eşleşmiyor');
        } else if (errorMessage.toString().contains('Same password')) {
          return ResponseMessage.error('Yeni şifreniz mevcut şifrenizle aynı olamaz');
        } else if (errorMessage.toString().contains('Invalid new password')) {
          return ResponseMessage.error('Yeni şifreniz geçerli değil. Şifre 6 rakamdan oluşmalıdır.');
        }
        
        return ResponseMessage.error(errorMessage);
      }
      
      return ResponseMessage.error('Bağlantı hatası: ${e.message}');
    } catch (e) {
      debugPrint('Şifre değiştirme hatası: $e');
      return ResponseMessage.error('Beklenmeyen bir hata oluştu: $e');
    }
  }
  
  // Kullanıcı hesabını sil (DELETE mapping: /user/delete-account)
  Future<ResponseMessage> deactivateUser() async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null) {
        throw Exception('Access token bulunamadı');
      }
      
      // Backend'in beklediği request format
      final requestData = {
        // Backend'deki DeleteAccountRequest modeline göre gerekli alanları ekleyin
        // Örnek: 'reason': 'User requested account deletion'
      };
      
      final response = await _dio.delete(
        ApiConstants.baseUrl + ApiConstants.deactivateUserEndpoint,
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200) {
        debugPrint('Kullanıcı hesabı silindi: ${response.data}');
        return ResponseMessage.fromJson(response.data);
      } else {
        debugPrint('Hesap silme başarısız: ${response.statusCode} - ${response.data}');
        return ResponseMessage.error('Hesap silme başarısız: ${response.data['message'] ?? 'Bilinmeyen hata'}');
      }
    } on DioException catch (e) {
      debugPrint('Hesap silme DioException: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      return ResponseMessage.error(e.response?.data?['message'] ?? 'Bağlantı hatası');
    } catch (e) {
      debugPrint('Hesap silme hatası: ${e}');
      return ResponseMessage.error('Beklenmeyen bir hata oluştu: ${e}');
    }
  }
  
  // Profil bilgilerini yenile (eksplisit olarak çağrılabilir)
  Future<UserProfile> refreshUserProfile() async {
    debugPrint('Profil bilgileri yenileniyor...');
    try {
      // Doğrudan API'dan en güncel profil bilgilerini al
      final userProfile = await getUserProfile();
      
      // getUserProfile metodu zaten SecureStorage'a gerekli bilgileri kaydediyor
      debugPrint('Profil bilgileri başarıyla yenilendi ve SecureStorage güncellendi');
      return userProfile;
    } catch (e) {
      debugPrint('Profil bilgileri yenilenirken hata oluştu: $e');
      rethrow; // Hatayı yukarıya ilet
    }
  }
}

// Profil güncelleme için request modeli (PUT mapping: /v1/api/user/profile)
// Sadece name, surname ve email alanlarını içerir
class UpdateUserRequest {
  final String? name;
  final String? surname;
  final String? email;
  
  UpdateUserRequest({
    this.name,
    this.surname,
    this.email,
  });
  
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (surname != null) data['surname'] = surname;
    if (email != null) data['email'] = email;
    return data;
  }
}