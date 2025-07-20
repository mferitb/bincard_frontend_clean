import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart'; // Yeni import - TapGestureRecognizer için
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'verification_screen.dart';
import 'login_screen.dart';
import '../../routes.dart';
import '../../widgets/safe_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(###) ### ## ##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    // Animasyonları oluştur
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen kullanım koşullarını kabul edin'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final firstName = _firstNameController.text.trim();
        final lastName = _lastNameController.text.trim();
        final phoneNumber = phoneMaskFormatter.getUnmaskedText();
        final password = _passwordController.text.trim();

        // Telefon numarası doğru formatta mı kontrol et
        if (phoneNumber.length != 10) {
          setState(() {
            _errorMessage = 'Telefon numarası 10 haneli olmalıdır';
            _isLoading = false;
          });
          return;
        }

        final response = await _authService.register(
          firstName,
          lastName,
          phoneNumber,
          password,
        );

        if (response.success) {
          if (!mounted) return;

          // Başarı mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Kayıt işlemi başarılı!'),
              backgroundColor: Colors.green,
            ),
          );

          // Doğrulama sayfasına yönlendir
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      VerificationScreen(phoneNumber: phoneNumber),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;

                var tween = Tween(
                  begin: begin,
                  end: end,
                ).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);

                return SlideTransition(position: offsetAnimation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        } else {
          setState(() {
            _errorMessage =
                response.message ??
                'Kayıt işlemi başarısız oldu. Lütfen tekrar deneyin.';
          });
        }
      } catch (e) {
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

  // Gizlilik politikası dialogunu gösterecek metod
  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Gizlilik Politikası',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gizlilik Politikası ve Kişisel Verilerin Korunması',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Bu gizlilik politikası, şehir kartı hizmetlerimizi kullanırken sizden toplanan kişisel verilerin nasıl kullanıldığını ve korunduğunu açıklamaktadır.',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '1. Toplanan Veriler',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• Kişisel bilgiler (ad, soyad, telefon numarası)\n'
                '• Konum bilgileri (kart kullanımı sırasında)\n'
                '• Kullanım istatistikleri ve tercihler',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '2. Verilerin Kullanımı',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• Hizmetlerimizi sağlamak ve geliştirmek\n'
                '• Güvenliğinizi sağlamak\n'
                '• Yasal yükümlülüklerimizi yerine getirmek',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '3. Veri Güvenliği',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kişisel verileriniz, endüstri standardı güvenlik önlemleri ile korunmaktadır ve yetkisiz erişime karşı düzenli olarak denetlenmektedir.',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Anladım',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          ),
          onPressed: () {
            safeNavigate(context, AppRoutes.login);
          },
        ),
      ),
      body: Stack(
        children: [
          // Üst kısımdaki dekoratif gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.35,
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

          // Ana içerik
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 10), // 20'den 10'a düşürdüm
                      _buildRegisterCard(),
                    ],
                  ),
                ),
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
        const SizedBox(height: 40),
        // Doğrudan logo görselini göster, yuvarlak arka plan olmadan
        Image.asset(
          'assets/images/logo2.png',
          width: 140,
          height: 140,
        ),
      ],
    );
  }

  Widget _buildRegisterCard() {
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yeni Hesap Oluştur',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lütfen bilgilerinizi eksiksiz doldurun',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            _buildNameInput(),
            const SizedBox(height: 16),
            _buildLastNameInput(),
            const SizedBox(height: 16),
            _buildPhoneInput(),
            const SizedBox(height: 16),
            _buildPasswordInput(),
            const SizedBox(height: 16),
            _buildConfirmPasswordInput(),
            const SizedBox(height: 24),
            _buildTermsCheckbox(),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildErrorMessage(),
            ],
            const SizedBox(height: 24),
            _buildRegisterButton(),
            const SizedBox(height: 16),
            _buildLoginRow(),
          ],
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

  Widget _buildNameInput() {
    return TextFormField(
      controller: _firstNameController,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      style: TextStyle(color: AppTheme.textPrimaryColor, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Ad',
        hintText: 'Adınızı girin',
        prefixIcon: Icon(Icons.person_rounded, color: AppTheme.primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
          return 'Lütfen adınızı girin';
        }
        return null;
      },
    );
  }

  Widget _buildLastNameInput() {
    return TextFormField(
      controller: _lastNameController,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      style: TextStyle(color: AppTheme.textPrimaryColor, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Soyad',
        hintText: 'Soyadınızı girin',
        prefixIcon: Icon(
          Icons.person_outline_rounded,
          color: AppTheme.primaryColor,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
          return 'Lütfen soyadınızı girin';
        }
        return null;
      },
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
        prefixText: '+90 ',
        prefixIcon: Icon(
          Icons.phone_android_rounded,
          color: AppTheme.primaryColor,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
        // Rakam sayısını kontrol et
        final digitCount = phoneMaskFormatter.getUnmaskedText().length;
        if (digitCount < 10) {
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
        hintText: '6 haneli şifre oluşturun',
        prefixIcon: Icon(Icons.lock_rounded, color: AppTheme.primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_rounded  // Şifre gizli - kapalı göz ikonu
                : Icons.visibility_rounded,     // Şifre görünür - açık göz ikonu
            color: AppTheme.primaryColor,
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
          return 'Lütfen şifre oluşturun';
        }
        if (value.length < 6) {
          return 'Şifre 6 haneli olmalıdır';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordInput() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      keyboardType: TextInputType.number,
      style: TextStyle(color: AppTheme.textPrimaryColor, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Şifre Tekrar',
        hintText: 'Şifrenizi tekrar girin',
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          color: AppTheme.primaryColor,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword
                ? Icons.visibility_off_rounded  // Şifre gizli - kapalı göz ikonu
                : Icons.visibility_rounded,     // Şifre görünür - açık göz ikonu
            color: AppTheme.primaryColor,
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
          return 'Lütfen şifrenizi tekrar girin';
        }
        if (value != _passwordController.text) {
          return 'Şifreler eşleşmiyor';
        }
        return null;
      },
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: _acceptTerms,
            activeColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (value) {
              setState(() {
                _acceptTerms = value ?? false;
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _acceptTerms = !_acceptTerms;
              });
            },
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 13,
                ),
                children: [
                  const TextSpan(text: 'Kullanım koşullarını ve '),
                  TextSpan(
                    text: 'gizlilik politikasını ',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        _showPrivacyPolicyDialog();
                      },
                  ),
                  const TextSpan(text: 'kabul ediyorum.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _register,
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
                    'Kayıt Yapılıyor...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Kayıt Ol',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
    );
  }

  Widget _buildLoginRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Zaten hesabınız var mı?',
          style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
        ),
        TextButton(
          onPressed: () {
            safeNavigate(context, AppRoutes.login);
          },
          child: Text(
            'Giriş Yap',
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
}
