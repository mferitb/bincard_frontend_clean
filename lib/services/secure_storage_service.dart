import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // EncryptedSharedPreferences kullanımı
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock, // İlk kilit açıldığında erişilebilir
    ),
  );

  // Kullanılacak anahtar isimleri
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _accessTokenExpiryKey = 'access_token_expiry';
  static const String _refreshTokenExpiryKey = 'refresh_token_expiry';
  static const String _userFirstNameKey = 'user_first_name';
  static const String _userLastNameKey = 'user_last_name';
  static const String _userPhoneKey = 'user_phone'; // Telefon numarası için anahtar
  static const String _userIdKey = 'user_id'; // Kullanıcı ID'si için anahtar

  // Singleton pattern
  static final SecureStorageService _instance = SecureStorageService._internal();
  
  factory SecureStorageService() {
    return _instance;
  }
  
  SecureStorageService._internal();

  // Access token kaydetme
  Future<void> setAccessToken(String token) async {
    await _secureStorage.write(key: _accessTokenKey, value: token);
  }

  // Access token alma
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  // Refresh token kaydetme
  Future<void> setRefreshToken(String token) async {
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  // Refresh token alma
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }
  
  // Kullanıcı bilgilerini kaydetme (JSON string olarak)
  Future<void> setUserData(String userJson) async {
    await _secureStorage.write(key: _userDataKey, value: userJson);
  }

  // Kullanıcı bilgilerini alma
  Future<String?> getUserData() async {
    return await _secureStorage.read(key: _userDataKey);
  }

  // Biyometrik doğrulama tercihini kaydetme
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  // Biyometrik doğrulama tercihini alma
  Future<bool> getBiometricEnabled() async {
    final value = await _secureStorage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  // Tüm verileri silme (çıkış yapma durumunda)
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
  
  // Belirli bir anahtar değerini silme
  Future<void> delete(String key) async {
    await _secureStorage.delete(key: key);
  }
  
  // Sadece token bilgilerini silme
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  // Access token expiry tarihini kaydet
  Future<void> setAccessTokenExpiry(String expiryDate) async {
    await _secureStorage.write(key: _accessTokenExpiryKey, value: expiryDate);
  }
  
  // Access token expiry tarihini al
  Future<String?> getAccessTokenExpiry() async {
    return await _secureStorage.read(key: _accessTokenExpiryKey);
  }
  
  // Sadece Access Token'ı silme
  Future<void> clearAccessToken() async {
    await _secureStorage.delete(key: _accessTokenKey);
  }
  
  // Refresh token expiry tarihini kaydet
  Future<void> setRefreshTokenExpiry(String expiryDate) async {
    await _secureStorage.write(key: _refreshTokenExpiryKey, value: expiryDate);
  }
  
  // Refresh token expiry tarihini al
  Future<String?> getRefreshTokenExpiry() async {
    return await _secureStorage.read(key: _refreshTokenExpiryKey);
  }

  // Kullanıcı adını kaydet
  Future<void> setUserFirstName(String firstName) async {
    await _secureStorage.write(key: _userFirstNameKey, value: firstName);
  }
  
  // Kullanıcı adını al
  Future<String?> getUserFirstName() async {
    return await _secureStorage.read(key: _userFirstNameKey);
  }
  
  // Kullanıcı soyadını kaydet
  Future<void> setUserLastName(String lastName) async {
    await _secureStorage.write(key: _userLastNameKey, value: lastName);
  }
  
  // Kullanıcı soyadını al
  Future<String?> getUserLastName() async {
    return await _secureStorage.read(key: _userLastNameKey);
  }
  
  // Kullanıcı telefon numarasını kaydet
  Future<void> setUserPhone(String phone) async {
    await _secureStorage.write(key: _userPhoneKey, value: phone);
  }
  
  // Kullanıcı telefon numarasını al
  Future<String?> getUserPhone() async {
    return await _secureStorage.read(key: _userPhoneKey);
  }
  
  // Kullanıcı ID'sini kaydet
  Future<void> setUserId(String userId) async {
    await _secureStorage.write(key: _userIdKey, value: userId);
  }
  
  // Kullanıcı ID'sini al
  Future<String?> getUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }

  // Generic key-value operations
  Future<void> write(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }
  
  Future<String?> read(String key) async {
    return await _secureStorage.read(key: key);
  }
  
  // Legacy support (aliasing to existing methods)
  Future<void> setString(String key, String value) async {
    return write(key, value);
  }
  
  Future<String?> getString(String key) async {
    return read(key);
  }
  
  Future<void> deleteKey(String key) async {
    return delete(key);
  }
}