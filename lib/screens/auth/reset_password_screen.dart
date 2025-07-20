import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/secure_storage_service.dart'; // Add this import
import '../../constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'login_screen.dart';
import 'refresh_login_screen.dart';
import '../../routes.dart'; // Import for AppRoutes

class ResetPasswordScreen extends StatefulWidget {
  final String phoneNumber;
  final String resetToken;
  
  const ResetPasswordScreen({
    super.key,
    required this.phoneNumber,
    required this.resetToken,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _apiService = ApiService();
  final _secureStorage = SecureStorageService(); // Add secure storage service
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Telefon numarasını SharedPreferences'a kaydetme yardımcı metodu
  Future<void> _savePhoneToPrefs(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_used_phone', phoneNumber);
      debugPrint('📱 Telefon numarası SharedPreferences\'a kaydedildi: $phoneNumber');
    } catch (e) {
      debugPrint('⚠️ Telefon numarasını SharedPreferences\'a kaydederken hata: $e');
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Save the phone number to secure storage before making any API calls
      await _secureStorage.setUserPhone(widget.phoneNumber);
      debugPrint('📱 Telefon numarası secure storage\'a kaydedildi: ${widget.phoneNumber}');
      
      // Ayrıca telefon numarasını SharedPreferences'a da kaydedelim (yedek olarak)
      await _savePhoneToPrefs(widget.phoneNumber);

      // API isteği gönder
      final response = await _apiService.post(
        ApiConstants.passwordResetEndpoint,
        data: {
          'resetToken': widget.resetToken,
          'newPassword': _passwordController.text,
        },
        useLoginDio: true,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map && response.data['success'] == true) {
          if (!mounted) return;

          // Şifre sıfırlama başarılı - artık otomatik giriş yapmıyoruz
          debugPrint('✅ Şifre sıfırlama başarılı');
          
          // Telefon numarasını kaydet (başarılı işlem sonrası garanti olsun)
          await _secureStorage.setUserPhone(widget.phoneNumber);
          await _savePhoneToPrefs(widget.phoneNumber);
          debugPrint('📱 Telefon numarası başarıyla kaydedildi: ${widget.phoneNumber}');

          // Clear the refresh token and related data after successful password reset
          await _secureStorage.clearTokens();
          debugPrint('🔄 Tokenlar temizlendi, kullanıcı login ekranına yönlendirilecek');

          // Başarı mesajını göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Şifreniz başarıyla sıfırlandı! Lütfen yeni şifrenizle giriş yapın.'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );

          // Kısa bir gecikme ile login ekranına yönlendir
          await Future.delayed(const Duration(milliseconds: 500));

          // Login ekranına yönlendir
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        } else {
          setState(() {
            _errorMessage = response.data['message'] ?? 'Şifre sıfırlama başarısız oldu.';
          });
        }
      } else {
        setState(() {
          _errorMessage = response.data?['message'] ?? 'Şifre sıfırlama başarısız oldu.';
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?['message'] ?? 'Bağlantı hatası';
      });
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

  @override
  Widget build(BuildContext context) {
    print('Reset page loaded');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifre Sıfırlama'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 140,
                  height: 140,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Yeni Şifre Belirleyin',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Lütfen hesabınız için yeni bir şifre belirleyin.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              _buildPasswordField(),
              const SizedBox(height: 16),
              _buildConfirmPasswordField(),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildErrorMessage(),
              ],
              const SizedBox(height: 24),
              _buildResetButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      keyboardType: TextInputType.number,
      maxLength: 6,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        labelText: 'Yeni Şifre',
        hintText: '6 haneli sayı girin',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen bir şifre girin';
        }
        if (value.length != 6) {
          return 'Şifre tam olarak 6 haneli olmalıdır';
        }
        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
          return 'Şifre sadece sayılardan oluşmalıdır';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      keyboardType: TextInputType.number,
      maxLength: 6,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        labelText: 'Şifre Tekrar',
        hintText: '6 haneli şifrenizi tekrar girin',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
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

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _resetPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Şifremi Sıfırla',
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }
}