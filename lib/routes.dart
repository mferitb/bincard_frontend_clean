import 'package:flutter/material.dart';

// Ana ekranlar
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/add_balance_screen.dart';
import 'screens/add_card_screen.dart';
import 'screens/saved_cards_screen.dart';
import 'screens/transfer_screen.dart';
import 'screens/card_activities_screen.dart';
import 'screens/qr_code_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/news_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/news_detail_screen.dart';
import 'screens/payment_points_screen.dart';
import 'screens/payment_point_detail_screen.dart';
import 'screens/places_screen.dart';

// Otobüs ile ilgili ekranlar
import 'screens/bus_routes_screen.dart';
import 'screens/bus_tracking_screen.dart';
import 'screens/map_screen.dart';

// Kart işlemleri ile ilgili ekranlar
import 'screens/card_renewal_screen.dart';
import 'screens/virtual_card_screen.dart';

// Arama ve geri bildirim ekranları
import 'screens/search_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/report_problem_screen.dart';
import 'screens/video_player_screen.dart';
import 'screens/news_detail_from_id_screen.dart';

// Kimlik doğrulama ekranları
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/verification_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/login_sms_verify_screen.dart';
import 'screens/auth/refresh_login_screen.dart';

// Widgets
import 'widgets/safe_screen.dart';

class AppRoutes {
  // Route isimleri
  static const String home = '/';
  static const String login = '/login';
  static const String refreshLogin = '/refresh-login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String forgotPasswordSmsVerify = '/forgot-password-sms-verify';
  static const String verification = '/verification';
  static const String resetPassword = '/reset-password';
  static const String loginSmsVerify = '/login-sms-verify';
  static const String profile = '/profile';
  static const String wallet = '/wallet';
  static const String addBalance = '/add-balance';
  static const String addCard = '/add-card';
  static const String savedCards = '/saved-cards';
  static const String transfer = '/transfer';
  static const String cardActivities = '/card-activities';
  static const String qrCode = '/qr-code';
  static const String qrScanner = '/qr-scanner';
  static const String notifications = '/notifications';
  static const String busRoutes = '/bus-routes';
  static const String busTracking = '/bus-tracking';
  static const String map = '/map';
  static const String news = '/news';
  static const String settings = '/settings';
  static const String search = '/search';
  static const String cardRenewal = '/card-renewal';
  static const String virtualCard = '/virtual-card';
  static const String feedback = '/feedback';
  static const String reportProblem = '/report-problem';
  static const String videoPlayer = '/video-player';
  static const String newsDetail = '/news-detail'; // Haber detay sayfası için route
  static const String paymentPoints = '/payment-points';
  static const String paymentPointDetail = '/payment-point-detail';
  static const String places = '/places';

  // Önceki eski referanslar için geçici çözüm
  static const String webView = '/web-view';

  // Tüm route'ları içeren map
  static final routes = <String, WidgetBuilder>{
    home: (context) => const HomeScreen(),
    login: (context) => SafeScreen(
      child: const LoginScreen(),
      warningMessage: 'Giriş ekranından çıkmak için Çıkış butonunu kullanın',
    ),
    register: (context) => SafeScreen(
      child: const RegisterScreen(),
      warningMessage: 'Kayıt işlemini tamamlayın veya Giriş sayfasına dönün',
    ),
    forgotPassword: (context) => SafeScreen(
      child: const ForgotPasswordScreen(),
      warningMessage: 'Şifre sıfırlama işlemini tamamlayın veya Giriş sayfasına dönün',
    ),
    profile: (context) => const ProfileScreen(),
    wallet: (context) => const WalletScreen(),
    addBalance: (context) => const AddBalanceScreen(),
    addCard: (context) => const AddCardScreen(),
    savedCards: (context) => const SavedCardsScreen(),
    transfer: (context) => TransferScreen(wiban: "KULLANICI_WIBAN_DEGERI"),
    notifications: (context) => const NotificationsScreen(),
    busRoutes: (context) => const BusRoutesScreen(),
    busTracking: (context) => const BusTrackingScreen(),
    news: (context) => const NewsScreen(),
    settings: (context) => const SettingsScreen(),
    search: (context) => const SearchScreen(),
    cardRenewal: (context) => const CardRenewalScreen(),
    virtualCard: (context) => const VirtualCardScreen(),
    feedback: (context) => const FeedbackScreen(),
    reportProblem: (context) => const ReportProblemScreen(),
    videoPlayer: (context) => const VideoPlayerScreen(),
    paymentPoints: (context) => const PaymentPointsScreen(),
    places: (context) => const PlacesScreen(),
  };

  // Parametre gerektiren route'lar için generate metodu
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case refreshLogin:
        return MaterialPageRoute(
          builder: (context) => SafeScreen(
            child: const RefreshLoginScreen(),
            warningMessage: 'Giriş işlemini tamamlayın',
          ),
        );
      case verification:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => SafeScreen(
            child: VerificationScreen(
              phoneNumber: args?['phoneNumber'] as String? ?? '',
              isPasswordReset: args?['isPasswordReset'] as bool? ?? false,
            ),
            warningMessage: 'Doğrulama işlemini tamamlayın',
          ),
        );
      case resetPassword:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => SafeScreen(
            child: ResetPasswordScreen(
              phoneNumber: args?['phoneNumber'] as String? ?? '',
              resetToken: args?['resetToken'] as String? ?? '',
            ),
            warningMessage: 'Şifre sıfırlama işlemini tamamlayın',
          ),
        );
      case loginSmsVerify:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => SafeScreen(
            child: LoginSmsVerifyScreen(
              phoneNumber: args?['phoneNumber'] as String? ?? '',
              password: args?['password'] as String? ?? '',
              isPasswordReset: args?['isPasswordReset'] as bool? ?? false,
            ),
            warningMessage: 'SMS doğrulama işlemini tamamlayın',
          ),
        );
      case qrCode:
        final args = settings.arguments as Map<String, dynamic>?;
        final isScanner = args?['isScanner'] as bool? ?? false;
        final cardNumber = args?['cardNumber'] as String?;
        final cardName = args?['cardName'] as String?;
        return MaterialPageRoute(
          builder:
              (context) => QRCodeScreen(
                isScanner: isScanner,
                cardNumber: cardNumber,
                cardName: cardName,
              ),
        );

      case cardActivities:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder:
              (context) => CardActivitiesScreen(
                cardNumber: args['cardNumber'],
                cardName: args['cardName'],
                cardColor: args['cardColor'],
              ),
        );

      case map:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder:
              (context) => MapScreen(
                initialLocation: args?['initialLocation'],
                locationType: args?['locationType'],
              ),
        );

      case busTracking:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder:
              (context) => BusTrackingScreen(busNumber: args?['busNumber']),
        );

      case reportProblem:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder:
              (context) => ReportProblemScreen(
                busNumber: args?['busNumber'],
                busRoute: args?['busRoute'],
              ),
        );

      case videoPlayer:
        return MaterialPageRoute(
          builder: (context) => const VideoPlayerScreen(),
        );

      case newsDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final newsId = args?['newsId'] as int?;
        final news = args?['news'];
        
        if (news != null) {
          // Doğrudan news objesi verilmişse, NewsDetailScreen kullan
          return MaterialPageRoute(
            builder: (context) => NewsDetailScreen(news: news),
          );
        } else if (newsId != null) {
          // Haber ID'sine göre haber detay sayfasına yönlendir
          return MaterialPageRoute(
            builder: (context) => NewsDetailFromIdScreen(newsId: newsId),
          );
        } else {
          // Eğer ne newsId ne de news yoksa, haberlerin listelendiği sayfaya yönlendir
          return MaterialPageRoute(
            builder: (context) => const NewsScreen(),
          );
        }

      case paymentPointDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final paymentPointId = args?['id'] as int?;
        if (paymentPointId == null) {
          return MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(child: Text('Geçersiz ödeme noktası ID')),));
        }
        return MaterialPageRoute(
          builder: (context) => PaymentPointDetailScreen(paymentPointId: paymentPointId!),
        );

      default:
        // Tanımlanmamış bir route için 404 sayfası
        return MaterialPageRoute(
          builder:
              (context) => Scaffold(
                appBar: AppBar(title: const Text('Sayfa Bulunamadı')),
                body: const Center(child: Text('404 - Sayfa Bulunamadı')),
              ),
        );
    }
  }
}
