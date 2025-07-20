import 'dart:convert';

class AuthResponse {
  final String? token;
  final String? refreshToken;
  final String? accessToken;
  final String? message;
  final bool success;
  final User? user;

  AuthResponse({
    this.token,
    this.refreshToken,
    this.accessToken,
    this.message,
    this.success = false,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final token = json['token'] ?? json['accessToken'];
    final refreshToken = json['refreshToken'];
    
    final hasTokens = token != null && refreshToken != null;
    
    return AuthResponse(
      token: token,
      accessToken: token,
      refreshToken: refreshToken,
      message: json['message'],
      success: json['success'] ?? hasTokens,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  factory AuthResponse.error(String message) {
    return AuthResponse(message: message, success: false);
  }
  
  factory AuthResponse.success(String message) {
    return AuthResponse(message: message, success: true);
  }
  
  String? get validToken => token ?? accessToken;
}

class User {
  final int? id;
  final String? firstName;
  final String? lastName;
  final String? telephone;
  final String? email;

  User({this.id, this.firstName, this.lastName, this.telephone, this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      telephone: json['telephone'],
      email: json['email'],
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}

class AuthRequest {
  final String telephone;
  final String password;
  final String ipAddress;
  final String deviceInfo;

  AuthRequest({
    required this.telephone,
    required this.password,
    required this.ipAddress,
    required this.deviceInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'telephone': telephone,
      'password': password,
      'ipAddress': ipAddress,
      'deviceInfo': deviceInfo,
    };
  }
}

class ResponseMessage {
  final String? message;
  final bool success;
  final dynamic data;

  ResponseMessage({this.message, this.success = false, this.data});

  factory ResponseMessage.fromJson(Map<String, dynamic> json) {
    return ResponseMessage(
      message: json['message'],
      success: json['success'] ?? false,
      data: json['data'],
    );
  }

  factory ResponseMessage.error(String message) {
    return ResponseMessage(message: message, success: false);
  }
  
  factory ResponseMessage.success(String message) {
    return ResponseMessage(message: message, success: true);
  }
}

class TokenDTO {
  final String token;
  final DateTime expiredAt;
  final DateTime? issuedAt;
  final DateTime? lastUsedAt;
  final String? ipAddress;
  final String? deviceInfo;
  final String? tokenType;

  TokenDTO({
    required this.token,
    required this.expiredAt,
    this.issuedAt,
    this.lastUsedAt,
    this.ipAddress,
    this.deviceInfo,
    this.tokenType,
  });

  // Yardımcı fonksiyon: expiredAt hem int hem string olabilir
  static DateTime _parseDate(dynamic value) {
    if (value is int) {
      // Saniye cinsinden timestamp ise
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    } else if (value is String) {
      return DateTime.parse(value);
    } else {
      throw Exception('expiredAt değeri tanınamadı: $value');
    }
  }

  factory TokenDTO.fromJson(dynamic json) {
    if (json is String) {
      return TokenDTO(
        token: json,
        expiredAt: DateTime.now().add(const Duration(hours: 1)), // Varsayılan süre
      );
    }
    
    if (json is! Map<String, dynamic>) {
      throw Exception('Invalid token format: Expected Map<String, dynamic> but got \\${json.runtimeType}');
    }
    
    final token = json['token'];
    final expiredAt = json['expiredAt'] ?? json['expiresAt']; // Java'da expiresAt
    if (token == null || expiredAt == null) {
      throw Exception('TokenDTO parse error: token or expiredAt/expiresAt is null! Backend response: \\${json.toString()}');
    }
    
    // Parse additional fields
    DateTime? issuedAt;
    if (json['issuedAt'] != null) {
      issuedAt = _parseDate(json['issuedAt']);
    }
    
    DateTime? lastUsedAt;
    if (json['lastUsedAt'] != null) {
      lastUsedAt = _parseDate(json['lastUsedAt']);
    }
    
    return TokenDTO(
      token: token as String,
      expiredAt: _parseDate(expiredAt),
      issuedAt: issuedAt,
      lastUsedAt: lastUsedAt,
      ipAddress: json['ipAddress']?.toString(),
      deviceInfo: json['deviceInfo']?.toString(),
      tokenType: json['tokenType']?.toString(),
    );
  }
  
  // Basit format için alternatif constructor
  factory TokenDTO.fromSimpleJson(dynamic json) {
    if (json is String) {
      return TokenDTO(
        token: json,
        expiredAt: DateTime.now().add(const Duration(hours: 1)), // Varsayılan süre
      );
    }
    
    if (json is! Map<String, dynamic>) {
      throw Exception('Invalid token format: Expected Map<String, dynamic> but got \\${json.runtimeType}');
    }
    final token = json['token'];
    final expiredAt = json['expiredAt'] ?? json['expiresAt'];
    if (token == null || expiredAt == null) {
      throw Exception('TokenDTO simple parse error: token or expiredAt/expiresAt is null! Backend response: \\${json.toString()}');
    }
    return TokenDTO(
      token: token as String,
      expiredAt: _parseDate(expiredAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'expiredAt': expiredAt.toIso8601String(),
      if (issuedAt != null) 'issuedAt': issuedAt!.toIso8601String(),
      if (lastUsedAt != null) 'lastUsedAt': lastUsedAt!.toIso8601String(),
      if (ipAddress != null) 'ipAddress': ipAddress,
      if (deviceInfo != null) 'deviceInfo': deviceInfo,
      if (tokenType != null) 'tokenType': tokenType,
    };
  }
  
  // Token'ın süresinin dolmasına kalan süreyi hesapla (saniye cinsinden)
  int get remainingTime {
    final now = DateTime.now();
    return expiredAt.difference(now).inSeconds;
  }
  
  // Token'ın süresinin dolup dolmadığını kontrol et
  bool get isExpired {
    final now = DateTime.now();
    return now.isAfter(expiredAt);
  }
  
  // Token'ın süresinin dolmasına yakın olup olmadığını kontrol et (varsayılan 30 saniye)
  bool isAboutToExpire({int thresholdSeconds = 30}) {
    return remainingTime <= thresholdSeconds;
  }
}

class TokenResponseDTO {
  final TokenDTO accessToken;
  final TokenDTO refreshToken;

  TokenResponseDTO({
    required this.accessToken,
    required this.refreshToken,
  });

  factory TokenResponseDTO.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      throw Exception('Invalid token response format: Expected Map<String, dynamic> but got \\${json.runtimeType}');
    }
    try {
      // accessToken ve refreshToken string olarak gelirse de işle
      final accessTokenRaw = json['accessToken'];
      final refreshTokenRaw = json['refreshToken'];
      
      // API response format kontrolü
      if (accessTokenRaw == null || refreshTokenRaw == null) {
        throw Exception('Token response error: accessToken or refreshToken is null! Backend response: \\${json.toString()}');
      }
      
      // Token nesneleri oluştur (hem string hem de obje formatını destekle)
      final accessToken = accessTokenRaw is String
          ? TokenDTO(
              token: accessTokenRaw,
              expiredAt: DateTime.now().add(const Duration(hours: 1)), // Varsayılan süre
            )
          : TokenDTO.fromJson(accessTokenRaw);
          
      final refreshToken = refreshTokenRaw is String
          ? TokenDTO(
              token: refreshTokenRaw,
              expiredAt: DateTime.now().add(const Duration(days: 30)), // Varsayılan süre
            )
          : TokenDTO.fromJson(refreshTokenRaw);
          
      return TokenResponseDTO(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } catch (e) {
      // Alternatif format deneme
      if (json.containsKey('token') && (json.containsKey('expiredAt') || json.containsKey('expiresAt'))) {
        final token = TokenDTO.fromJson(json);
        return TokenResponseDTO(
          accessToken: token,
          refreshToken: token,
        );
      }
      rethrow;
    }
  }
  
  // Basit response için alternatif constructor (sadece token ve expiredAt içeren)
  factory TokenResponseDTO.fromSimpleJson(dynamic json) {
    // Eğer json bir String ise, önce onu parse etmeye çalış
    if (json is String) {
      try {
        // String'i JSON olarak parse etmeye çalış
        final parsedJson = jsonDecode(json);
        return TokenResponseDTO.fromSimpleJson(parsedJson);
      } catch (e) {
        // Eğer parse edilemiyorsa, sadece token olarak kabul et
        final accessToken = TokenDTO(
          token: json,
          expiredAt: DateTime.now().add(const Duration(hours: 1)), // Varsayılan süre
        );
        
        return TokenResponseDTO(
          accessToken: accessToken,
          refreshToken: accessToken, // Geçici olarak aynı token kullanılabilir
        );
      }
    }
    
    // JSON bir Map değilse hata fırlat
    if (json is! Map<String, dynamic>) {
      throw Exception('Invalid token response format: Expected Map<String, dynamic> but got ${json.runtimeType}');
    }
    
    // Token nesneleri varsa standart formatı kullan
    if (json.containsKey('accessToken') && json['accessToken'] is Map<String, dynamic>) {
      return TokenResponseDTO.fromJson(json);
    }
    
    // Basit format - tek access token ve expiredAt içerir
    if (json.containsKey('token') && json.containsKey('expiredAt')) {
      final accessToken = TokenDTO(
        token: json['token'] as String,
        expiredAt: DateTime.parse(json['expiredAt'] as String),
      );
      
      // Refresh token için de accessToken kullan (daha sonra refresh endpoint'ten güncellenecek)
      return TokenResponseDTO(
        accessToken: accessToken,
        refreshToken: accessToken, // Geçici olarak aynı token kullanılabilir
      );
    }
    
    throw Exception('Invalid token response format');
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken.toJson(),
      'refreshToken': refreshToken.toJson(),
    };
  }
}

class UpdateAccessTokenRequestDTO {
  final String refreshToken;
  final String ipAddress;
  final String deviceInfo;

  UpdateAccessTokenRequestDTO({
    required this.refreshToken,
    required this.ipAddress,
    required this.deviceInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'refreshToken': refreshToken,
      'ipAddress': ipAddress,
      'deviceInfo': deviceInfo,
    };
  }
}
