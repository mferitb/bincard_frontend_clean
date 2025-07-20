import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../../screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../services/secure_storage_service.dart';
import '../../routes.dart';
import '../../widgets/safe_screen.dart';
import '../../services/notification_service.dart';

// SharedPreferences anahtarlarını sabit olarak tanımlayalım
const String kSavedPhoneKey = 'saved_phone';
const String kRememberMeKey = 'remember_me';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _biometricService = BiometricService();
  
  // SharedPreferences örneğini bir kere oluşturup saklayalım
  SharedPreferences? _prefs;

  // Animasyon kontrolcüsü
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(###) ### ## ##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _canUseBiometrics = false;
  String _errorMessage = '';
  bool _isInitialized = false;
  bool _hasRefreshToken = false;  // Refresh token var mı?
  int _biometricAttempts = 0;     // Biyometrik deneme sayısı
  final int _maxBiometricAttempts = 3; // Maksimum deneme hakkı
  String? _userName; // Kullanıcı adı

  @override
  void initState() {
    super.initState();

    // Animasyon kontrolcüsünü oluştur - süreyi kısaltalım
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Süreyi azalttık
    );

    // Animasyonları tanımla
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1), // Daha az hareket
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
      // SharedPreferences örneğini bir kere oluştur
      _prefs = await SharedPreferences.getInstance();
      
      // Kayıtlı bilgileri yükle
      _loadSavedCredentials();
      
      // Refresh token kontrolü yap
      await _checkRefreshToken();
      
      // Biyometrik doğrulama kontrolü
      await _checkBiometricAvailability();
      
      // Kullanıcı adını al
      if (_hasRefreshToken) {
        await _loadUserInfo();
      }
      
      // Animasyonu başlat
      if (mounted) {
        _animationController.forward();
        setState(() {
          _isInitialized = true;
        });
      }
      
      // Eğer refresh token ve biyometrik giriş aktifse, otomatik biyometrik giriş için hazırlık yap
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // _prepareAutoBiometricLogin(); // Bu fonksiyonu kaldırdık
      });
    } catch (e) {
      debugPrint('Başlangıç hatası: $e');
    }
  }
  
  void _loadSavedCredentials() {
    if (_prefs == null) return;
    
    final savedPhone = _prefs!.getString(kSavedPhoneKey);
    final savedRememberMe = _prefs!.getBool(kRememberMeKey);

    if (savedRememberMe == true && savedPhone != null && mounted) {
      setState(() {
        _phoneController.text = savedPhone;
        // Telefon numarasını mask formatına uygun şekilde ayarla
        phoneMaskFormatter.formatEditUpdate(
          TextEditingValue.empty, 
          TextEditingValue(text: savedPhone)
        );
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveCredentials() async {
    if (_prefs == null) return;
    
    if (_rememberMe) {
      // Telefon numarasını masksız olarak kaydet
      final phoneNumber = phoneMaskFormatter.getUnmaskedText();
      await _prefs!.setString(kSavedPhoneKey, phoneNumber);
      await _prefs!.setBool(kRememberMeKey, true);
    } else {
      await _prefs!.remove(kSavedPhoneKey);
      await _prefs!.setBool(kRememberMeKey, false);
    }
  }
  
  Future<void> _checkExistingSession() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (isLoggedIn && mounted) {
        // Kullanıcı zaten giriş yapmış, ana sayfaya yönlendir
        _navigateToHome();
      }
    } catch (e) {
      debugPrint('Oturum kontrolü hatası: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _checkBiometricAvailability() async {
    try {
      final biometricService = BiometricService();
      
      // Biyometrik kimlik doğrulama kullanılabilir mi?
      final isAvailable = await biometricService.isBiometricAvailable();
      
      // Biyometrik kimlik doğrulama etkinleştirilmiş mi?
      final isEnabled = await biometricService.isBiometricEnabled();
      
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

  // Refresh token kontrolü - Devre dışı bırakıldı (her zaman telefon ve şifre gösterilecek)
  Future<void> _checkRefreshToken() async {
    try {
      final secureStorage = SecureStorageService();
      final refreshToken = await secureStorage.getRefreshToken();
      if (refreshToken != null) {
        debugPrint('Kayıtlı refresh token bulundu, ancak hızlı giriş devre dışı');
        setState(() {
          _hasRefreshToken = false; // Always set to false to show phone input
        });
      }
    } catch (e) {
      debugPrint('Refresh token kontrolü hatası: $e');
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        // Şifreyi al
        final password = _passwordController.text.trim();

        // Telefon numarası formatını düzenle (maskeden sadece rakamları al)
        final phoneNumber = phoneMaskFormatter.getUnmaskedText();

        // Kullanıcı bilgilerini kaydet
        await _saveCredentials();

        // Auth servisi ile normal giriş yapma
        debugPrint('Normal giriş işlemi başlatılıyor. Telefon: $phoneNumber');
        try {
          final response = await _authService.login(phoneNumber, password);
          debugPrint('Giriş yanıtı alındı: accessToken= [200~ {response.accessToken.token}');
          // Başarılı giriş - bildirim izni iste
          try {
            await NotificationService().handleNotificationFlow();
          } catch (e) {
            debugPrint('Bildirim izni/FCM token işlemi sırasında hata: $e');
          }
          // Başarılı giriş - ana sayfaya yönlendir
          debugPrint('Giriş başarılı, ana sayfaya yönlendiriliyor...');
          if (!mounted) return;
          _navigateToHome();
        } catch (e) {
          debugPrint('Giriş başarısız: $e');
          
          // SMS doğrulama gerekiyorsa, SMS doğrulama ekranına yönlendir
          if (e.toString().contains("SMS_VERIFICATION_REQUIRED")) {
            debugPrint('SMS doğrulama gerekiyor, ilgili ekrana yönlendiriliyor...');
            if (mounted) {
              Navigator.pushNamed(
                context, 
                AppRoutes.loginSmsVerify,
                arguments: {
                  'phoneNumber': phoneNumber,
                  'password': password,
                },
              );
              setState(() {
                _isLoading = false;
              });
              return;
            }
          }
          
          setState(() {
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
          });
        }
      } catch (e) {
        debugPrint('Giriş sırasında hata: $e');
        setState(() {
          _errorMessage = 'Beklenmeyen bir hata oluştu: $e';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  Future<void> _loginWithBiometrics() async {
    // Eğer maksimum deneme sayısına ulaşıldıysa, biyometrik girişi devre dışı bırak
    if (_biometricAttempts >= _maxBiometricAttempts) {
      setState(() {
        _errorMessage = 'Maksimum deneme sayısına ulaşıldı. Lütfen bilgilerinizle giriş yapın.';
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
            _errorMessage = 'Maksimum deneme sayısına ulaşıldı. Lütfen telefon numarası ve şifre ile giriş yapın.';
            _canUseBiometrics = false; // Bu oturumda biyometrik girişi devre dışı bırak
          });
        } else {
          // Henüz deneme hakkı varsa, kısa bir süre sonra tekrar dene
          if (mounted) {
            Future.delayed(const Duration(seconds: 1), () {
              if (_biometricAttempts < _maxBiometricAttempts && mounted) {
                _showBiometricPrompt();
              }
            });
          }
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
          _errorMessage = 'Maksimum deneme sayısına ulaşıldı. Lütfen telefon numarası ve şifre ile giriş yapın.';
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
  
  void _navigateToHome() async {
    debugPrint('_navigateToHome metodu çağrıldı');
    
    // Bekleyen deep link var mı kontrol et
    final secureStorage = SecureStorageService();
    final pendingDeepLink = await secureStorage.read('pendingDeepLink');
    
    if (pendingDeepLink != null && pendingDeepLink.isNotEmpty) {
      debugPrint('🔗 Bekleyen deep link bulundu: $pendingDeepLink');
      
      // Deep link'i işle
      try {
        final uri = Uri.parse(pendingDeepLink);
        // Deep link'i temizle
        await secureStorage.delete('pendingDeepLink');
        
        // news-detail veya /news/ path'i içeren URI'ları işle
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
            final id = int.parse(newsId);
            debugPrint('🔗 Giriş sonrası haber ID: $id için deep link yönlendirmesi yapılıyor');
            
            // Daha güvenli yönlendirme işlemi
            if (mounted) {
              // Önce ana sayfaya yönlendir, sonra haber detay sayfasına
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false, // Tüm yığını temizle
              );
              
              // Haber detay sayfasına yönlendirmeden önce kısa bir bildirim göster
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Paylaşılan habere yönlendiriliyorsunuz...'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              
              // Ana sayfaya yönlendirdikten sonra kısa bir gecikme ile haber detay sayfasına git
              Future.delayed(const Duration(milliseconds: 500), () {
                Navigator.of(context).pushNamed(
                  AppRoutes.newsDetail,
                  arguments: {'newsId': id},
                );
              });
              return; // İşlem tamamlandı, fonksiyondan çık
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Deep link ayrıştırma hatası: $e');
        // Hata durumunda normal yönlendirmeye devam et
      }
    }
    
    // Deep link yoksa veya işlenemediyse normal olarak ana sayfaya yönlendir
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false, // Tüm route yığınını temizle
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekran boyutunu bir kez al
    final size = MediaQuery.of(context).size;

    // Önbelleğe alma işlemi için precacheImage kullan
    precacheImage(const AssetImage('assets/images/logo.png'), context);
    
    // Refresh token varsa ve biyometrik giriş aktifse otomatik olarak biyometrik giriş başlat
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _checkAndStartBiometricLogin();
    // });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Üst kısımdaki dekoratif gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.4,
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
            ),
          ),

          // Ana içerik - Animasyonu sadece ilk yüklemede göster
          SafeArea(
            child: _isInitialized 
              ? FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildMainContent(),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(),
                ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMainContent() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildLoginCard(),
            ],
          ),
        ),
      ),
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

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 40), // Üstteki boşluğu azalttım
        // Doğrudan logo görselini göster, yuvarlak arka plan olmadan
        Image.asset(
          'assets/images/logo2.png',
          width: 140,   // Arka plan olmadan biraz daha büyük
          height: 140,  // Arka plan olmadan biraz daha büyük
        ),
        const SizedBox(height: 24),
        // Her zaman standart karşılama mesajını göster
        Text(
          'Şehir Kartıma Hoş Geldiniz',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

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
            'Giriş Yap',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lütfen bilgilerinizi girin',
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
        _buildPhoneInput(),  // Always show phone input
        const SizedBox(height: 16),
        _buildPasswordInput(),
        const SizedBox(height: 8),
        _buildRememberMeForgotPassword(),
        const SizedBox(height: 24),
        if (_errorMessage.isNotEmpty) ...[
          _buildErrorMessage(),
          const SizedBox(height: 16),
        ],
        _buildLoginButton(),
        const SizedBox(height: 24),
        _buildRegisterRow(),
      ],
    );
  }

  Widget _buildPhoneInput() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [phoneMaskFormatter],
      style: TextStyle(color: AppTheme.textPrimaryColor, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Telefon Numarası',
        hintText: '(5XX) XXX XX XX',
        prefixIcon: Icon(
          Icons.phone_android_rounded,
          color: AppTheme.primaryColor,
        ),
        prefixText: '+90 ',
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen telefon numaranızı girin';
        }
        
        // Maskelenmiş telefon numarası kontrolü
        final unmaskedText = phoneMaskFormatter.getUnmaskedText();
        if (unmaskedText.isEmpty) {
          return 'Lütfen telefon numaranızı girin';
        }
        
        // Rakam sayısını kontrol et
        if (unmaskedText.length < 10) {
          return 'Telefon numarası eksik';
        }
        
        return null;
      },
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
            await _login();
          }
        }
      },
    );
  }

  Widget _buildRememberMeForgotPassword() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _rememberMe,
                activeColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Beni Hatırla',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            // Use safe navigation for auth flow
            safeNavigate(context, AppRoutes.forgotPassword);
          },
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Şifremi Unuttum',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login,
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

  Widget _buildRegisterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Hesabınız yok mu?',
          style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
        ),
        TextButton(
          onPressed: () {
            // Use safe navigation for auth flow
            safeNavigate(context, AppRoutes.register);
          },
          child: Text(
            'Kayıt Ol',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  // Biyometrik girişi otomatik başlat
  // Future<void> _checkAndStartBiometricLogin() async {
  //   if (_isInitialized && _hasRefreshToken && _canUseBiometrics && !_isLoading && mounted) {
  //     debugPrint('Biyometrik giriş otomatik olarak başlatılıyor...');
      
  //     // Kısa bir gecikme ekleyerek UI'ın tamamen yüklenmesini bekleyelim
  //     await Future.delayed(const Duration(milliseconds: 300));
      
  //     if (mounted) {
  //       await _loginWithBiometrics();
  //     }
  //   }
  // }

  // Refresh token varsa ve biyometrik kimlik doğrulama etkinse otomatik olarak biyometrik giriş için hazırlık yap
  // Future<void> _prepareAutoBiometricLogin() async {
  //   if (!mounted) return;
    
  //   debugPrint('Biyometrik giriş hazırlığı yapılıyor...');
  //   debugPrint('Refresh token var mı: $_hasRefreshToken');
  //   debugPrint('Biyometrik doğrulama kullanılabilir mi: $_canUseBiometrics');
    
  //   // Hem refresh token hem de biyometrik doğrulama mevcutsa, 
  //   // ekran yüklendikten sonra biyometrik doğrulama penceresini göster
  //   if (_hasRefreshToken && _canUseBiometrics) {
  //     debugPrint('Biyometrik giriş için gerekli koşullar sağlanıyor. Biyometrik prompt gösterilecek...');
      
  //     // Biraz bekleyelim, UI'ın tam yüklenmesi için
  //     await Future.delayed(const Duration(milliseconds: 800));
      
  //     if (mounted) {
  //       // Biyometrik deneme sayacını sıfırla
  //       _biometricAttempts = 0;
        
  //       try {
  //         // Access token kontrolü yap
  //         final secureStorage = SecureStorageService();
  //         final accessToken = await secureStorage.getAccessToken();
          
  //         // Eğer access token yoksa, biyometrik girişi dene
  //         if (accessToken == null) {
  //           _showBiometricPrompt();
  //         } else {
  //           // Access token varsa, doğrudan ana sayfaya yönlendir
  //           _navigateToHome();
  //         }
  //       } catch (e) {
  //         debugPrint('Access token kontrolü sırasında hata: $e');
  //         _showBiometricPrompt();
  //       }
  //     }
  //   } else {
  //     debugPrint('Biyometrik giriş için gerekli koşullar sağlanmıyor.');
  //   }
  // }
  
  // Biyometrik kimlik doğrulama penceresini göster
  Future<void> _showBiometricPrompt() async {
    if (!mounted) return;
    
    // Eğer maksimum deneme sayısına ulaşıldıysa, biyometrik girişi devre dışı bırak
    if (_biometricAttempts >= _maxBiometricAttempts) {
      setState(() {
        _errorMessage = 'Maksimum deneme sayısına ulaşıldı. Lütfen bilgilerinizle giriş yapın.';
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
              _errorMessage = 'Maksimum deneme sayısına ulaşıldı. Lütfen bilgilerinizle giriş yapın.';
              _canUseBiometrics = false; // Bu oturumda biyometrik girişi devre dışı bırak
            } else {
              _errorMessage = 'Biyometrik giriş başarısız oldu. Kalan deneme: ${_maxBiometricAttempts - _biometricAttempts}';
              
              // Henüz deneme hakkı varsa, kısa bir süre sonra tekrar dene
              Future.delayed(const Duration(seconds: 1), () {
                if (_biometricAttempts < _maxBiometricAttempts && mounted) {
                  _showBiometricPrompt();
                }
              });
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
            _errorMessage = 'Maksimum deneme sayısına ulaşıldı. Lütfen bilgilerinizle giriş yapın.';
            _canUseBiometrics = false; // Bu oturumda biyometrik girişi devre dışı bırak
          } else {
            _errorMessage = 'Biyometrik giriş hatası. Kalan deneme: ${_maxBiometricAttempts - _biometricAttempts}';
            
            // Henüz deneme hakkı varsa, kısa bir süre sonra tekrar dene
            Future.delayed(const Duration(seconds: 1), () {
              if (_biometricAttempts < _maxBiometricAttempts && mounted) {
                _showBiometricPrompt();
              }
            });
          }
        });
      }
    }
  }

  // Kullanıcı bilgilerini yükle
  Future<void> _loadUserInfo() async {
    try {
      final secureStorage = SecureStorageService();
      final firstName = await secureStorage.getUserFirstName();
      
      if (firstName != null && mounted) {
        setState(() {
          _userName = firstName;
        });
        debugPrint('Kullanıcı adı yüklendi: $_userName');
      }
    } catch (e) {
      debugPrint('Kullanıcı bilgileri yüklenirken hata: $e');
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
}
