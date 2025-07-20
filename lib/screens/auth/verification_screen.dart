import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/secure_storage_service.dart';
import '../../services/api_service.dart';
import '../../constants/api_constants.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isPasswordReset;

  const VerificationScreen({
    super.key, 
    required this.phoneNumber,
    this.isPasswordReset = false
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final _authService = AuthService();
  final _userService = UserService();
  final _secureStorage = SecureStorageService();
  final _apiService = ApiService();
  
  // Tüm kutularda rakam olup olmadığını kontrol eden değişken
  bool _isCodeComplete = false;

  bool _isLoading = false;
  String _errorMessage = '';
  int _remainingTime = 180; // 3 dakika (180 saniye)
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    
    // Her kod girişinde kontrol et
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].addListener(() {
        _checkCodeCompletion();
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  // Tüm kutularda rakam olup olmadığını kontrol et
  void _checkCodeCompletion() {
    bool isComplete = _controllers.every((controller) => controller.text.isNotEmpty);
    
    if (isComplete != _isCodeComplete) {
      setState(() {
        _isCodeComplete = isComplete;
      });
      
      // Tüm kutular doluysa otomatik doğrula
      if (isComplete) {
        // Klavyeyi kapat ve kısa bir gecikme ile doğrula
        FocusScope.of(context).unfocus();
        Future.delayed(const Duration(milliseconds: 300), () {
          _verifyCode();
        });
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Tüm kod kutularını temizle
  void _clearAllFields() {
    for (var controller in _controllers) {
      controller.clear();
    }
    setState(() {
      _isCodeComplete = false;
    });
    // İlk kutucuğa odaklan
    FocusScope.of(context).requestFocus(_focusNodes[0]);
  }

  Future<void> _verifyCode() async {
  if (_isLoading) return;

  // Doğrudan birleştir (liste üzerinde dolaşmadan)
  String codeStr = '';
  for (int i = 0; i < _controllers.length; i++) {
    codeStr += _controllers[i].text;
    debugPrint('Kutu $i: ${_controllers[i].text}');
  }
  
  debugPrint('Birleştirilmiş kod: $codeStr (${codeStr.runtimeType})');
  
  if (codeStr.length != 6) {
    setState(() {
      _errorMessage = 'Lütfen 6 haneli doğrulama kodunu giriniz';
    });
    return;
  }

  // Tüm karakterlerin rakam olduğunu kontrol et
  if (!RegExp(r'^\d+$').hasMatch(codeStr)) {
    setState(() {
      _errorMessage = 'Kod sadece rakamlardan oluşmalıdır';
    });
    return;
  }
  
  debugPrint('Kod doğrulanıyor: $codeStr');

  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });

  try {
    if (widget.isPasswordReset) {
      debugPrint('Şifre sıfırlama doğrulama kodu: $codeStr');
      
      // API'ye göndermeden önce veri yapısını kontrol et
      Map<String, dynamic> requestData = {'code': codeStr};
      debugPrint('API isteği verisi: $requestData');
      
      try {
        String token = await _verifyPasswordResetCode(codeStr);
        debugPrint('API token yanıtı: $token');

        if (!mounted) return;
        
        // Başarılı doğrulama durumunda kullanıcıyı bilgilendir
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kod doğrulandı, yeni şifre belirleyin.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Yeni şifre belirleme ekranına yönlendir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              phoneNumber: widget.phoneNumber,
              resetToken: token,
            ),
          ),
        );
      } catch (innerError) {
        debugPrint('⚠️ Şifre sıfırlama kodu doğrulama hatası: $innerError');
        throw innerError; // Dışarıdaki catch bloğunun yakalaması için hatayı yeniden fırlat
      }
    } else {
      // Normal kayıt doğrulama
      int? code = int.tryParse(codeStr);
      if (code == null) {
        setState(() {
          _errorMessage = 'Kod sadece rakamlardan oluşmalıdır';
          _isLoading = false;
        });
        return;
      }
      
      final message = await _authService.verifyPhoneNumber(code);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  } catch (e) {
    debugPrint('Doğrulama hatası: $e');
    setState(() {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isCodeComplete = false;
    });
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}  Future<String> _verifyPasswordResetCode(String codeStr) async {
  print('Gönderilen kod: $codeStr');

  int code = int.parse(codeStr);

  try {
    final response = await _apiService.post(
      ApiConstants.passwordVerifyCodeEndpoint,
      data: {'code': code},
      useLoginDio: true,
    );

    print('API yanıtı: ${response.data} (${response.data.runtimeType})');

    if (response.data == null || response.data is! Map<String, dynamic>) {
      throw Exception('API yanıtı boş veya geçersiz formatta.');
    }

    final data = response.data as Map<String, dynamic>;
    
    // Debug log to see all response keys
    print('API yanıtı anahtarları: ${data.keys.toList()}');

    // API yanıtındaki başarı durumunu kontrol et - isSuccess veya success anahtarı olabilir
    bool isSuccess = false;
    if (data.containsKey('success')) {
      isSuccess = data['success'] == true;
      print('Success key found: $isSuccess');
    } else if (data.containsKey('isSuccess')) {
      isSuccess = data['isSuccess'] == true;
      print('isSuccess key found: $isSuccess');
    }
    
    final String message = data['message'] ?? '';
    print('Message from API: $message');

    // Return token (message) even if success is not explicitly true
    // This is because some API responses might be differently structured
    // but still contain valid tokens in the message field
    if (message.isNotEmpty && !message.toLowerCase().contains('hata') && !message.toLowerCase().contains('error')) {
      print('Reset token: $message');
      return message; // reset token
    } else if (isSuccess) {
      print('isSuccess true but empty message, using empty token');
      return message; // return even empty message if success is true
    } else {
      throw Exception('Kod doğrulama başarısız: $message');
    }

  } catch (e) {
    print('API Hatası: $e');
    rethrow;
  }
}






  Future<void> _resendCode() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _canResend = false;
    });

    try {
      // Telefon numarası formatlama
      String formattedPhone = widget.phoneNumber;
      
      // Parantez, boşluk ve tire gibi karakterleri kaldır
      formattedPhone = formattedPhone.replaceAll(RegExp(r'[\s\(\)\-]'), '');
      
      // Sadece rakamlardan oluştuğundan emin ol
      formattedPhone = formattedPhone.replaceAll(RegExp(r'[^0-9]'), '');
      
      // Başında 0 veya 90 varsa kaldır, sade 10 haneli numara olsun
      if (formattedPhone.startsWith('0')) {
        formattedPhone = formattedPhone.substring(1);
      } else if (formattedPhone.startsWith('90') && formattedPhone.length >= 12) {
        formattedPhone = formattedPhone.substring(2);
      }
      
      // 10 haneden uzun ise son 10 haneyi al
      if (formattedPhone.length > 10) {
        formattedPhone = formattedPhone.substring(formattedPhone.length - 10);
      }
      
      debugPrint('📱 Formatlanmış telefon: $formattedPhone');

      // İşlem türüne göre farklı endpoint ve parametre kullan
      if (widget.isPasswordReset) {
        // Şifre sıfırlama kodu yeniden gönderme
        debugPrint('🔄 Şifre sıfırlama kodu yeniden gönderiliyor...');
        
        try {
          // API çağrısını dene
          final response = await _apiService.post(
            ApiConstants.passwordForgotEndpoint,
            queryParameters: {'phone': formattedPhone},
            useLoginDio: true,
          );
          
          debugPrint('✅ API yanıtı: Status=${response.statusCode}, Body=${response.data}');
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            // Başarılı yanıt - işleme devam et
            bool isSuccess = true;
            String message = 'Şifre sıfırlama kodu yeniden gönderildi!';
            
            // Yanıt içeriğini kontrol et
            if (response.data != null && response.data is Map) {
              if (response.data.containsKey('success')) {
                isSuccess = response.data['success'] == true;
              } else if (response.data.containsKey('isSuccess')) {
                isSuccess = response.data['isSuccess'] == true;
              }
              
              if (response.data.containsKey('message') && response.data['message'] != null) {
                message = response.data['message'].toString();
              }
            }
            
            // Başarı durumunu göster
            debugPrint('Kod yeniden gönderme başarı durumu: $isSuccess');
            debugPrint('Mesaj: $message');
            
            // Zamanı sıfırla (3 dakika) ve timeri başlat
            setState(() {
              _remainingTime = 180; // 3 dakika
            });
            _startTimer();

            // Kod kutularını temizle
            _clearAllFields();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            throw Exception('Sunucudan geçersiz yanıt alındı (${response.statusCode})');
          }
        } catch (innerException) {
          debugPrint('Şifre sıfırlama kod gönderme hatası: $innerException');
          throw innerException; // Hatayı dışarıdaki catch bloğuna ilet
        }
      } else {
        // Normal doğrulama kodu yeniden gönderme
        final response = await _authService.resendVerificationCode(formattedPhone);

        if (response.success) {
          // Zamanı sıfırla (3 dakika) ve timeri başlat
          setState(() {
            _remainingTime = 180; // 3 dakika
          });
          _startTimer();

          // Kod kutularını temizle
          _clearAllFields();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Yeni doğrulama kodu gönderildi'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _errorMessage = response.message ?? 'Kod gönderme işlemi başarısız oldu.';
            _canResend = true;
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ Kod yeniden gönderme hatası: $e');
      String errorMessage = 'Beklenmeyen bir hata oluştu';
      
      // DioException ise daha detaylı mesaj göster
      if (e is DioException) {
        if (e.response != null && e.response!.data != null) {
          try {
            var responseData = e.response!.data;
            if (responseData is Map && responseData.containsKey('message')) {
              errorMessage = responseData['message'].toString();
            }
          } catch (innerError) {
            debugPrint('Yanıt işlenirken hata: $innerError');
          }
        } else {
          errorMessage = 'Bağlantı hatası: ${e.message}';
        }
      } else {
        // Genel hata
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
      
      setState(() {
        _errorMessage = errorMessage;
        _canResend = true;
      });
      
      // Kullanıcıyı bilgilendir
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telefon Doğrulama'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: GestureDetector(
        // Ekranın herhangi bir yerine tıklandığında klavyeyi kapat
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                Center(
                  child: Image.asset(
                    'assets/images/logo2.png',
                    width: 140,
                    height: 140,
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    widget.isPasswordReset 
                        ? 'Şifre Sıfırlama Kodu'
                        : 'Telefon Numaranızı Doğrulayın',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '+90 ${widget.phoneNumber} numaralı telefonunuza gönderilen 6 haneli doğrulama kodunu giriniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildVerificationCodeInput(),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _clearAllFields,
                    child: Text(
                      "Kodu Temizle",
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildResendCodeSection(),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildErrorMessage(),
                ],
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationCodeInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        6,
        (index) => SizedBox(
          width: 45,
          child: RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (event) {
              if (event is RawKeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.backspace) {
                  // Eğer mevcut kutu boşsa ve ilk kutu değilse, bir önceki kutuya git
                  if (_controllers[index].text.isEmpty && index > 0) {
                    _controllers[index - 1].clear(); // Önceki kutuyu temizle
                    FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                  }
                }
              }
            },
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              decoration: InputDecoration(
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              onChanged: (value) {
                // Değer girince sonraki kutuya geç
                if (value.isNotEmpty && index < 5) {
                  FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendCodeSection() {
    return Column(
      children: [
        Text(
          widget.isPasswordReset 
              ? 'Şifre sıfırlama kodunuz gelmedi mi?'
              : 'Doğrulama kodunuz gelmedi mi?',
          style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _canResend ? _resendCode : null,
              child: Text(
                widget.isPasswordReset
                    ? 'Şifre Sıfırlama Kodu Gönder'
                    : 'Yeniden Kod Gönder',
                style: TextStyle(
                  color: _canResend ? AppTheme.primaryColor : Colors.grey.shade400,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (!_canResend) ...[
              const SizedBox(width: 10),
              Text(
                _formatTime(_remainingTime),
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
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

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyCode,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isCodeComplete ? Colors.green : AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          disabledBackgroundColor: Colors.grey.shade400,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Text(
                _isCodeComplete ? 'Doğrulanıyor...' : 'Doğrula',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}