class ApiConstants {
  // Base URL for API requests
  // Updated API URL
  static const String baseUrl = 'http://192.168.219.61:8080/v1/api';
  
  // Ortam değişkenleri
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // API endpoints
  // Auth endpoints
  static String get loginEndpoint => '/auth/login';
  static String get signUpEndpoint => '/user/sign-up';
  static String get refreshTokenEndpoint => '/auth/refresh';  // Updated to match actual usage
  static String get verifyCodeEndpoint => '/auth/verify-code';
  static String get resendCodeEndpoint => '/auth/resend-verify-code';
  static String get forgotPasswordEndpoint => '/auth/forgot-password';
  static String get resetPasswordEndpoint => '/auth/reset-password';
  static String get refreshLoginEndpoint => '/auth/refresh-login';
  static String get refreshLogin => '/auth/refresh-login'; // Backward compatibility
  
  // Password reset endpoints
  static String get passwordForgotEndpoint => '/user/password/forgot';
  static String get passwordVerifyCodeEndpoint => '/user/password/verify-code';
  static String get passwordResetEndpoint => '/user/password/reset';
  static String get passwordResendCodeEndpoint => '/user/password/resend-code';
  
  // User endpoints
  static String get userProfileEndpoint => '/user/profile';  // GET/PUT: Kullanıcı profilini al veya güncelle
  static String get updateUserEndpoint => '/user/update';
  static String get updateProfileEndpoint => '/user/profile';  // PUT: Profil bilgilerini güncelle
  static String get updateProfilePhotoEndpoint => '/user/profile/photo';  // PUT: Profil fotoğrafını güncelle
  static String get verifyPhoneEndpoint => '/user/verify-phone';
  static String get changePasswordEndpoint => '/user/password/change';
  static String updateFcmTokenEndpoint(String fcmToken) => '/user/update-fcm-token?fcmToken=$fcmToken';
  
  // News endpoints
  static String get newsBaseEndpoint => '/news';
  static String get newsActiveEndpoint => '/news/active';
  static String get newsByCategoryEndpoint => '/news/by-category';
  static String get newsViewHistoryEndpoint => '/news/view-history';
  static String get newsSuggestedEndpoint => '/news/suggested';
  static String newsDetailEndpoint(String newsId) => '/news/$newsId';
  static String newsLikeEndpoint(String newsId) => '/news/$newsId/like';
  static String newsUnlikeEndpoint(String newsId) => '/news/$newsId/unlike';
  static String get newsLikedEndpoint => '/news/liked';
  static String newsDetailWithPlatformEndpoint(String newsId, {String platform = 'MOBILE'}) => '/news/$newsId?platform=$platform';
  
  // Payment Point endpoints
  static String get paymentPointBase => '/payment-point';
  static String paymentPointById(int id) => '/payment-point/$id';
  static String get paymentPointSearch => '/payment-point/search';
  static String get paymentPointNearby => '/payment-point/nearby';
  static String paymentPointByCity(String city) => '/payment-point/by-city/$city';
  static String paymentPointByPaymentMethod(String method) => '/payment-point/by-payment-method?paymentMethod=$method';
  // Nearby payment points endpoint (query parametreli)
  static String paymentPointNearbyWithParams({required double latitude, required double longitude, double radiusKm = 1.0, int page = 0, int size = 10, String sort = 'distance,asc'}) {
    return '/payment-point/nearby?latitude=$latitude&longitude=$longitude&radiusKm=$radiusKm&page=$page&size=$size&sort=$sort';
  }

  // Location endpoint
  static String get userLocationEndpoint => '/user/location';
  
  // Content Type ve diğer header'lar
  static const String contentType = 'application/json';
  
  // API Headers
  static Map<String, String> get headers => {
    'Content-Type': contentType,
    'Accept': 'application/json',
  };
  
  // Add auth header with token
  static Map<String, String> getAuthHeaders(String token) {
    return {
      ...headers,
      'Authorization': 'Bearer $token',
    };
  }

  // Wallet endpoints
  static String get myWalletEndpoint => '/wallet/my-wallet';
  static String get topUpWalletEndpoint => '/wallet/top-up';
  static String get transferWalletEndpoint => '/wallet/transfer';
  static String get createWalletEndpoint => '/wallet/create';
  static String walletNameEndpoint(String input) => '/wallet/name?input=$input';
  static String walletActivitiesEndpoint({String? type, String? start, String? end, int page = 0, int size = 20, String sort = 'activityDate,desc'}) {
    final params = <String, String>{
      if (type != null) 'type': type,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      'page': page.toString(),
      'size': size.toString(),
      'sort': sort,
    };
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '/wallet/activities?$query';
  }

  static String get notifications => '/notifications';
  static String notificationDetail(int id) => '/notifications/$id';
  static String get notificationCount => '/notifications/count';
}
