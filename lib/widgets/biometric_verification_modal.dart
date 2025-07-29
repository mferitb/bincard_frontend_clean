import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/biometric_service.dart';
import '../services/auth_service.dart';

class BiometricVerificationModal extends StatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;
  final VoidCallback? onFailure;
  final String title;
  final String subtitle;
  final int maxAttempts;

  const BiometricVerificationModal({
    super.key,
    this.onSuccess,
    this.onCancel,
    this.onFailure,
    this.title = 'Biyometrik Doğrulama',
    this.subtitle = 'Giriş yapmak için parmak izinizi kullanın',
    this.maxAttempts = 3,
  });

  @override
  State<BiometricVerificationModal> createState() => _BiometricVerificationModalState();
}

class _BiometricVerificationModalState extends State<BiometricVerificationModal>
    with TickerProviderStateMixin {
  final BiometricService _biometricService = BiometricService();
  final AuthService _authService = AuthService();
  
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;
  
  bool _isAuthenticating = false;
  bool _isSuccess = false;
  bool _isError = false;
  String _errorMessage = '';
  int _currentAttempt = 0;
  
  @override
  void initState() {
    super.initState();
    
    // Pulse animation for the fingerprint icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Shake animation for error states
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
    
    // Start authentication automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBiometricAuthentication();
    });
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }
  
  Future<void> _startBiometricAuthentication() async {
    if (_currentAttempt >= widget.maxAttempts) {
      _handleMaxAttemptsReached();
      return;
    }
    
    setState(() {
      _isAuthenticating = true;
      _isError = false;
      _errorMessage = '';
    });
    
    // Start pulse animation
    _pulseController.repeat(reverse: true);
    
    try {
      final success = await _authService.loginWithBiometrics();
      
      if (success) {
        _handleSuccess();
      } else {
        _handleFailure();
      }
    } catch (e) {
      _handleFailure(error: e.toString());
    }
  }
  
  void _handleSuccess() {
    _pulseController.stop();
    setState(() {
      _isAuthenticating = false;
      _isSuccess = true;
      _isError = false;
    });
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // Wait a moment to show success state, then call callback
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        widget.onSuccess?.call();
        Navigator.of(context).pop(true);
      }
    });
  }
  
  void _handleFailure({String? error}) {
    _pulseController.stop();
    _currentAttempt++;
    
    setState(() {
      _isAuthenticating = false;
      _isError = true;
      _errorMessage = error ?? 'Biyometrik doğrulama başarısız oldu';
    });
    
    // Shake animation for error
    _shakeController.forward().then((_) {
      _shakeController.reset();
    });
    
    // Haptic feedback
    HapticFeedback.heavyImpact();
    
    if (_currentAttempt >= widget.maxAttempts) {
      _handleMaxAttemptsReached();
    } else {
      // Show retry option
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && !_isSuccess) {
          setState(() {
            _isError = false;
            _errorMessage = '';
          });
        }
      });
    }
  }
  
  void _handleMaxAttemptsReached() {
    setState(() {
      _isAuthenticating = false;
      _isError = true;
      _errorMessage = 'Maksimum deneme sayısına ulaşıldı. Şifre ile giriş yapın.';
    });
    
    widget.onFailure?.call();
    
    // Auto close after showing error
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.of(context).pop(false);
      }
    });
  }
  
  void _handleCancel() {
    widget.onCancel?.call();
    Navigator.of(context).pop(false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Biometric Icon with animations
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isAuthenticating ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getIconBackgroundColor(),
                            boxShadow: [
                              BoxShadow(
                                color: _getIconBackgroundColor().withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _getIconData(),
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Status message
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStatusMessage(),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!_isSuccess && _currentAttempt < widget.maxAttempts) ...[
                  // Cancel button
                  TextButton(
                    onPressed: _handleCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'İptal',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  // Retry button (only show if there was an error and attempts remaining)
                  if (_isError && !_isAuthenticating && _currentAttempt < widget.maxAttempts)
                    ElevatedButton(
                      onPressed: _startBiometricAuthentication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tekrar Dene',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ],
            ),
            
            // Attempt counter
            if (_currentAttempt > 0 && _currentAttempt < widget.maxAttempts)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Kalan deneme: ${widget.maxAttempts - _currentAttempt}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusMessage() {
    if (_isSuccess) {
      return Text(
        'Doğrulama başarılı!',
        key: const ValueKey('success'),
        style: TextStyle(
          fontSize: 16,
          color: Colors.green[600],
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      );
    } else if (_isError) {
      return Text(
        _errorMessage,
        key: const ValueKey('error'),
        style: TextStyle(
          fontSize: 14,
          color: Colors.red[600],
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      );
    } else if (_isAuthenticating) {
      return Text(
        'Parmak izinizi sensöre yerleştirin',
        key: const ValueKey('authenticating'),
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      );
    } else {
      return Text(
        'Doğrulama için parmak izinizi kullanın',
        key: const ValueKey('waiting'),
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      );
    }
  }
  
  Color _getIconBackgroundColor() {
    if (_isSuccess) {
      return Colors.green;
    } else if (_isError) {
      return Colors.red;
    } else if (_isAuthenticating) {
      return AppTheme.primaryColor;
    } else {
      return Colors.grey[400]!;
    }
  }
  
  IconData _getIconData() {
    if (_isSuccess) {
      return Icons.check;
    } else if (_isError) {
      return Icons.error_outline;
    } else {
      return Icons.fingerprint;
    }
  }
}

// Helper function to show the biometric modal
Future<bool?> showBiometricVerificationModal(
  BuildContext context, {
  String title = 'Biyometrik Doğrulama',
  String subtitle = 'Giriş yapmak için parmak izinizi kullanın',
  int maxAttempts = 3,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => BiometricVerificationModal(
      title: title,
      subtitle: subtitle,
      maxAttempts: maxAttempts,
    ),
  );
}