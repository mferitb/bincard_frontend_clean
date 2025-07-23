import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';
import '../services/theme_service.dart';
import '../services/language_service.dart';
import 'change_password_screen.dart';
import 'privacy_settings_screen.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';
import '../services/biometric_service.dart';
import 'liked_news_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isNotificationsEnabled = true;
  bool _isBiometricEnabled = false;
  bool _isBiometricAvailable = false;
  double _textScale = 0.5;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadNotificationSettings();
    _loadBiometricSettings();
  }

  Future<void> _loadSettings() async {
    // ThemeService'ten ayarları yükle
    try {
      // Provider'ı initState içinde kullanmak için
      // Provider.of yerine Future.microtask kullanıyoruz
      Future.microtask(() {
        final themeService = Provider.of<ThemeService>(context, listen: false);
        setState(() {
          // 0.8 - 1.2 aralığını 0.0 - 1.0 aralığına dönüştür
          _textScale = (themeService.textScale - 0.8) / 0.4;
          if (_textScale < 0) _textScale = 0;
          if (_textScale > 1) _textScale = 1;
        });
      });
    } catch (e) {
      debugPrint('Ayarlar yüklenirken hata: $e');
    }
  }

  Future<void> _loadNotificationSettings() async {
    // Bildirim ayarlarını yükleme
    setState(() {
      _isNotificationsEnabled = true; // Varsayılan değer
    });
  }

  Future<void> _loadBiometricSettings() async {
    try {
      final biometricService = BiometricService();
      final isAvailable = await biometricService.hasAnyBiometricEnrolled();
      final isEnabled = await biometricService.isBiometricEnabled();
      if (mounted) {
        setState(() {
          _isBiometricAvailable = isAvailable;
          _isBiometricEnabled = isEnabled;
        });
      }
    } catch (e) {
      debugPrint('Biyometrik ayarları yüklenirken hata: $e');
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _isNotificationsEnabled = value;
    });
    // Bildirim ayarını kaydet
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final biometricService = BiometricService();
      if (value) {
        // Biyometrik doğrulamayı aktifleştir
        if (!_isBiometricAvailable) {
          _showBiometricNotAvailableDialog();
          setState(() {
            _isLoading = false;
            _isBiometricEnabled = false;
          });
          return;
        }
        // Biyometrik doğrulama için kullanıcıdan izin iste (bir defalık)
        final authenticated = await biometricService.authenticate(
          reason: 'Biyometrik kimlik doğrulamayı aktifleştirmek için doğrulama yapın',
          description: 'Bu, uygulamaya girişte biyometrik kimlik doğrulamasını aktifleştirecektir',
        );
        if (authenticated) {
          await biometricService.enableBiometricAuthentication();
          setState(() {
            _isBiometricEnabled = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Biyometrik kimlik doğrulama aktifleştirildi'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        } else {
          setState(() {
            _isBiometricEnabled = false;
          });
        }
      } else {
        // Biyometrik doğrulamayı devre dışı bırak
        await biometricService.disableBiometricAuthentication();
        setState(() {
          _isBiometricEnabled = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biyometrik kimlik doğrulama devre dışı bırakıldı'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Biyometrik ayarı değiştirirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biyometrik ayarı değiştirilemedi: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showBiometricNotAvailableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Biyometrik Doğrulama Mevcut Değil'),
        content: const Text(
          'Cihazınızda biyometrik doğrulama (parmak izi, yüz tanıma) mevcut değil veya henüz kurulmamış. Lütfen cihaz ayarlarınızı kontrol edin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Null-safety kontrolü ile servisleri al
    final themeService = Provider.of<ThemeService>(context);
    final languageService = Provider.of<LanguageService>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ayarlar',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Görünüm Ayarları'),
              _buildAppearanceSettings(themeService),
              const SizedBox(height: 24),
              // HAREKETLERİN BÖLÜMÜ
              _buildSectionTitle('Hareketlerin'),
              _buildLikedNewsSection(context),
              const SizedBox(height: 24),
              _buildSectionTitle('Bildirim Ayarları'),
              _buildNotificationSettings(),
              const SizedBox(height: 24),
              _buildSectionTitle('Güvenlik Ayarları'),
              _buildSecuritySettings(),
              const SizedBox(height: 24),
              _buildSectionTitle('Dil Ayarları'),
              _buildLanguageSettings(languageService),
              const SizedBox(height: 24),
              _buildSectionTitle('Hakkında'),
              _buildAboutSettings(),
              const SizedBox(height: 32),
              _buildHelpButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildAppearanceSettings(ThemeService themeService) {
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
        children: [
          // Karanlık mod switch'i kaldırıldı
          // Sadece yazı boyutu ayarı bırakıldı
          _buildSliderItem(
            icon: Icons.text_fields,
            title: 'Yazı Boyutu',
            value: _textScale,
            onChanged: (value) {
              double actualScale = 0.8 + (value * 0.4);
              themeService.setTextScale(actualScale);
              setState(() {
                _textScale = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
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
        children: [
          _buildSwitchItem(
            icon: Icons.notifications,
            title: 'Tüm Bildirimler',
            value: _isNotificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          const Divider(),
          _buildSwitchItem(
            icon: Icons.money,
            title: 'Bakiye Bildirimleri',
            value: _isNotificationsEnabled,
            onChanged: (value) {
              setState(() {
                if (value) {
                  _isNotificationsEnabled = true;
                }
              });
              _toggleNotifications(value);
            },
          ),
          const Divider(),
          _buildSwitchItem(
            icon: Icons.campaign,
            title: 'Kampanya Bildirimleri',
            value: _isNotificationsEnabled,
            onChanged: (value) {
              setState(() {
                if (value) {
                  _isNotificationsEnabled = true;
                }
              });
              _toggleNotifications(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
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
        children: [
          _buildSwitchItem(
            icon: Icons.fingerprint,
            title: 'Biyometrik Kimlik Doğrulama',
            subtitle: _isBiometricAvailable 
                ? 'Uygulama girişinde parmak izi veya yüz tanıma kullanın'
                : 'Bu cihazda biyometrik kimlik doğrulama mevcut değil',
            value: _isBiometricEnabled,
            enabled: _isBiometricAvailable && !_isLoading,
            onChanged: _toggleBiometric,
          ),
          const Divider(),
          _buildInfoItem(
            icon: Icons.security,
            title: 'Şifre Değiştir',
            hasArrow: true,
            onTap: () {
              // Şifre değiştirme sayfasına yönlendir
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          const Divider(),
          _buildInfoItem(
            icon: Icons.lock,
            title: 'Gizlilik Ayarları',
            hasArrow: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacySettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSettings(LanguageService languageService) {
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
        children: [
          for (final language in languageService.availableLanguages)
            _buildRadioItem(
              icon: language == 'Türkçe' ? Icons.flag : Icons.language,
              title: language,
              value: language,
              groupValue: languageService.selectedLanguage,
              onChanged: (value) {
                if (value != null) {
                  languageService.setLanguage(value);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAboutSettings() {
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
        children: [
          _buildInfoItem(
            icon: Icons.info,
            title: 'Uygulama Versiyonu',
            subtitle: AppConstants.appVersion,
          ),
          const Divider(),
          _buildInfoItem(
            icon: Icons.description,
            title: 'Kullanım Koşulları',
            hasArrow: true,
            onTap: () {
              // Kullanım koşulları sayfasına yönlendir
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              );
            },
          ),
          const Divider(),
          _buildInfoItem(
            icon: Icons.privacy_tip,
            title: 'Gizlilik Politikası',
            hasArrow: true,
            onTap: () {
              // Gizlilik politikası sayfasına yönlendir
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    bool enabled = true,
    required Function(bool) onChanged,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              )
            : null,
        trailing: Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSliderItem({
    required IconData icon,
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.2),
              thumbColor: AppTheme.primaryColor,
              overlayColor: AppTheme.primaryColor.withOpacity(0.1),
            ),
            child: Slider(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioItem({
    required IconData icon,
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          Radio<String>(
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    String? subtitle,
    bool hasArrow = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasArrow)
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.primaryColor,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          // Yardım sayfasına yönlendir
        },
        icon: const Icon(Icons.help),
        label: const Text(
          'Yardım ve Destek',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // HAREKETLERİN > BEĞENDİĞİM HABERLER BÖLÜMÜ
  Widget _buildLikedNewsSection(BuildContext context) {
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.favorite, color: Colors.red, size: 24),
        ),
        title: const Text(
          'Beğendiğim Haberler',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        onTap: () {
          // Beğendiğim Haberler ekranına git
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LikedNewsScreen()),
          );
        },
      ),
    );
  }
}
