import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'constants/app_constants.dart';
import 'theme/app_theme.dart';
import 'services/theme_service.dart';
import 'services/language_service.dart';
import 'routes.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'dart:async';
import 'services/secure_storage_service.dart';
import 'services/app_state_service.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'screens/liked_news_screen.dart';
import 'services/map_service.dart';
import 'screens/privacy_settings_screen.dart';
import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/fcm_token_service.dart';

// Global navigatorKey - token service gibi servislerden sayfalar arası geçiş için
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Route observer for debugging
class DebugRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    debugPrint('🔄 Route PUSH: ${route.settings.name} (from: ${previousRoute?.settings.name})');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    debugPrint('🔄 Route REPLACE: ${newRoute?.settings.name} (replaced: ${oldRoute?.settings.name})');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    debugPrint('🔄 Route POP: ${route.settings.name} (back to: ${previousRoute?.settings.name})');
  }
}

// Token kontrolünden muaf tutulacak sayfaların route isimleri
const List<String> tokenExemptRoutes = [
  AppRoutes.login,
  AppRoutes.refreshLogin,
  AppRoutes.register,
  AppRoutes.forgotPassword,
  AppRoutes.forgotPasswordSmsVerify,
  AppRoutes.loginSmsVerify,
  AppRoutes.resetPassword,
  AppRoutes.verification,
  '/splash',
];

// Mevcut route'un token kontrolünden muaf olup olmadığını kontrol et
bool isTokenExemptRoute(String? currentRoute) {
  if (currentRoute == null) return false;
  return tokenExemptRoutes.any((route) => currentRoute.startsWith(route));
}

// Mevcut route'u alma yardımcı fonksiyonu
String? getCurrentRoute() {
  if (navigatorKey.currentState != null && navigatorKey.currentState!.canPop()) {
    return ModalRoute.of(navigatorKey.currentContext!)?.settings.name;
  }
  return null;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // .env içindeki key'leri burada kullanacaksan önemli
  
  // Durum çubuğunu ve sistem gezinti çubuğunu yapılandır
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Uygulama yönünü dikey olarak kilitle
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Tema ve dil servislerini başlat
  final themeService = ThemeService();
  await themeService.initialize();
  
  final languageService = LanguageService();
  await languageService.initialize();
  
  // Auth ve API servislerini başlat
  final apiService = ApiService();
  final authService = AuthService();
  
  // Uygulama önceki oturumda düzgün kapandı mı kontrol et
  final wasClosedProperly = await AppStateService.wasAppClosedProperly();
  
  // Eğer uygulama düzgün kapanmadıysa veya ilk kez başlatılıyorsa
  if (!wasClosedProperly) {
    debugPrint('Uygulama düzgün kapanmamış veya ilk kez başlatılıyor. Otomatik oturum açma devre dışı.');
    // Otomatik oturum açmayı engelle
    await authService.clearTokens();
  } else {
    debugPrint('Uygulama düzgün kapanmış, token kontrolü yapılıyor...');
    // Token kontrolü yap (ama yine de splash screen'den sonra login ekranına yönlendirilecek)
    try {
      await authService.checkAndRefreshToken();
    } catch (e) {
      debugPrint('Token kontrolü sırasında hata: $e');
    }
  }
  
  // Uygulama çıkışta düzgün kapanacak şekilde işaretle
  AppStateService.markAppAsClosed();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeService>.value(value: themeService),
        ChangeNotifierProvider<LanguageService>.value(value: languageService),
        Provider<AuthService>.value(value: authService),
        Provider<ApiService>.value(value: apiService),
        Provider<UserService>(create: (_) => UserService()),
        ChangeNotifierProvider<FcmTokenService>(create: (_) => FcmTokenService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  Timer? _locationTimer;
  bool _locationPermissionGranted = false;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // Yaşam döngüsü değişikliklerini dinle
    WidgetsBinding.instance.addObserver(this);
    
    // Deep linking için initPlatformState metodunu çağır
    _initDeepLinkHandling();
    // Konum izni ve gönderim kontrolünü başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestLocationPermission(context, showMessage: true);
      _startPeriodicLocationSend(context);
      NotificationService().handleNotificationFlow(); // FCM token gönderimini başlat
    });
  }
  
  // Deep linking için gerekli hazırlıkları yap
  Future<void> _initDeepLinkHandling() async {
    _appLinks = AppLinks();
    
    // Uygulama başlatıldığında gelen deep link'i al
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        debugPrint('🔗 İlk açılışta deep link yakalandı: $uri');
        _handleDeepLink(uri);
      }
    } catch (e) {
      debugPrint('Deep link ilk açılışta hata oluştu: $e');
    }
    
    // Uygulama çalışırken gelen deep linkleri dinle
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('🔗 Uygulama çalışırken deep link yakalandı: $uri');
      _handleDeepLink(uri);
    }, onError: (e) {
      debugPrint('Deep link dinlerken hata oluştu: $e');
    });
  }
  
  // Deep link'i işleme fonksiyonu
  void _handleDeepLink(Uri uri) {
    if (!mounted) return;
    
    // Önce kullanıcının giriş yapıp yapmadığını kontrol et
    final authService = Provider.of<AuthService>(context, listen: false);
    
    debugPrint('🔗 Deep link işleniyor: $uri, host: ${uri.host}, path: ${uri.path}');
    
    if (uri.host == 'news-detail' || uri.path.contains('/news/')) {
      // URI'den haber ID'sini çıkart
      String? newsId;
      
      if (uri.host == 'news-detail') {
        newsId = uri.queryParameters['id'];
      } else if (uri.path.contains('/news/')) {
        // /news/{id} formatındaki path'i işle
        final pathSegments = uri.pathSegments;
        final newsIndex = pathSegments.indexOf('news');
        if (newsIndex >= 0 && newsIndex < pathSegments.length - 1) {
          newsId = pathSegments[newsIndex + 1];
        }
      }
      
      if (newsId != null && newsId.isNotEmpty) {
        try {
          final id = int.parse(newsId);
          debugPrint('🔗 Haber ID: $id için deep link yönlendirmesi yapılıyor');
          
          authService.checkToken().then((hasToken) {
            if (hasToken) {
              // Kullanıcı giriş yapmışsa, doğrudan haber detay sayfasına yönlendir
              navigatorKey.currentState?.pushNamed(
                AppRoutes.newsDetail,
                arguments: {'newsId': id},
              );
            } else {
              // Kullanıcı giriş yapmamışsa, login ekranına yönlendir
              // ve başarılı girişten sonra haber detay sayfasına yönlendirmek için bilgiyi sakla
              final secureStorage = SecureStorageService();
              secureStorage.write('pendingDeepLink', uri.toString()).then((_) {
                debugPrint('🔗 Bekleyen deep link kaydedildi: ${uri.toString()}');
                
                // Kullanıcıya bilgi mesajı göster ve login ekranına yönlendir
                if (navigatorKey.currentContext != null) {
                  final snackBar = SnackBar(
                    content: const Text('Bu içeriği görüntülemek için lütfen giriş yapın'),
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                  );
                  
                  ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(snackBar);
                  
                  // Kısa bir gecikme ile login ekranına yönlendir
                  Future.delayed(const Duration(milliseconds: 500), () {
                    navigatorKey.currentState?.pushNamed(AppRoutes.login);
                  });
                }
              });
            }
          });
        } catch (e) {
          debugPrint('Deep link parametresi ayrıştırılırken hata: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    // Deep link aboneliğini iptal et
    _linkSubscription?.cancel();
    
    // Dinlemeyi durdur
    WidgetsBinding.instance.removeObserver(this);
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama arka plana geçtiğinde veya kapatıldığında
    if (state == AppLifecycleState.detached || state == AppLifecycleState.paused) {
      AppStateService.markAppAsClosed();
      _locationTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      // Uygulama tekrar öne geldiğinde izin ve gönderim kontrolü
      _checkAndRequestLocationPermission(context, showMessage: true);
      _startPeriodicLocationSend(context);
    }
  }

  Future<void> _checkAndRequestLocationPermission(BuildContext context, {bool showMessage = false}) async {
    final mapService = MapService();
    final locationTrackingEnabled = await mapService.isLocationTrackingEnabled();
    if (!locationTrackingEnabled) return;
    final granted = await mapService.checkLocationPermission();
    _locationPermissionGranted = granted;
    if (!granted) {
      // Bugün izin istendi mi kontrol et
      final requestedToday = await mapService.isPermissionRequestedToday();
      // Sadece ana ekranda (home) konum SnackBar'ı göster, diğer tüm ekranlarda gösterme
      final currentRoute = ModalRoute.of(navigatorKey.currentContext!)?.settings.name;
      if (!requestedToday && context.mounted && showMessage && currentRoute == AppRoutes.home) {
        if (navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            const SnackBar(content: Text('Lütfen konum izni verin, uygulama tam çalışabilmesi için gereklidir.')),
          );
        }
      }
      return;
    }
    // İzin verildiyse hemen konumu gönder
    final pos = await mapService.getCurrentLocation();
    if (pos != null) {
      await mapService.sendLocationToApi(pos.latitude, pos.longitude);
    }
  }

  void _startPeriodicLocationSend(BuildContext context) {
    _locationTimer?.cancel();
    // 5 dakikada bir çalışacak timer başlat
    _locationTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      final mapService = MapService();
      final locationTrackingEnabled = await mapService.isLocationTrackingEnabled();
      if (!locationTrackingEnabled) return;
      if (!_locationPermissionGranted) return;
      final pos = await mapService.getCurrentLocation();
      if (pos != null) {
        await mapService.sendLocationToApi(pos.latitude, pos.longitude);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Periyodik token kontrolü başlat (5 dakikada bir) - Geçici olarak devre dışı
    startPeriodicTokenCheck(context);
    debugPrint('⚠️ Periodic token check geçici olarak devre dışı bırakıldı');
    
    return Consumer2<ThemeService, LanguageService>(
      builder: (context, themeService, languageService, child) {
        return MaterialApp(
          title: 'BinCard',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          navigatorObservers: [
            // Route değişikliklerini log'la
            DebugRouteObserver(),
            routeObserver, // Beğendiğim Haberler için
          ],
          theme: AppTheme.lightTheme,
          // darkTheme ve themeMode kaldırıldı
          locale: languageService.locale,
          initialRoute: '/splash', // Uygulama her zaman Splash Screen'den başlayacak
          routes: {
            ...AppRoutes.routes,
            '/splash': (context) => const SplashScreen(), // Splash Screen'i routes'a ekle
          },
          onGenerateRoute: AppRoutes.generateRoute,
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Sayfa Bulunamadı')),
                body: const Center(child: Text('404 - Sayfa Bulunamadı')),
              ),
            );
          },
        );
      },
    );
  }
  
  // Periyodik token kontrolü için background timer
  void startPeriodicTokenCheck(BuildContext context) {
    // Her 5 dakikada bir token kontrolü yap (300 saniye)
    const duration = Duration(seconds: 300);
    
    debugPrint('Periyodik token kontrolü başlatıldı (5 dakikada bir)');
    
    Timer.periodic(duration, (timer) async {
      // Mevcut route'u kontrol et
      final currentRoute = getCurrentRoute();
      if (isTokenExemptRoute(currentRoute)) {
        debugPrint('Token kontrolünden muaf sayfa: $currentRoute, periyodik kontrol atlanıyor');
        return;
      }
      
      // Refresh login sayfasındaysak, token kontrolü yapma
      if (currentRoute == AppRoutes.refreshLogin) {
        debugPrint('Refresh login sayfasında, periyodik token kontrolü atlanıyor');
        return;
      }
      
      debugPrint('Periyodik token kontrolü çalışıyor...');
      try {
        final authService = AuthService();
        final secureStorage = SecureStorageService();
        
        // Access token kontrolü
        final isValid = await authService.checkAndRefreshToken();
        
        if (!isValid) {
          // Refresh token kontrolü
          final refreshToken = await secureStorage.getRefreshToken();
          final refreshTokenExpiry = await secureStorage.getRefreshTokenExpiry();
          
          bool refreshTokenValid = false;
          if (refreshToken != null && refreshTokenExpiry != null) {
            final expiry = DateTime.parse(refreshTokenExpiry);
            refreshTokenValid = DateTime.now().isBefore(expiry);
          }
          
          if (navigatorKey.currentContext != null) {
            if (refreshTokenValid) {
              // Refresh token geçerliyse refresh login sayfasına yönlendir
              debugPrint('Access token geçersiz, refresh token geçerli, refresh login sayfasına yönlendiriliyor');
              Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
                AppRoutes.refreshLogin, (route) => false);
            } else {
              // Refresh token da geçersizse login sayfasına yönlendir
              debugPrint('Token ve refresh token geçersiz, login sayfasına yönlendiriliyor');
              Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
                AppRoutes.login, (route) => false);
            }
          }
        } else {
          debugPrint('Token kontrolü başarılı, oturum aktif');
        }
      } catch (e) {
        debugPrint('Periyodik token kontrolü hatası: $e');
      }
    });
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // String? _envError; // .env kontrolü kaldırıldı

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // .env kontrolü kaldırıldı, doğrudan token kontrolüne geç
      _checkTokenAndNavigate();
    });
  }

  Future<void> _checkTokenAndNavigate() async {
    try {
      // Small delay to show the splash screen
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return; // Widget'ın hala ağaçta olup olmadığını kontrol et

      // Refresh token kontrolü
      final secureStorage = SecureStorageService();
      final refreshToken = await secureStorage.getRefreshToken();
      final refreshTokenExpiry = await secureStorage.getRefreshTokenExpiry();

      // Refresh token geçerlilik kontrolü
      bool refreshTokenValid = false;
      if (refreshToken != null && refreshTokenExpiry != null) {
        final expiry = DateTime.parse(refreshTokenExpiry);
        refreshTokenValid = DateTime.now().isBefore(expiry);
        debugPrint('Refresh token geçerli mi: $refreshTokenValid, sona erme: $expiry');
      }
      
      if (!refreshTokenValid || refreshToken == null) {
        // Refresh token yoksa veya geçersizse direkt login sayfasına yönlendir
        debugPrint('Refresh token yok veya geçersiz, login sayfasına yönlendiriliyor');
        Navigator.pushReplacementNamed(context, AppRoutes.login);
        return;
      }
      
      // Refresh token varsa ve geçerliyse refresh login sayfasına yönlendir
      debugPrint('Refresh token geçerli, refresh login sayfasına yönlendiriliyor');
      Navigator.pushReplacementNamed(context, AppRoutes.refreshLogin);
    } catch (e) {
      debugPrint('Splash ekranından yönlendirme hatası: $e');
      if (mounted) {
        // Hata durumunda normal login sayfasına yönlendir
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // .envError kontrolü ve hata ekranı kaldırıldı
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo2.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}