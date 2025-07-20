import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math; // Added math import
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences için import
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../services/secure_storage_service.dart';
import '../../services/user_service.dart';
import '../../services/token_service.dart';
import '../../services/api_service.dart';
import 'login_screen.dart';
import 'forgot_password_screen.dart'; // Import for forgot password screen
import '../../screens/home_screen.dart';
import '../../routes.dart';

class RefreshLoginScreen extends StatefulWidget {
  const RefreshLoginScreen({super.key});

  @override
  State<RefreshLoginScreen> createState() => _RefreshLoginScreenState();
}

class _RefreshLoginScreenState extends State<RefreshLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _biometricService = BiometricService();
  final _secureStorage = SecureStorageService();

  // Animasyon kontrolcüsü
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _canUseBiometrics = false;
  String _errorMessage = '';
  bool _isInitialized = false;
  String? _userName;
  String? _userPhone; // Telefon numarası için değişken
  int _biometricAttempts = 0;
  final int _maxBiometricAttempts = 3;

  @override
  void initState() {
    super.initState();

    // Animasyon kontrolcüsünü oluştur
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Animasyonları tanımla
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Başlangıç işlemlerini asenkron olarak başlat
    _initializeAsync();
  }

  // Tüm başlangıç işlemlerini tek bir asenkron metotta toplayalım
  Future<void> _initializeAsync() async {
    try {
      // Kullanıcı adını ve refresh token'ı kontrol et
      await _loadUserInfo();
      await _checkBiometricAvailability();

      // Animasyonu başlat
      if (mounted) {
        _animationController.forward();
        setState(() {
          _isInitialized = true;
        });
      }

      // Eğer biyometrik giriş aktifse, otomatik biyometrik giriş için hazırlık yap
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prepareAutoBiometricLogin();
      });
    } catch (e) {
      debugPrint('Başlangıç hatası: $e');
    }
  }

  // Kullanıcı bilgilerini yükle
  Future<void> _loadUserInfo() async {
    try {
      final firstName = await _secureStorage.getUserFirstName();
      final lastName = await _secureStorage.getUserLastName();
      final refreshToken = await _secureStorage.getRefreshToken();
      
      // Telefon numarasını secure storage'dan yükle
      final phone = await _secureStorage.getUserPhone();
      debugPrint('📱 Secure storage\'dan telefon numarası: $phone');
      
      // Eğer secure storage'da yoksa, SharedPreferences'dan kontrol et
      if (phone == null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final savedPhone = prefs.getString('last_used_phone');
          if (savedPhone != null) {
            debugPrint('📱 SharedPreferences\'dan telefon numarası bulundu: $savedPhone');
            // Secure storage'a kaydet
            await _secureStorage.setUserPhone(savedPhone);
            setState(() {
              _userPhone = savedPhone;
            });
          }
        } catch (e) {
          debugPrint('⚠️ SharedPreferences\'dan telefon yüklenirken hata: $e');
        }
      } else {
        setState(() {
          _userPhone = phone;
        });
      }
      
      debugPrint('🔍 Refresh token var mı: ${refreshToken != null}');
      if (refreshToken != null) {
        debugPrint('🔍 Refresh token uzunluk: ${refreshToken.length}');
      }
      
      if (refreshToken == null) {
        // Eğer refresh token yoksa, normal login sayfasına yönlendir
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          // Kullanıcının tam adını kullan (ad ve soyad birlikte)
          if (firstName != null) {
            if (lastName != null) {
              _userName = "$firstName $lastName";
            } else {
              _userName = firstName;
            }
          }
        });
        debugPrint('Kullanıcı adı yüklendi: $_userName');
      }
    } catch (e) {
      debugPrint('Kullanıcı bilgileri yüklenirken hata: $e');
    }
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      // Biyometrik kimlik doğrulama kullanılabilir mi?
      final isAvailable = await _biometricService.isBiometricAvailable();
      
      // Biyometrik kimlik doğrulama etkinleştirilmiş mi?
      final isEnabled = await _biometricService.isBiometricEnabled();
      
      if (mounted) {
        setState(() {
          _canUseBiometrics = isAvailable && isEnabled;
        });
      }
      
      debugPrint('Biyometrik doğrulama kullanılabilir: $isAvailable, etkin: $isEnabled');
    } catch (e) {
      debugPrint('Biyometrik kontrol hatası: $e');
    }
  }

  // Zaman dilimine göre selamlama mesajı oluştur
  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 12) {
      return 'Günaydın';
    } else if (hour >= 12 && hour < 18) {
      return 'İyi Günler';
    } else if (hour >= 18 && hour < 22) {
      return 'İyi Akşamlar';
    } else {
      return 'İyi Geceler';
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Refresh token ile giriş
  Future<void> _refreshLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        debugPrint('🔄 Refresh login başlatılıyor...');
        
        // Telefon numarasını kontrol et
        final phoneNumber = await _secureStorage.getUserPhone();
        debugPrint('� Refresh login için telefon numarası: $phoneNumber');
        
        // Telefon numarası yoksa ek kontrol yap
        if (phoneNumber == null) {
          debugPrint('⚠️ Secure storage\'da telefon numarası bulunamadı, SharedPreferences\'a bakılıyor...');
          final prefs = await SharedPreferences.getInstance();
          final savedPhone = prefs.getString('last_used_phone');
          
          if (savedPhone != null) {
            debugPrint('📱 SharedPreferences\'dan telefon numarası bulundu: $savedPhone');
            // Secure storage'a kaydet
            await _secureStorage.setUserPhone(savedPhone);
            setState(() {
              _userPhone = savedPhone;
            });
          }
        }
        
        // Check refresh token before the operation
        final refreshTokenBefore = await _secureStorage.getRefreshToken();
        debugPrint('🔍 Refresh login öncesi refresh token: ${refreshTokenBefore != null ? "var" : "yok"}');
        
        final response = await _authService.refreshLogin(_passwordController.text);
        
        // Check refresh token after the operation
        final refreshTokenAfter = await _secureStorage.getRefreshToken();
        debugPrint('🔍 Refresh login sonrası refresh token: ${refreshTokenAfter != null ? "var" : "yok"}');
        
        // If we get a response without exception, it means login was successful
        debugPrint('✅ Refresh login başarılı, kullanıcı bilgileri getiriliyor...');
        
        // Verify that tokens were saved properly
        final accessToken = await _secureStorage.getAccessToken();
        final refreshToken = await _secureStorage.getRefreshToken();
        debugPrint('💾 Access token kaydedildi: ${accessToken != null ? "✅" : "❌"}');
        debugPrint('💾 Refresh token kaydedildi: ${refreshToken != null ? "✅" : "❌"}');
        
        // Telefon numarasını tekrar kontrol et
        final phoneNumberAfter = await _secureStorage.getUserPhone();
        debugPrint('🔍 Refresh login sonrası telefon numarası: $phoneNumberAfter');
        
        // Fetch user profile to ensure we have updated user information
        try {
          final userService = UserService();
          await userService.getUserProfile();
          debugPrint('👤 Kullanıcı profili başarıyla getirildi');
        } catch (e) {
          debugPrint('⚠️ Kullanıcı profili getirme hatası: $e');
          // Don't block login if profile fetch fails
        }
        
        // Test token service
        try {
          final tokenService = TokenService();
          final hasValidTokens = await tokenService.hasValidTokens();
          debugPrint('🔍 TokenService hasValidTokens: $hasValidTokens');
        } catch (e) {
          debugPrint('⚠️ TokenService kontrolü hatası: $e');
        }
        
        if (mounted) {
          debugPrint('🏠 Ana sayfaya yönlendiriliyor...');
          
          // Final token check before navigation
          final finalAccessToken = await _secureStorage.getAccessToken();
          final finalRefreshToken = await _secureStorage.getRefreshToken();
          debugPrint('🔍 Navigation öncesi final token durumu:');
          debugPrint('   - Access token: ${finalAccessToken != null ? "var (${finalAccessToken.length} karakter)" : "yok"}');
          debugPrint('   - Refresh token: ${finalRefreshToken != null ? "var (${finalRefreshToken.length} karakter)" : "yok"}');
          
          // Test token service
          try {
            final tokenService = TokenService();
            final hasValidTokens = await tokenService.hasValidTokens();
            debugPrint('🔍 TokenService hasValidTokens: $hasValidTokens');
          } catch (e) {
            debugPrint('⚠️ TokenService kontrolü hatası: $e');
          }
          
          // Ensure token interceptor is set up
          final apiService = ApiService();
          apiService.setupTokenInterceptor();
          debugPrint('🔧 Token interceptor yeniden kuruldu');
          
          // Longer delay to ensure everything is ready
          await Future.delayed(const Duration(milliseconds: 1000));
          
          if (mounted) {
            debugPrint('🚀 Navigator.pushReplacementNamed(${AppRoutes.home}) çağırılıyor...');
            
            // Use pushNamedAndRemoveUntil to ensure we clear the stack
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.home, 
              (route) => false, // Remove all previous routes
            );
            
            debugPrint('✅ Navigation komutu verildi');
          } else {
            debugPrint('❌ Widget unmounted after delay, navigation iptal edildi');
          }
        } else {
          debugPrint('❌ Widget mounted değil, navigation yapılamıyor');
        }
      } catch (e) {
        if (mounted) {
          // Extract the actual error message from the exception
          String errorMessage = e.toString();
          if (errorMessage.startsWith('Exception: ')) {
            errorMessage = errorMessage.substring(11); // Remove "Exception: " prefix
          }
          
          // Check if this is a session expiration that requires full login
          if (errorMessage.contains('Oturum süresi dolmuş') || 
              errorMessage.contains('tekrar giriş yapın') ||
              errorMessage.contains('Oturum bilgileriniz geçersiz')) {
            // Clear any remaining tokens and redirect to full login
            debugPrint('🚫 Oturum geçersiz, login sayfasına yönlendiriliyor');
            await _secureStorage.clearTokens();
            
            // Show a helpful message and redirect
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Oturum bilgileriniz geçersiz. Lütfen tekrar giriş yapın.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
              
              // Small delay for user to see the message
              await Future.delayed(const Duration(milliseconds: 1500));
              
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            }
            return;
          }
          
          // For other errors (like wrong password), just show the error message
          debugPrint('❌ Refresh login hatası: $errorMessage');
          _showErrorDialog(errorMessage);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _loginWithBiometrics() async {
    // Eğer maksimum deneme sayısına ulaşıldıysa, biyometrik girişi devre dışı bırak
    if (_biometricAttempts >= _maxBiometricAttempts) {
      setState(() {
        _errorMessage = 'Maksimum deneme sayısına ulaşıldı. Lütfen şifrenizle giriş yapın.';
        _canUseBiometrics = false; // Bu oturumda biyometrik girişi devre dışı bırak
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      debugPrint('Biyometrik giriş başlatılıyor...');
      final success = await _authService.loginWithBiometrics();
      
      if (success) {
        debugPrint('Biyometrik giriş başarılı, ana sayfaya yönlendiriliyor...');
        if (!mounted) return;
        _navigateToHome();
      } else {
        debugPrint('Biyometrik giriş başarısız');
        setState(() {
          _biometricAttempts++;
          _errorMessage = 'Biyometrik doğrulama başarısız oldu. Kalan deneme: ${_maxBiometricAttempts - _biometricAttempts}';
        });
        
        // Maksimum deneme sayısına ulaşıldıysa, manuel giriş isteği göster
        if (_biometricAttempts >= _maxBiometricAttempts) {
          setState(() {
            _errorMessage = 'Maksimum deneme sayısına ulaşıldı. Lütfen şifrenizle giriş yapın.';
            _canUseBiometrics = false; // Bu oturumda biyometrik girişi devre dışı bırak
          });
        }
      }
    } catch (e) {
      debugPrint('Biyometrik giriş hatası: $e');
      setState(() {
        _biometricAttempts++;
        _errorMessage = 'Biyometrik doğrulama hatası: $e';
      });
      
      // Maksimum deneme sayısına ulaşıldıysa, manuel giriş isteği göster
      if (_biometricAttempts >= _maxBiometricAttempts && mounted) {
        setState(() {
          _errorMessage = 'Maksimum deneme sayısına ulaşıldı. Lütfen şifrenizle giriş yapın.';
          _canUseBiometrics = false; // Bu oturumda biyometrik girişi devre dışı bırak
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToHome() {
    debugPrint('_navigateToHome metodu çağrıldı');
    // Daha güvenli yönlendirme işlemi
    if (mounted) {
      // Access token kontrolü yap
      _secureStorage.getAccessToken().then((accessToken) {
        if (accessToken == null) {
          debugPrint('Access token bulunamadı, token yenileniyor...');
          _authService.refreshAccessToken().then((success) {
            if (success) {
              debugPrint('Token yenileme başarılı, ana sayfaya yönlendiriliyor...');
              _doNavigateToHome();
            } else {
              debugPrint('Token yenileme başarısız, login sayfasına yönlendiriliyor...');
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            }
          });
        } else {
          debugPrint('Access token mevcut, ana sayfaya yönlendiriliyor...');
          _doNavigateToHome();
        }
      });
    }
  }
  
  void _doNavigateToHome() {
    // Tüm yığını temizleyerek ana sayfaya yönlendir
    debugPrint('Ana sayfaya yönlendiriliyor...');
    Future.delayed(Duration.zero, () {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false, // Tüm yığını temizle
      );
    });
  }

  // Refresh token varsa ve biyometrik kimlik doğrulama etkinse otomatik olarak biyometrik giriş için hazırlık yap
  Future<void> _prepareAutoBiometricLogin() async {
    if (!mounted) return;
    
    debugPrint('Biyometrik giriş hazırlığı yapılıyor...');
    
    // Check for refresh token first
    final refreshToken = await _secureStorage.getRefreshToken();
    debugPrint('Refresh token var mı: ${refreshToken != null}');
    
    // Log refresh token expiry if available
    if (refreshToken != null) {
      final refreshTokenExpiry = await _secureStorage.getRefreshTokenExpiry();
      if (refreshTokenExpiry != null) {
        final expiry = DateTime.parse(refreshTokenExpiry);
        final isValid = DateTime.now().isBefore(expiry);
        debugPrint('Refresh token geçerli mi: $isValid, sona erme: $expiry');
      } else {
        debugPrint('Refresh token expiry bilgisi bulunamadı');
      }
    }
    
    debugPrint('Biyometrik doğrulama kullanılabilir mi: $_canUseBiometrics');
    
    // Hem refresh token hem de biyometrik doğrulama mevcutsa, 
    // ekran yüklendikten sonra biyometrik doğrulama penceresini göster
    final hasRefreshToken = refreshToken != null;
    if (_canUseBiometrics && hasRefreshToken) {
      debugPrint('Biyometrik giriş için gerekli koşullar sağlanıyor. Biyometrik prompt gösterilecek...');
      
      // Biraz bekleyelim, UI'ın tam yüklenmesi için
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (mounted) {
        // Biyometrik deneme sayacını sıfırla
        _biometricAttempts = 0;
        
        try {
          // Access token kontrolü yap
          final accessToken = await _secureStorage.getAccessToken();
          
          // Eğer access token yoksa, biyometrik girişi dene
          if (accessToken == null) {
            _showBiometricPrompt();
          } else {
            // Access token varsa, doğrudan ana sayfaya yönlendir
            _navigateToHome();
          }
        } catch (e) {
          debugPrint('Access token kontrolü sırasında hata: $e');
          _showBiometricPrompt();
        }
      }
    } else {
      debugPrint('Biyometrik giriş için gerekli koşullar sağlanmıyor.');
    }
  }

  // Biyometrik kimlik doğrulama penceresini göster
  Future<void> _showBiometricPrompt() async {
    if (!mounted) return;
    
    // Eğer maksimum deneme sayısına ulaşıldıysa, biyometrik girişi devre dışı bırak
    if (_biometricAttempts >= _maxBiometricAttempts) {
      setState(() {
        _errorMessage = 'Maksimum deneme sayısına ulaşıldı. Lütfen şifrenizle giriş yapın.';
        _canUseBiometrics = false; // Bu oturumda biyometrik girişi devre dışı bırak
      });
      return;
    }
    
    debugPrint('Biyometrik kimlik doğrulama penceresi gösteriliyor... Deneme: ${_biometricAttempts + 1}/$_maxBiometricAttempts');
    
    // Biyometrik giriş başlat
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final success = await _authService.loginWithBiometrics();
      
      if (success) {
        // Başarılı giriş, ana sayfaya yönlendir
        debugPrint('Biyometrik giriş başarılı, ana sayfaya yönlendiriliyor...');
        if (mounted) {
          _navigateToHome();
        }
      } else {
        // Başarısız biyometrik giriş, hata mesajı göster
        debugPrint('Biyometrik giriş başarısız oldu. Deneme: ${_biometricAttempts + 1}');
        if (mounted) {
          setState(() {
            _biometricAttempts++;
            _isLoading = false;
            
            if (_biometricAttempts >= _maxBiometricAttempts) {
              _errorMessage = 'Maksimum deneme sayısına ulaşıldı. Lütfen şifrenizle giriş yapın.';
              _canUseBiometrics = false; // Bu oturumda biyometrik girişi devre dışı bırak
            } else {
              _errorMessage = 'Biyometrik giriş başarısız oldu. Kalan deneme: ${_maxBiometricAttempts - _biometricAttempts}';
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Biyometrik giriş hatası: $e');
      if (mounted) {
        setState(() {
          _biometricAttempts++;
          _isLoading = false;
          
          if (_biometricAttempts >= _maxBiometricAttempts) {
            _errorMessage = 'Maksimum deneme sayısına ulaşıldı. Lütfen şifrenizle giriş yapın.';
            _canUseBiometrics = false; // Bu oturumda biyometrik girişi devre dışı bırak
          } else {
            _errorMessage = 'Biyometrik giriş hatası. Kalan deneme: ${_maxBiometricAttempts - _biometricAttempts}';
          }
        });
      }
    }
  }

  // Farklı hesap ile giriş yapmak için tüm kullanıcı verilerini temizle
  Future<void> _clearAllUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Tüm tokenleri ve kullanıcı verilerini temizle
      await _secureStorage.clearAll();
      
      // Biyometrik kimlik doğrulamayı devre dışı bırak
      await _biometricService.disableBiometricAuthentication();
      
      debugPrint('Tüm kullanıcı verileri temizlendi, login ekranına yönlendiriliyor');
      
      // Login ekranına yönlendir
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
      }
    } catch (e) {
      debugPrint('Kullanıcı verilerini temizlerken hata: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Veriler temizlenirken bir hata oluştu';
      });
    }
  }

  // Mavi alanın içindeki karşılama içeriği
  Widget _buildWelcomeContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo - yuvarlak arka plan olmadan doğrudan logo
        Image.asset(
          'assets/images/logo2.png',
          width: 140,   // Biraz daha büyük
          height: 140,  // Biraz daha büyük
        ),
        const SizedBox(height: 12), // Boşluğu azalttım
        // Greeting message
        Text(
          _getGreetingMessage(),
          style: const TextStyle(
            fontSize: 22, // Yazı boyutunu 18'den 22'ye büyüttüm
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // User name
        Text(
          _userName ?? 'Değerli Kullanıcı',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith( // headlineSmall yerine headlineMedium (daha büyük)
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Welcome back message
        Text(
          'Tekrar hoş geldiniz',
          style: const TextStyle(
            fontSize: 18, // 16'dan 18'e büyüttüm
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Login formunu içeren kart için yeni metod
  Widget _buildLoginFormContent() {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).size.height * 0.46, // Form alanını biraz daha aşağı taşıdım (0.40 -> 0.46)
        left: 24,
        right: 24,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: _buildLoginCard(),
        ),
      ),
    );
  }

  // Eski buildHeader metodu yeni buildWelcomeContent metoduyla değiştirildi

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hızlı Giriş',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Devam etmek için şifrenizi girin',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),
          _buildLoginForm(),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPasswordInput(),
        const SizedBox(height: 16),
        if (_errorMessage.isNotEmpty) ...[
          _buildErrorMessage(),
          const SizedBox(height: 16),
        ],
        _buildLoginButton(),
        const SizedBox(height: 12),
        _buildForgotPasswordButton(),
        // Biyometrik giriş butonunu ve _canUseBiometrics kontrolünü kaldırdım
        const SizedBox(height: 16),
        _buildDifferentAccountButton(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildForgotPasswordButton() {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
          );
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          'Şifremi Unuttum',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDifferentAccountButton() {
    return Center(
      child: TextButton(
        onPressed: _isLoading ? null : _clearAllUserData,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.logout, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Farklı hesap ile giriş yap',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordInput() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      keyboardType: TextInputType.number,
      style: TextStyle(color: AppTheme.textPrimaryColor, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Şifre',
        hintText: '6 haneli şifrenizi girin',
        prefixIcon: Icon(Icons.lock_rounded, color: AppTheme.primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: AppTheme.primaryColor,
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      inputFormatters: [
        LengthLimitingTextInputFormatter(6),
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen şifrenizi girin';
        }
        if (value.length < 6) {
          return 'Şifre 6 haneli olmalıdır';
        }
        return null;
      },
      onChanged: (value) async {
        if (value.length == 6 && !_isLoading) {
          if (_formKey.currentState != null && _formKey.currentState!.validate()) {
            await _refreshLogin();
          }
        }
      },
    );
  }

  Widget _buildErrorMessage() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _refreshLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        shadowColor: AppTheme.primaryColor.withOpacity(0.5),
        disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.6),
      ),
      child:
          _isLoading
              ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Giriş Yapılıyor...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Giriş Yap',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
    );
  }
  
  Widget _buildBiometricLoginButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _loginWithBiometrics,
      icon: const Icon(Icons.fingerprint, size: 24),
      label: const Text(
        'Biyometrik Kimlik ile Giriş',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        shadowColor: Colors.blue.withOpacity(0.5),
      ),
    );
  }

  // Yükleniyor göstergesi
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3), // Arka planı daha şeffaf yaptım
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16), // Daha küçük padding
          decoration: BoxDecoration(
            color: Colors.grey.shade200.withOpacity(0.8), // Beyaz yerine açık gri ve yarı şeffaf
            shape: BoxShape.circle, // Yuvarlak bir container
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05), // Daha az belirgin gölge
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          // Sadece CircularProgressIndicator göster, yazı yok
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            strokeWidth: 3.0, // Biraz daha kalın çizgi
            backgroundColor: Colors.grey.withOpacity(0.2), // Gri ve düşük opaklıkta arka plan
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ekran boyutunu bir kez al
    final size = MediaQuery.of(context).size;

    // Önbelleğe alma işlemi için precacheImage kullan
    precacheImage(const AssetImage('assets/images/logo.png'), context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Üst kısımdaki dekoratif gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.47, // Mavi alanı biraz daha genişlettim
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppTheme.blueGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              // Mavi alanın içine doğrudan logo ve selamlama metinleri ekle
              child: _isInitialized 
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: _buildWelcomeContent(),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
            ),
          ),

          // Login kartını ana içeriğin bir parçası olarak ekle
          SafeArea(
            child: _isInitialized 
              ? FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildLoginFormContent(),
                  ),
                )
              : const SizedBox(),
          ),
          
          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }
}