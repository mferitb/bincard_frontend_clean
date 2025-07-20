class RefreshLoginRequest {
  final String refreshToken;
  final String password;
  final String ipAddress;
  final String deviceInfo;
  final String? appVersion;
  final String? platform;

  RefreshLoginRequest({
    required this.refreshToken,
    required this.password,
    required this.ipAddress,
    required this.deviceInfo,
    this.appVersion,
    this.platform,
  });

  Map<String, dynamic> toJson() {
    return {
      'refreshToken': refreshToken,
      'password': password,
      'ipAddress': ipAddress,
      'deviceInfo': deviceInfo,
      if (appVersion != null) 'appVersion': appVersion,
      if (platform != null) 'platform': platform,
    };
  }
}

class RefreshLoginResponse {
  final bool success;
  final String? message;
  final dynamic accessToken;
  final dynamic refreshToken;
  final Map<String, dynamic>? user;

  RefreshLoginResponse({
    required this.success,
    this.message,
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory RefreshLoginResponse.fromJson(Map<String, dynamic> json) {
    return RefreshLoginResponse(
      success: json['success'] ?? false,
      message: json['message'],
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      user: json['user'] != null ? Map<String, dynamic>.from(json['user']) : null,
    );
  }

  factory RefreshLoginResponse.error(String message) {
    return RefreshLoginResponse(
      success: false,
      message: message,
    );
  }
}
