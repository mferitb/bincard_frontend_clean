import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'settings_screen.dart';
import '../widgets/custom_message.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';
import '../routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  UserProfile? _userProfile;
  final _userService = UserService();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    debugPrint('Profile Screen: Profil bilgileri yükleniyor...');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 🎯 ÖNCELİK: Her zaman API'den en güncel veriyi al 
      // (getUserProfile metodu zaten API ile SecureStorage'ı karşılaştırıp günceller)
      debugPrint('🎯 Profile Screen: API\'den profil alınıyor...');
      final userProfile = await _userService.getUserProfile();
      
      // UI'ı API verisisiyle güncelle (SecureStorage'dan değil!)
      setState(() {
        _userProfile = userProfile;
        _isLoading = false;
      });
      
      debugPrint('✅ Profile Screen: UI API verisiyle güncellendi - Ad: ${userProfile.name}, Soyad: ${userProfile.surname}');
      
    } catch (e) {
      debugPrint('❌ Profile Screen: Profil bilgileri yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Profil bilgileri yüklenemedi: $e';
      });
    }
  }

  void _navigateToEditProfile() async {
    debugPrint('Profile Screen: Edit profile\'a gidiyor - Mevcut profil: ${_userProfile?.name} ${_userProfile?.surname}');
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );

    debugPrint('Profile Screen: Edit profile\'dan döndü - Result: $result');

    // Profil düzenleme sayfasından dönüldüğünde her zaman profili yenile
    if (result == true) {
      debugPrint('Edit profile\'dan döndü (başarılı), profil yenileniyor...');
      
      // Force rebuild to ensure UI updates
      if (mounted) {
        setState(() {
          _isLoading = true; // Loading göster
        });
      }
      
      // Kısa bir delay ekle ve sonra yenile
      await Future.delayed(const Duration(milliseconds: 300));
      
      _loadUserProfile();
    } else {
      debugPrint('Edit profile\'dan döndü, değişiklik yapmadan çıkıldı');
      
      // Değişiklik yapılmamış olsa bile UI'ı yenile (emin olmak için)
      await Future.delayed(const Duration(milliseconds: 100));
      _loadUserProfile();
    }
  }

  void _navigateToChangePassword() async {
    debugPrint('Profile Screen: Change password sayfasına gidiyor...');
    
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
    );
    
    debugPrint('Profile Screen: Change password sayfasından döndü');
  }

  Future<void> _logout() async {
    try {
      // Logout servisi çağrılıyor
      final response = await _authService.logout();
      
      // Refresh token'ın geçerliliğini kontrol et
      final secureStorage = SecureStorageService();
      final refreshToken = await secureStorage.getRefreshToken();
      final refreshTokenExpiry = await secureStorage.getRefreshTokenExpiry();
      
      bool refreshTokenValid = false;
      if (refreshToken != null && refreshTokenExpiry != null) {
        final expiry = DateTime.parse(refreshTokenExpiry);
        refreshTokenValid = DateTime.now().isBefore(expiry);
      }
      
      // Yönlendirme işlemi
      if (mounted) {
        if (refreshTokenValid) {
          // Refresh token geçerliyse, refresh login sayfasına yönlendir
          debugPrint('Refresh token geçerli, refresh login sayfasına yönlendiriliyor');
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.refreshLogin, (route) => false);
        } else {
          // Refresh token geçersizse, normal login sayfasına yönlendir
          debugPrint('Refresh token geçersiz, login sayfasına yönlendiriliyor');
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
        }
      }
    } catch (e) {
      debugPrint('Logout işlemi sırasında hata: $e');
      // Hata durumunda yine de login sayfasına yönlendir
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
      }
    }
  }

  Future<void> _clearAndRefreshProfile() async {
    debugPrint('🧹 Manuel SecureStorage temizleme ve profil yenileme başlatıldı');
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      final secureStorage = SecureStorageService();
      
      // SecureStorage'ı tamamen temizle
      debugPrint('🧹 SecureStorage temizleniyor...');
      await secureStorage.setUserFirstName('');
      await secureStorage.setUserLastName('');
      await secureStorage.setUserPhone('');
      
      // Kısa bir delay
      await Future.delayed(const Duration(milliseconds: 300));
      
      // API'den en güncel veriyi al
      debugPrint('🔄 API\'den en güncel veriler alınıyor...');
      final userProfile = await _userService.refreshUserProfile();
      
      setState(() {
        _userProfile = userProfile;
        _isLoading = false;
      });
      
      // Final kontrol
      final finalName = await secureStorage.getUserFirstName();
      final finalSurname = await secureStorage.getUserLastName();
      debugPrint('🔍 Manuel yenileme sonrası - SecureStorage: $finalName $finalSurname');
      debugPrint('🔍 Manuel yenileme sonrası - UI State: ${userProfile.name} ${userProfile.surname}');
      
      if (mounted) {
        CustomMessage.show(
          context,
          message: 'Profil başarıyla yenilendi!',
          type: MessageType.success,
        );
      }
      
    } catch (e) {
      debugPrint('Manuel profil yenileme hatası: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Profil yenilenemedi: $e';
      });
      
      if (mounted) {
        CustomMessage.show(
          context,
          message: 'Profil yenilenemedi: $e',
          type: MessageType.error,
        );
      }
    }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profilim',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: AppTheme.primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.edit, color: AppTheme.primaryColor),
            onPressed: _navigateToEditProfile,
          ),
        ],
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingIndicator()
            : _errorMessage.isNotEmpty
                ? _buildErrorView()
                : _buildProfileContent(),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Profil bilgileri yükleniyor...'),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Hata Oluştu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUserProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_userProfile == null) {
      return const Center(child: Text('Kullanıcı bilgileri bulunamadı.'));
    }

    return RefreshIndicator(
      onRefresh: _loadUserProfile,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildSectionTitle('Kişisel Bilgiler'),
            _buildPersonalInfo(),
            const SizedBox(height: 24),
            _buildSectionTitle('İletişim Bilgileri'),
            _buildContactInfo(),
            const SizedBox(height: 24),
            _buildSectionTitle('Hesap Bilgileri'),
            _buildAccountInfo(),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: _buildSettingsButton()),
                const SizedBox(width: 16),
                Expanded(child: _buildLogoutButton()),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _userProfile?.name ?? '';
    final surname = _userProfile?.surname ?? '';
    final fullName = '$name $surname'.trim();
    final initials = _getInitials(fullName);
    final memberStatus = _userProfile?.active == true ? 'Aktif Üye' : 'Pasif Üye';

    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryColor, width: 3),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: _userProfile?.profileUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.network(
                      _userProfile!.profileUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            initials,
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            fullName.isEmpty ? 'İsimsiz Kullanıcı' : fullName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _userProfile?.active == true
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              memberStatus,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _userProfile?.active == true ? AppTheme.primaryColor : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String fullName) {
    if (fullName.isEmpty) return 'UK';
    
    final nameParts = fullName.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.length == 1 && nameParts[0].isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    
    return 'UK'; // Unidentified User
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

  Widget _buildPersonalInfo() {
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
            icon: Icons.person,
            title: 'Ad Soyad',
            value: '${_userProfile?.name ?? ''} ${_userProfile?.surname ?? ''}'.trim(),
          ),
          const Divider(),
          _buildInfoItem(
            icon: Icons.calendar_today,
            title: 'Doğum Tarihi',
            value: _userProfile?.formattedBirthday ?? 'Belirtilmemiş',
          ),
          const Divider(),
          _buildInfoItem(
            icon: Icons.credit_card,
            title: 'T.C. Kimlik No',
            value: _userProfile?.identityNumber != null 
                ? _maskIdentityNumber(_userProfile!.identityNumber!)
                : 'Belirtilmemiş',
          ),
        ],
      ),
    );
  }

  String _maskIdentityNumber(String identityNumber) {
    if (identityNumber.length < 5) return identityNumber;
    
    final visiblePart = identityNumber.substring(identityNumber.length - 2);
    final maskedPart = '•' * (identityNumber.length - 2);
    
    return '$maskedPart$visiblePart';
  }

  Widget _buildContactInfo() {
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
            icon: Icons.phone,
            title: 'Telefon Doğrulaması',
            value: _userProfile?.phoneVerified == true ? 'Doğrulanmış' : 'Doğrulanmamış',
            valueColor: _userProfile?.phoneVerified == true ? Colors.green : Colors.orange,
          ),
          const Divider(),
          _buildInfoItem(
            icon: Icons.email,
            title: 'E-posta',
            value: _userProfile?.email ?? 'Belirtilmemiş',
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildAccountInfo() {
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
            icon: Icons.verified_user,
            title: 'Üyelik Durumu',
            value: _userProfile?.active == true ? 'Aktif' : 'Pasif',
            valueColor: _userProfile?.active == true ? Colors.green : Colors.red,
          ),
          const Divider(),
          _buildInfoItem(
            icon: Icons.access_time,
            title: 'Üyelik Tarihi',
            value: _userProfile?.formattedCreatedAt ?? 'Belirtilmemiş',
          ),
          const Divider(),
          _buildInfoItem(
            icon: Icons.update,
            title: 'Son Güncelleme',
            value: _userProfile?.formattedUpdatedAt ?? 'Belirtilmemiş',
          ),
          const Divider(),
          _buildInfoItem(
            icon: Icons.security,
            title: 'Şifre',
            value: 'Değiştir',
            isButton: true,
            onTap: () {
              _navigateToChangePassword();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    bool isButton = false,
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
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isButton)
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

  Widget _buildSettingsButton() {
    return Container(
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
        },
        icon: const Icon(Icons.settings),
        label: const Text(
          'Ayarlar',
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

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout),
        label: const Text(
          'Çıkış Yap',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
