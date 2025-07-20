import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'verification_screen.dart';
import '../../routes.dart';
import '../../widgets/safe_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isVerificationSent = false;
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _sendVerificationCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        // API isteği gönder
        final phoneNumber = _phoneController.text;
        final response = await _apiService.post(
          ApiConstants.passwordForgotEndpoint,
          queryParameters: {'phone': phoneNumber},
          useLoginDio: true,
        );

        if (response.statusCode == 200 && response.data != null) {
          if (response.data['success'] == true) {
            setState(() {
              _isVerificationSent = true;
              _isLoading = false;
            });
            _animationController.reset();
            _animationController.forward();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.data['message'] ?? 'Doğrulama kodu gönderildi!'),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );

            // Şifre sıfırlama doğrulama ekranına yönlendir
            safeNavigate(context, AppRoutes.verification, arguments: {
              'phoneNumber': phoneNumber,
              'isPasswordReset': true,
            });
          } else {
            setState(() {
              _errorMessage = response.data['message'] ?? 'Doğrulama kodu gönderme başarısız oldu.';
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _errorMessage = response.data?['message'] ?? 'Doğrulama kodu gönderme başarısız oldu.';
            _isLoading = false;
          });
        }
      } on DioException catch (e) {
        setState(() {
          _errorMessage = e.response?.data?['message'] ?? 'Bağlantı hatası';
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _resetPassword() {
    // Tüm OTP alanlarının dolu olduğunu kontrol et
    String otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Lütfen 6 haneli doğrulama kodunu tam olarak girin',
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // TODO: Implement reset password logic with OTP verification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Şifre sıfırlama işlemi başlatıldı...'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Başarılı şifre sıfırlama işlemi sonrası giriş sayfasına dönüş
    Future.delayed(const Duration(seconds: 2), () {
      safeNavigate(context, AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => safeNavigate(context, AppRoutes.login),
        ),
        title: Text(
          'Şifremi Unuttum',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildPhoneInput(),
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red.shade800),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    _buildSendCodeButton(),
                    const SizedBox(height: 32),
                    _buildHelpSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Doğrudan logo görselini göster, yuvarlak arka plan olmadan
        Image.asset(
          'assets/images/logo.png',
          width: 140,
          height: 140,
        ),
        const SizedBox(height: 24),
        Text(
          'Şifrenizi mi Unuttunuz?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            _isVerificationSent
                ? 'Telefonunuza gönderilen 6 haneli kodu girin'
                : 'Kayıtlı telefon numaranızı girin ve size doğrulama kodu gönderelim',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondaryColor,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        style: TextStyle(
          color: AppTheme.textPrimaryColor,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: 'Telefon Numarası',
          hintText: '5XX XXX XX XX',
          prefixText: '+90 ',
          prefixIcon: Icon(Icons.phone, color: AppTheme.primaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          floatingLabelStyle: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        inputFormatters: [
          LengthLimitingTextInputFormatter(10),
          FilteringTextInputFormatter.digitsOnly,
        ],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Lütfen telefon numaranızı girin';
          }
          if (value.length < 10) {
            return 'Telefon numarası 10 haneli olmalıdır';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildVerificationInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundVariant1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.info_outline, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Doğrulama kodu gönderildi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+90 ${_formatPhoneNumber(_phoneController.text)} numaralı telefona gönderilen 6 haneli kodu girin.',
              style: TextStyle(color: AppTheme.textSecondaryColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPhoneNumber(String number) {
    if (number.length != 10) return number;
    return '${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6, 8)} ${number.substring(8)}';
  }

  Widget _buildOtpInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Doğrulama Kodu',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            6,
            (index) => SizedBox(
              width: 45,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    // Sonraki input'a geç
                    if (index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    } else {
                      // Son input dolduğunda klavyeyi kapat
                      FocusScope.of(context).unfocus();
                    }
                  } else if (value.isEmpty && index > 0) {
                    // Boş ise ve ilk input değilse önceki input'a geç
                    _focusNodes[index - 1].requestFocus();
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendCodeButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _sendVerificationCode,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Doğrulama Kodu Gönder',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _resetPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Şifreyi Sıfırla',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildResendCodeButton() {
    return TextButton(
      onPressed: () {
        // Kodu yeniden gönder
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Yeni doğrulama kodu gönderiliyor...'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.refresh, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            'Kodu Yeniden Gönder',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yardıma mı ihtiyacınız var?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.support_agent, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Müşteri Hizmetleriyle İletişime Geçin',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.help_outline, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sık Sorulan Sorular',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
