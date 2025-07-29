import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;
import 'profile_screen.dart';
import 'wallet_screen.dart';
import 'add_balance_screen.dart';
import 'add_card_screen.dart';
import 'saved_cards_screen.dart';
import 'card_activities_screen.dart';
import 'qr_code_screen.dart';
import 'notifications_screen.dart';
import 'bus_routes_screen.dart';
import 'bus_tracking_screen.dart';
import 'news_screen.dart';
import 'settings_screen.dart';
import 'search_screen.dart';
import 'feedback_screen.dart';
import 'wallet_create_screen.dart';
import 'map_screen.dart';
import 'card_renewal_screen.dart';
import '../services/secure_storage_service.dart';
import '../services/user_service.dart';
import '../services/news_service.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/news/news_page.dart';
import '../models/news/user_news_dto.dart';
import '../models/news/platform_type.dart';
import '../models/news/news_type.dart';
import '../models/news/news_priority.dart';
import 'news_detail_screen.dart';
import '../widgets/video_player_widget.dart';
import 'news_detail_from_id_screen.dart';
import 'payment_points_screen.dart';
import 'places_screen.dart';
import 'package:provider/provider.dart';
import '../services/fcm_token_service.dart';
import 'package:shimmer/shimmer.dart';
import '../services/weather_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  String _userName = ""; // Kullanıcı adını tutacak değişken
  bool _isLoadingNews = false;
  List<UserNewsDTO> _newsList = [];
  // Pagination properties
  int _currentPage = 0;
  int _totalPages = 0;
  bool _hasMoreNews = true;
  
  // Kullanıcının kayıtlı kartları
  final List<Map<String, dynamic>> _cards = [
    {
      'name': 'Şehir Kartı',
      'number': '5312 **** **** 3456',
      'balance': '257,50 ₺',
      'expiryDate': '12/25',
      'isActive': true,
      'color': AppTheme.blueGradient,
    },
    {
      'name': 'İkinci Kartım',
      'number': '4728 **** **** 9012',
      'balance': '125,75 ₺',
      'expiryDate': '08/24',
      'isActive': true,
      'color': AppTheme.greenGradient,
    },
  ];
  
  Map<String, dynamic>? _walletData;
  String? _walletError;
  bool _isWalletLoading = false;
  final ScrollController _newsScrollController = ScrollController();
  WeatherData? _weatherData;
  bool _isWeatherLoading = false;
  String? _weatherError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    
    // Kullanıcı adını al
    _loadUserName();
    
    // Haberleri yükle
    _loadNews();
    // Scroll listener ekle
    _newsScrollController.addListener(_onNewsScroll);
    _fetchWallet();
    _fetchWeather();
  }
  
  // Haberleri servis üzerinden al
  Future<void> _loadNews({bool refresh = false}) async {
    if (_isLoadingNews) return;
    
    // If refreshing, reset page to 0
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _newsList = [];
        _hasMoreNews = true;
      });
    }
    
    // If no more news and not refreshing, don't load
    if (!_hasMoreNews && !refresh) return;
    
    setState(() {
      _isLoadingNews = true;
    });
    
    try {
      // ApiService oluştur ve token interceptor'ı ekle
      final apiService = ApiService();
      apiService.setupTokenInterceptor();
      
      final newsService = NewsService(apiService: apiService);
      final newsPage = await newsService.getActiveNewsWithCache(
        platform: PlatformType.MOBILE,
        page: _currentPage,
        size: 2,
      );
      
      setState(() {
        if (refresh) {
          _newsList = newsPage.content;
        } else {
          _newsList = [..._newsList, ...newsPage.content];
        }
        _currentPage = newsPage.pageNumber + 1;
        _totalPages = newsPage.totalPages;
        _hasMoreNews = !newsPage.isLast;
        _isLoadingNews = false;
      });
    } catch (e) {
      debugPrint('Haberler yüklenirken hata: $e');
      setState(() {
        _isLoadingNews = false;
      });
    }
  }
  
  // Kullanıcı adını güvenli depolamadan yükle
  Future<void> _loadUserName() async {
    final secureStorage = SecureStorageService();
    final firstName = await secureStorage.getUserFirstName();
    
    if (firstName != null && firstName.isNotEmpty) {
      setState(() {
        _userName = firstName;
      });
    } else {
      // Adı bulamadıysak, önce kullanıcı servisinden profili almayı deneyelim
      try {
        final userService = UserService();
        final userProfile = await userService.getUserProfile();
        
        if (userProfile.name != null && userProfile.name!.isNotEmpty) {
          setState(() {
            _userName = userProfile.name!;
          });
        } else {
          setState(() {
            _userName = "Misafir"; // Eğer ad bulunamazsa varsayılan değer
          });
        }
      } catch (e) {
        debugPrint('Kullanıcı profili yüklenirken hata: $e');
        setState(() {
          _userName = "Misafir"; // Hata durumunda varsayılan değer
        });
      }
    }
  }
  
  // Kullanıcının haberlerini yükle
  Future<void> _loadUserNews() async {
    setState(() {
      _isLoadingNews = true;
    });
    
    try {
      // ApiService oluştur ve token interceptor'ı ekle
      final apiService = ApiService();
      apiService.setupTokenInterceptor();
      
      final newsService = NewsService(apiService: apiService);
      //final userId = await (SecureStorageService().getUserId() ?? '');
      //final news = await newsService.getUserNews(userId: userId);
      final newsPage = await newsService.getActiveNews(platform: PlatformType.MOBILE);
      
      setState(() {
        _newsList = newsPage.content;
      });
    } catch (e) {
      debugPrint('Haberler yüklenirken hata: $e');
    } finally {
      setState(() {
        _isLoadingNews = false;
      });
    }
  }

  Future<void> _fetchWallet() async {
    setState(() {
      _isWalletLoading = true;
      _walletError = null;
    });
    try {
      final api = ApiService();
      final response = await api.get(ApiConstants.baseUrl + '/wallet/my-wallet');
      if (response.data['success'] == false && response.data['message'] != null) {
        setState(() {
          _walletData = null;
          _walletError = response.data['message'];
        });
      } else {
        setState(() {
          _walletData = response.data;
          _walletError = null;
        });
      }
    } catch (e) {
      setState(() {
        _walletData = null;
        _walletError = 'Cüzdan bilgisi alınamadı';
      });
    } finally {
      setState(() {
        _isWalletLoading = false;
      });
    }
  }

  Future<void> _fetchWeather() async {
    debugPrint('[_fetchWeather] Fonksiyon çağrıldı');
    setState(() {
      _isWeatherLoading = true;
      _weatherError = null;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[_fetchWeather] Konum servisi aktif mi: $serviceEnabled');
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('[_fetchWeather] Konum izni: $permission');
      if (!serviceEnabled) {
        setState(() {
          _isWeatherLoading = false;
          _weatherError = 'Konum servisi kapalı.';
        });
        debugPrint('[_fetchWeather] Konum servisi kapalı, çıkılıyor');
        return;
      }
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('[_fetchWeather] Konum izni tekrar soruldu, yeni durum: $permission');
        if (permission == LocationPermission.denied) {
          setState(() {
            _isWeatherLoading = false;
            _weatherError = 'Konum izni reddedildi.';
          });
          debugPrint('[_fetchWeather] Konum izni reddedildi, çıkılıyor');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isWeatherLoading = false;
          _weatherError = 'Konum izni kalıcı olarak reddedildi.';
        });
        debugPrint('[_fetchWeather] Konum izni kalıcı olarak reddedildi, çıkılıyor');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      debugPrint('[_fetchWeather] Kullanıcı konumu: ${pos.latitude}, ${pos.longitude}');
      final weatherService = WeatherService();
      final weather = await weatherService.getWeather(pos.latitude, pos.longitude);
      debugPrint('[_fetchWeather] Weather response: $weather');
      if (weather == null) {
        setState(() {
          _weatherData = null;
          _isWeatherLoading = false;
          _weatherError = 'Hava durumu alınamadı.';
        });
        debugPrint('[_fetchWeather] Hava durumu alınamadı, null response');
      } else {
        setState(() {
          _weatherData = weather;
          _isWeatherLoading = false;
          _weatherError = null;
        });
        debugPrint('[_fetchWeather] Hava durumu başarıyla alındı: ${weather.temperature}°C, ${weather.description}');
      }
    } catch (e) {
      debugPrint('[_fetchWeather] Hava durumu çekme hatası: $e');
      setState(() {
        _isWeatherLoading = false;
        _weatherError = 'Hava durumu alınırken hata oluştu.';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _newsScrollController.dispose();
    super.dispose();
  }

  // Scroll ile aşağı inince yeni sayfa yükle
  void _onNewsScroll() {
    if (_newsScrollController.position.pixels >= _newsScrollController.position.maxScrollExtent - 100) {
      if (!_isLoadingNews && _hasMoreNews) {
        _loadNews();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fcmToken = Provider.of<FcmTokenService>(context).token;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadNews(refresh: true);
          },
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 20.0,
                    right: 20.0,
                    top: 16.0,
                    bottom: 8.0,
                  ),
                  child: _buildWelcomeHeader(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildBalanceSummary(),
                    const SizedBox(height: 28),
                    _buildBusCardsSection(),
                    const SizedBox(height: 28),
                    _buildQuickActionsSection(),
                    const SizedBox(height: 28),
                    _buildMainServicesGrid(),
                    const SizedBox(height: 28),
                    _buildNewsSliderSection(),
                    const SizedBox(height: 120), // Increased bottom padding for scroll
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        elevation: 10,
        color: Colors.white,
        shadowColor: Colors.black.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Ana Sayfa',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.credit_card_rounded,
                label: 'Kartlarım',
                index: 1,
              ),
              const SizedBox(width: 40), // Orta boşluk (FAB için)
              _buildNavItem(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Cüzdan',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: 'Profil',
                index: 3,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 10),
        child: FloatingActionButton(
          onPressed: () {
            // QR Kod tarama sayfasına yönlendir
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QRCodeScreen(isScanner: true),
              ),
            );
          },
          backgroundColor: AppTheme.primaryColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 26),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
  
  // Bottom navigation bar item
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SavedCardsScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WalletScreen(),
              ),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            );
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // AppBar
  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      toolbarHeight: 70,
      backgroundColor: AppTheme.surfaceColor,
      elevation: 1,
      leadingWidth: 0,
      titleSpacing: 20,
      title: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.indigoAccent, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.1, 0.9],
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            child: Text(
              'BinCard',
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Spacer(),
          _buildAppBarAction(Icons.search, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          }),
          const SizedBox(width: 12),
          _buildAppBarAction(Icons.notifications_outlined, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAppBarAction(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.dividerColor,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
      ),
    );
  }

  // Balance summary section - Modern and elegant design
  Widget _buildBalanceSummary() {
    if (_isWalletLoading) {
      // Shimmer efekti ile cüzdan yükleniyor göstergesi
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: double.infinity,
          height: 140,
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      );
    }
    if (_walletError != null || _walletData == null) {
      return const SizedBox.shrink(); // Don't show anything if wallet doesn't exist or error
    }
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          // Cüzdan kartı
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)], // Daha belirgin mavi tonlar
                stops: const [0.3, 1.0],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WalletScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 38),
                          const SizedBox(width: 14),
                          Text(
                            'Cüzdanım',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Toplam Bakiye',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (_walletData!['balance'] ?? 0).toString() + ' ₺',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Son Güncelleme: ' + _formatDate(_walletData!['lastUpdated']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      if (_walletData!['wiban'] != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'WIBAN: ' + _walletData!['wiban'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddBalanceScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Bakiye Yükle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/transfer');
                  },
                  icon: const Icon(Icons.sync_alt),
                  label: const Text('Transfer Yap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Otobüs Kartları bölümü
  Widget _buildBusCardsSection() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.credit_card,
                        color: AppTheme.primaryColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Kartlarım',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SavedCardsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.arrow_forward,
                    size: 16,
                  ),
                  label: const Text(
                    'Tümünü Gör',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 175,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _cards.length + 1, // +1 for add card button
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              itemBuilder: (context, index) {
                if (index == _cards.length) {
                  return _buildAddCardButton();
                }
                return _buildCardItem(_cards[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCardItem(Map<String, dynamic> card) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: card['color'],
              stops: const [0.3, 1.0],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    card['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Transform.rotate(
                      angle: math.pi / 4,
                      child: Icon(
                        Icons.wifi,
                        color: Colors.white.withOpacity(0.9),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                card['number'],
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BAKİYE',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card['balance'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddBalanceScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: card['color'][0],
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Yükle',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAddCardButton() {
    return Container(
      width: 125,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddCardScreen()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Kart Ekle',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    final quickActions = [
      {
        'icon': Icons.directions_bus,
        'label': 'Hatlar',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BusRoutesScreen()),
        ),
      },
      {
        'icon': Icons.location_on,
        'label': 'Otobüs Takip',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BusTrackingScreen()),
        ),
      },
      {
        'icon': Icons.qr_code,
        'label': 'QR Ödeme',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const QRCodeScreen(isScanner: false)),
        ),
      },
      {
        'icon': Icons.map,
        'label': 'Ödeme Noktaları',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PaymentPointsScreen()),
        ),
      },
      // Yakındaki Yerler kaldırıldı
    ];

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Hızlı İşlemler',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(quickActions.length, (index) {
                final action = quickActions[index];
                return Expanded(
                  child: _buildQuickActionButton(
                    icon: action['icon'] as IconData,
                    label: action['label'] as String,
                    onTap: action['onTap'] as VoidCallback,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Container(
          constraints: const BoxConstraints(minHeight: 80),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 56,
                width: 56,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainServicesGrid() {
    final mainServices = [
      {
        'icon': Icons.place,
        'label': 'Yakındaki Yerler',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PlacesScreen()),
        ),
      },
      {
        'icon': Icons.card_membership,
        'label': 'Kart Yenileme',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CardRenewalScreen()),
        ),
      },
      {
        'icon': Icons.newspaper,
        'label': 'Haberler',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NewsScreen()),
        ),
      },
      {
        'icon': FontAwesomeIcons.clockRotateLeft,
        'label': 'Geçmiş',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CardActivitiesScreen(
              cardNumber: '5312 **** **** 3456',
              cardName: 'Ahmet Yılmaz',
              cardColor: AppTheme.blueGradient,
            ),
          ),
        ),
      },
      {
        'icon': Icons.help_outline,
        'label': 'Geri Bildirim',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FeedbackScreen()),
        ),
      },
      {
        'icon': Icons.settings,
        'label': 'Ayarlar',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        ),
      },
    ];

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.apps,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Diğer Hizmetler',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: constraints.maxWidth < 400 ? 0.95 : 1.1,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: mainServices.length,
                  itemBuilder: (context, index) {
                    final service = mainServices[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6), // Extra bottom padding to avoid overflow
                      child: _buildServiceItem(
                        icon: service['icon'] as IconData,
                        label: service['label'] as String,
                        onTap: service['onTap'] as VoidCallback,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // News slider section
  Widget _buildNewsSliderSection() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.newspaper,
                        color: AppTheme.primaryColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Güncel Haberler',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NewsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.arrow_forward,
                    size: 16,
                  ),
                  label: const Text(
                    'Tümünü Gör',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _isLoadingNews && _newsList.isEmpty
              ? SizedBox(
                  height: 250,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 2,
                    itemBuilder: (context, index) => Container(
                      width: 280,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : _newsList.isEmpty
                  ? _buildEmptyNewsWidget()
                  : SizedBox(
                      height: 250,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (scrollNotification) {
                          if (scrollNotification is ScrollEndNotification) {
                            _onNewsScroll();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          controller: _newsScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: _newsList.length + (_hasMoreNews ? 1 : 0),
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          itemBuilder: (context, index) {
                            if (index < _newsList.length) {
                              return _buildNewsCard(_newsList[index]);
                            } else {
                              // Yükleniyor göstergesi
                              return SizedBox(
                                width: 80,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primaryColor,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildNewsLoadingIndicator() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildEmptyNewsWidget() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.newspaper_outlined,
            size: 60,
            color: AppTheme.textSecondaryColor.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Haber bulunamadı',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _loadNews,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Yenile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(UserNewsDTO news) {
    final isImportant = news.priority.toString().contains('HIGH') || news.priority.toString().contains('URGENT');
    
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () {
            _showNewsDetails(news);
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Container(
                  height: 130,
                  width: double.infinity,
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  child: _buildNewsMedia(news),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(news.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getCategoryName(news.type),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getCategoryColor(news.type),
                            ),
                          ),
                        ),
                        if (isImportant) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: AppTheme.accentColor,
                                  size: 11,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Önemli',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      news.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Haber görseli (resim veya video thumbnail)
  Widget _buildNewsMedia(UserNewsDTO news) {
    // Video haberi ve thumbnail varsa
    if (news.videoUrl != null && news.thumbnailUrl != null && news.thumbnailUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail göster
          Image.network(
            news.thumbnailUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Thumbnail yükleme hatası: $error');
              return Center(
                child: Icon(
                  _getCategoryIcon(news.type),
                  size: 50,
                  color: AppTheme.primaryColor.withOpacity(0.5),
                ),
              );
            },
          ),
          // Video göstergesi
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_circle_filled,
                    color: Colors.white,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Video',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Play butonu overlay
          Center(
            child: Icon(
              Icons.play_circle_filled,
              color: Colors.white.withOpacity(0.8),
              size: 40,
            ),
          ),
        ],
      );
    }
    
    // Video haberi var ama thumbnail yoksa
    if (news.videoUrl != null && news.videoUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // Varsayılan arkaplan
          Container(
            color: AppTheme.primaryColor.withOpacity(0.1),
            child: Center(
              child: Icon(
                Icons.movie_outlined,
                size: 50,
                color: AppTheme.primaryColor.withOpacity(0.5),
              ),
            ),
          ),
          // Video göstergesi
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_circle_filled,
                    color: Colors.white,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Video',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    
    // Normal resim içeren haber
    if (news.image != null && news.image!.isNotEmpty) {
      return Image.network(
        news.image!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              _getCategoryIcon(news.type),
              size: 50,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
          );
        },
      );
    }
    
    // Ne resim ne de video olan haber
    return Center(
      child: Icon(
        _getCategoryIcon(news.type),
        size: 50,
        color: AppTheme.primaryColor.withOpacity(0.5),
      ),
    );
  }

  void _showNewsDetails(UserNewsDTO news) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailFromIdScreen(newsId: news.id),
      ),
    );
  }
  
  void _showVideoNewsOptions(UserNewsDTO news) {
    // Kullanıcıya normal detay sayfası veya video oynatıcı seçeneği sun
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.article),
                title: const Text('Haber Detayını Görüntüle'),
                onTap: () {
                  Navigator.pop(context); // Sheet kapat
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_filled),
                title: const Text('Videoyu Oynat'),
                onTap: () {
                  Navigator.pop(context); // Sheet kapat
                  
                  // Video oynatıcıyı tam ekran olarak aç
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Container(
                      height: MediaQuery.of(context).size.height * 0.75,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Column(
                        children: [
                          // Kapatma çubuğu
                          Container(
                            width: 50,
                            height: 5,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          // Video başlığı
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              news.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Video player
                          Expanded(
                            child: VideoPlayerWidget(
                              videoUrl: news.videoUrl!,
                              autoPlay: true,
                              looping: false,
                              showControls: true,
                              fitToScreen: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(NewsType type) {
    switch (type) {
      case NewsType.DUYURU:
        return Icons.campaign;
      case NewsType.KAMPANYA:
        return Icons.engineering;
      case NewsType.BAKIM:
        return Icons.trending_up;
      case NewsType.BILGILENDIRME:
        return Icons.devices;
      case NewsType.GUNCELLEME:
        return Icons.support_agent;
      default:
        return Icons.article;
    }
  }

  Color _getCategoryColor(NewsType type) {
    switch (type) {
      case NewsType.DUYURU:
        return AppTheme.primaryColor;
      case NewsType.KAMPANYA:
        return AppTheme.infoColor;
      case NewsType.BAKIM:
        return AppTheme.successColor;
      case NewsType.BILGILENDIRME:
        return AppTheme.accentColor;
      case NewsType.GUNCELLEME:
        return Colors.purple;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  String _getCategoryName(NewsType type) {
    return type.name;
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr.toString());
      // Türkçe format: 15 Temmuz 2025, 10:04
      final months = [
        'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
      ];
      String month = months[date.month - 1];
      String day = date.day.toString();
      String year = date.year.toString();
      String hour = date.hour.toString().padLeft(2, '0');
      String minute = date.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute';
    } catch (e) {
      return dateStr.toString();
    }
  }

  void _showWeatherDetailsModal(BuildContext context) {
    if (_weatherData == null) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_weatherData!.iconCode.endsWith('n'))
                    const Icon(Icons.nightlight_round, size: 36, color: Colors.amber)
                  else
                    Image.network(
                      _weatherData!.getIconUrl(),
                      width: 36,
                      height: 36,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.wb_sunny_outlined, size: 28, color: AppTheme.primaryColor),
                    ),
                  const SizedBox(width: 16),
                  Text(
                    '${_weatherData!.temperature.round()}°C',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _weatherData!.description.isNotEmpty
                          ? _weatherData!.description[0].toUpperCase() + _weatherData!.description.substring(1)
                          : '',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_weatherData!.cityName != null)
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(_weatherData!.cityName!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              if (_weatherData!.windSpeed != null)
                Row(
                  children: [
                    const Icon(Icons.air, size: 18, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text('Rüzgar: ${_weatherData!.windSpeed!.toStringAsFixed(1)} m/s', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              if (_weatherData!.humidity != null)
                Row(
                  children: [
                    const Icon(Icons.water_drop, size: 18, color: Colors.lightBlue),
                    const SizedBox(width: 8),
                    Text('Nem: ${_weatherData!.humidity}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              if (_weatherData!.pressure != null)
                Row(
                  children: [
                    const Icon(Icons.speed, size: 18, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Text('Basınç: ${_weatherData!.pressure} hPa', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kapat'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Elegant welcome header with greeting
  Widget _buildWelcomeHeader() {
    debugPrint('[Widget] _buildWelcomeHeader renderlandı. _weatherData: $_weatherData, _isWeatherLoading: $_isWeatherLoading, _weatherError: $_weatherError');
    final hour = DateTime.now().hour;
    String greeting;
    
    if (hour >= 5 && hour < 12) {
      greeting = "Günaydın";
    } else if (hour >= 12 && hour < 18) {
      greeting = "İyi Günler";
    } else if (hour >= 18 && hour < 22) {
      greeting = "İyi Akşamlar";
    } else {
      greeting = "İyi Geceler";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondaryColor.withOpacity(0.8),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _userName.isEmpty ? 'Hoş Geldiniz' : '$_userName',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: GestureDetector(
                onTap: _weatherData != null ? () => _showWeatherDetailsModal(context) : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isWeatherLoading)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                      )
                    else if (_weatherData != null)
                      Row(
                        children: [
                          if (_weatherData!.iconCode.endsWith('n'))
                            const Icon(Icons.nightlight_round, size: 22, color: AppTheme.primaryColor)
                          else
                            Image.network(
                              _weatherData!.getIconUrl(),
                              width: 22,
                              height: 22,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.wb_sunny_outlined, size: 16, color: AppTheme.primaryColor),
                            ),
                          const SizedBox(width: 4),
                          Text(
                            '${_weatherData!.temperature.round()}°C',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      )
                    else if (_weatherError != null)
                      Row(
                        children: [
                          Icon(Icons.error_outline, size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            _weatherError!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Icon(Icons.wb_sunny_outlined, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            '--°C',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
