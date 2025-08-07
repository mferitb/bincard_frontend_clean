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
import '../models/station_model.dart';
import '../services/station_service.dart';
import 'favorite_stations_screen.dart';
import '../services/user_service.dart';
import '../routes.dart';
import '../services/secure_storage_service.dart';
import '../services/routes_service.dart';
import '../models/route_model.dart';
import '../widgets/custom_message.dart';
import 'route_detail_map_screen.dart';
import '../services/routes_service.dart';
import 'favorite_routes_screen.dart';

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
            CustomMessage.show(
              context,
              message: 'Biyometrik kimlik doğrulama aktifleştirildi',
              type: MessageType.success,
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
          CustomMessage.show(
            context,
            message: 'Biyometrik kimlik doğrulama devre dışı bırakıldı',
            type: MessageType.warning,
          );
        }
      }
    } catch (e) {
      debugPrint('Biyometrik ayarı değiştirirken hata: $e');
      if (mounted) {
        CustomMessage.show(
          context,
          message: 'Biyometrik ayarı değiştirilemedi: $e',
          type: MessageType.error,
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
              const SizedBox(height: 12),
              _buildFavoriteStationsButton(context),
              const SizedBox(height: 12),
              _buildFavoriteRoutesButton(context),
              const SizedBox(height: 24),
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
              _buildFreezeAccountItem(),
              const SizedBox(height: 12),
              _buildDeleteAccountItem(),
              const SizedBox(height: 16),
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
    Color? iconColor,
    Color? textColor,
    Color? iconBackgroundColor,
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
                color: iconBackgroundColor ?? AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor ?? AppTheme.primaryColor, size: 20),
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
                      color: textColor ?? AppTheme.textPrimaryColor,
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

  Widget _buildFreezeAccountItem() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
      child: _buildInfoItem(
        icon: Icons.pause_circle_outline,
        title: 'Hesabımı Dondur',
        onTap: () async {
          // İlk onay dialog'u
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Hesabınızı dondurmak istediğinize emin misiniz?'),
              content: const Text('Hesabınız dondurulduğunda geçici olarak erişiminiz kısıtlanacak. Daha sonra tekrar aktifleştirebilirsiniz.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Vazgeç'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Devam Et'),
                ),
              ],
            ),
          );
          
          if (confirmed == true) {
            // Dondurma detayları dialog'u
            String? reason;
            int? freezeDurationDays;
            
            final detailsEntered = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                final reasonController = TextEditingController();
                final durationController = TextEditingController(text: '30'); // Default 30 gün
                
                return AlertDialog(
                  title: const Text('Hesap Dondurma Detayları'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hesap dondurma nedeninizi belirtin:'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: reasonController,
                          maxLines: 3,
                          maxLength: 500,
                          decoration: const InputDecoration(
                            labelText: 'Dondurma Nedeni (Zorunlu)',
                            border: OutlineInputBorder(),
                            hintText: 'Örn: Geçici olarak uygulamayı kullanamayacağım',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Kaç gün süreyle dondurmak istiyorsunuz?'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: durationController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Gün Sayısı (1-365)',
                            border: OutlineInputBorder(),
                            suffixText: 'gün',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Minimum: 1 gün\n• Maksimum: 365 gün',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () {
                        final enteredReason = reasonController.text.trim();
                        final enteredDuration = int.tryParse(durationController.text.trim());
                        
                        if (enteredReason.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Dondurma nedeni boş bırakılamaz')),
                          );
                          return;
                        }
                        
                        if (enteredReason.length > 500) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Dondurma nedeni 500 karakteri geçemez')),
                          );
                          return;
                        }
                        
                        if (enteredDuration == null || enteredDuration < 1 || enteredDuration > 365) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Dondurma süresi 1-365 gün arasında olmalıdır')),
                          );
                          return;
                        }
                        
                        reason = enteredReason;
                        freezeDurationDays = enteredDuration;
                        Navigator.of(context).pop(true);
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.orange),
                      child: const Text('Hesabımı Dondur'),
                    ),
                  ],
                );
              },
            );
            
            if (detailsEntered == true && reason != null && freezeDurationDays != null) {
              setState(() { _isLoading = true; });
              final result = await UserService().freezeAccount(
                reason: reason!,
                freezeDurationDays: freezeDurationDays!,
              );
              setState(() { _isLoading = false; });
              if (result.success) {
                if (mounted) {
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hesap Donduruldu'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(result.message ?? 'Hesabınız başarıyla donduruldu.'),
                          const SizedBox(height: 12),
                          Text('Dondurma süresi: $freezeDurationDays gün', 
                               style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Hesabınız belirtilen süre sonunda otomatik olarak aktif hale gelecektir.',
                               style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Tamam'),
                        ),
                      ],
                    ),
                  );
                  // Hesap dondurulduktan sonra çıkış yap
                  await SecureStorageService().clearAccessToken();
                  await SecureStorageService().clearRefreshToken();
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                }
              } else {
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hata'),
                      content: Text(result.message ?? 'Hesap dondurulurken bir hata oluştu.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Tamam'),
                        ),
                      ],
                    ),
                  );
                }
              }
            } else {
              // Detaylar girilmedi veya iptal edildi
              if (mounted) {
                String message = 'Hesap dondurma işlemi iptal edildi';
                if (detailsEntered == true && (reason == null || reason!.isEmpty)) {
                  message = 'Hesap dondurmak için tüm bilgileri girmeniz zorunludur';
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            }
          }
        },
        // Turuncu ikon ve metin için renk override
        iconColor: Colors.orange,
        textColor: Colors.orange,
        iconBackgroundColor: Colors.orange.withOpacity(0.08),
      ),
    );
  }

  Widget _buildDeleteAccountItem() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
      child: _buildInfoItem(
        icon: Icons.delete_forever,
        title: 'Hesabımı Sil',
        onTap: () async {
          // İlk onay dialog'u
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Hesabınızı silmek istediğinize emin misiniz?'),
              content: const Text('Bu işlem geri alınamaz. Devam etmek için şifrenizi girmeniz gerekecek.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Vazgeç'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Devam Et'),
                ),
              ],
            ),
          );
          
          if (confirmed == true) {
            // Şifre girme dialog'u
            String? password;
            final passwordEntered = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                final passwordController = TextEditingController();
                return AlertDialog(
                  title: const Text('Hesap Silme Onayı'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Hesabınızı silmek için şifrenizi girin:'),
                      const SizedBox(height: 8),
                      const Text(
                        'Bu işlem geri alınamaz!', 
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Şifre (Zorunlu)',
                          border: OutlineInputBorder(),
                          hintText: 'Mevcut şifrenizi girin',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () {
                        final enteredPassword = passwordController.text.trim();
                        if (enteredPassword.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Şifre alanı boş bırakılamaz')),
                          );
                          return;
                        }
                        password = enteredPassword;
                        Navigator.of(context).pop(true);
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Hesabımı Sil'),
                    ),
                  ],
                );
              },
            );
            
            if (passwordEntered == true && password != null && password!.isNotEmpty) {
              setState(() { _isLoading = true; });
              final result = await UserService().deactivateUser(
                password: password!,
                reason: 'Kullanıcı hesap silme talebinde bulundu',
              );
              setState(() { _isLoading = false; });
              if (result.success) {
                if (mounted) {
                  await SecureStorageService().clearAccessToken();
                  await SecureStorageService().clearRefreshToken();
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Başarılı'),
                      content: Text(result.message ?? 'Kullanıcı hesabı silindi.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Tamam'),
                        ),
                      ],
                    ),
                  );
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                }
              } else {
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hata'),
                      content: Text(result.message ?? 'Hesap silinirken bir hata oluştu.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Tamam'),
                        ),
                      ],
                    ),
                  );
                }
              }
            } else {
              // Şifre girilmedi veya iptal edildi
              if (mounted) {
                String message = 'Hesap silme işlemi iptal edildi';
                if (passwordEntered == true && (password == null || password!.isEmpty)) {
                  message = 'Hesap silme için şifre girmeniz zorunludur';
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            }
          }
        },
        // Kırmızı ikon ve metin için renk override
        iconColor: Colors.red,
        textColor: Colors.red,
        iconBackgroundColor: Colors.redAccent.withOpacity(0.08),
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

  Widget _buildFavoriteStationsButton(BuildContext context) {
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
          child: const Icon(Icons.star, color: Colors.amber, size: 24),
        ),
        title: const Text(
          'Favori Durakların',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FavoriteStationsScreen()),
          );
        },
      ),
    );
  }

  Widget _buildFavoriteRoutesButton(BuildContext context) {
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
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.star, color: Colors.amber, size: 24),
        ),
        title: const Text(
          'Favori Rotaların',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FavoriteRoutesScreen(),
            ),
          );
        },
      ),
    );
  }
}
