import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../../theme/app_theme.dart';
import '../../routes.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/auth_model.dart';
import '../../services/secure_storage_service.dart';
import 'reset_password_screen.dart';

class LoginSmsVerifyScreen extends StatefulWidget {
  final String phoneNumber;
  final String password;
  final bool isPasswordReset;

  const LoginSmsVerifyScreen({
    super.key,
    required this.phoneNumber,
    required this.password,
    this.isPasswordReset = false,
  });

  @override
  _LoginSmsVerifyScreenState createState() => _LoginSmsVerifyScreenState();
}

class _LoginSmsVerifyScreenState extends State<LoginSmsVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );

  bool _isLoading = false;
  String _errorMessage = '';
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final SecureStorageService _secureStorage = SecureStorageService();

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        // 6 haneli kodu birleştir
        final code = _controllers.map((c) => c.text).join();
        
        if (code.length != 6) {
          setState(() {
            _errorMessage = 'Lütfen 6 haneli doğrulama kodunu girin';
            _isLoading = false;
          });
          return;
        }

        if (widget.isPasswordReset) {
          // Şifre sıfırlama doğrulama kodu kontrolü
          await _verifyPasswordResetCode(code);
        } else {
          // Normal giriş doğrulama kodu kontrolü
          await _verifyLoginCode(code);
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyPasswordResetCode(String code) async {
  setState(() {
    _isLoading = true;
    _errorMessage = '';  // null yerine boş string kullanıldı
  });

  try {
    // API isteği
    final response = await _apiService.post(
      '/user/password/verify-code',
      data: {'code': code},
      useLoginDio: true,
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;

      // Başarılı yanıt kontrolü
      if (data['isSuccess'] == true || data['success'] == true) {
        final resetToken = data['message'] ?? data['resetToken'];

        if (resetToken != null && resetToken is String && resetToken.isNotEmpty) {
          // resetToken'ı güvenli belleğe kaydet
          await _secureStorage.setUserData(resetToken);

          // Şifre sıfırlama ekranına geç
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResetPasswordScreen(
                  phoneNumber: widget.phoneNumber,
                  resetToken: resetToken,
                ),
              ),
            );
          }
        } else {
          throw Exception('Doğrulama başarılı ancak reset token alınamadı.');
        }
      } else {
        final message = data['message'] ?? 'Doğrulama başarısız oldu.';
        throw Exception(message);
      }
    } else {
      final message = response.data?['message'] ?? 'Doğrulama başarısız oldu.';
      throw Exception(message);
    }
  } on DioException catch (e) {
    setState(() {
      _errorMessage = e.response?.data?['message'] ?? 'Bağlantı hatası';
    });
  } catch (e) {
    setState(() {
      _errorMessage = e.toString();
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  Future<void> _verifyLoginCode(String code) async {
    try {
      // Cihaz ve IP bilgilerini al
      final deviceInfo = await _authService.getDeviceInfo();
      final ipAddress = await _authService.getIpAddress();
      final appVersion = await _authService.getAppVersion();
      final platform = _authService.getPlatform();

      // API isteği için verileri hazırla
      final data = {
        'code': code,
        'ipAddress': ipAddress,
        'deviceInfo': deviceInfo,
        'appVersion': appVersion,
        'platform': platform,
      };

      debugPrint('SMS doğrulama isteği gönderiliyor: $data');

      // API isteği gönder
      final response = await _apiService.post(
        '/auth/phone-verify',
        data: data,
        useLoginDio: true,
      );

      if (response.statusCode == 200 && response.data != null) {
        // accessToken veya refreshToken yoksa hata mesajı göster
        if (response.data['accessToken'] == null || response.data['refreshToken'] == null) {
          final message = response.data['message'] ?? 'Doğrulama başarısız oldu.';
          throw Exception(message);
        }
        
        // Token yanıtını işle
        final tokenResponse = TokenResponseDTO.fromJson(response.data);
        
        // Token'ları güvenli depolamaya kaydet
        await _secureStorage.setAccessToken(tokenResponse.accessToken.token);
        await _secureStorage.setRefreshToken(tokenResponse.refreshToken.token);
        await _secureStorage.setAccessTokenExpiry(tokenResponse.accessToken.expiredAt.toIso8601String());
        await _secureStorage.setRefreshTokenExpiry(tokenResponse.refreshToken.expiredAt.toIso8601String());
        
        // Phone number'ı da güvenli depolamaya kaydet
        await _secureStorage.setUserPhone(widget.phoneNumber);
        debugPrint('Phone number saved to secure storage: ${widget.phoneNumber}');
        
        // Token interceptor'ı etkinleştir
        _apiService.setupTokenInterceptor();
        
        // Ana sayfaya yönlendir
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        }
      } else {
        final message = response.data?['message'] ?? 'Doğrulama başarısız oldu.';
        throw Exception(message);
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?['message'] ?? 'Bağlantı hatası';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isPasswordReset ? 'Şifre Sıfırlama Doğrulama' : 'SMS Doğrulama'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Icon(
                    widget.isPasswordReset ? Icons.lock_reset : Icons.phone_android,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Doğrulama Kodu',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isPasswordReset
                        ? 'Şifrenizi sıfırlamak için telefonunuza gönderilen 6 haneli doğrulama kodunu girin.'
                        : 'Yeni cihaz algılandı. Giriş için telefonunuza gönderilen 6 haneli doğrulama kodunu girin.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  _buildVerificationCodeFields(),
                  const SizedBox(height: 24),
                  if (_errorMessage.isNotEmpty) ...[
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
                    const SizedBox(height: 24),
                  ],
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Doğrula',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Geri Dön',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationCodeFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        6,
        (index) => SizedBox(
          width: 45,
          child: TextFormField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            inputFormatters: [
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) {
              if (value.isNotEmpty) {
                if (index < 5) {
                  _focusNodes[index + 1].requestFocus();
                } else {
                  _focusNodes[index].unfocus();
                  // Son karakter girildiğinde otomatik doğrulama yap
                  _verifyCode();
                }
              } else if (index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '';
              }
              return null;
            },
          ),
        ),
      ),
    );
  }
} 