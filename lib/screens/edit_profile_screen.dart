import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../services/secure_storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  
  File? _profileImage;
  final _imagePicker = ImagePicker();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;
  bool _photoUpdateSuccess = false;
  String _errorMessage = '';
  String _photoErrorMessage = '';
  
  UserProfile? _userProfile;
  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Kullanıcı profil bilgilerini yükle
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userProfile = await _userService.getUserProfile();
      setState(() {
        _userProfile = userProfile;
        _fillFormWithUserData(userProfile);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Profil bilgileri yüklenemedi: $e';
      });
    }
  }

  // Form alanlarını kullanıcı verileriyle doldur
  void _fillFormWithUserData(UserProfile profile) {
    _nameController.text = profile.name ?? '';
    _surnameController.text = profile.surname ?? '';
    _emailController.text = profile.email ?? '';
  }

  Future<void> _pickImage() async {
    setState(() {
      _isUploading = true;  // Yükleme başlıyor
    });
    
    try {
      // Galeriye erişim izni kontrol et ve iste
      PermissionStatus storagePermission = await Permission.storage.status;
      PermissionStatus photosPermission = await Permission.photos.status;
      
      // Android 13+ için photos izni, daha eski sürümler için storage izni
      bool hasPermission = false;
      
      if (Platform.isAndroid) {
        // Android 13+ (API 33+) için photos izni kullan
        if (await Permission.photos.isGranted) {
          hasPermission = true;
        } else if (await Permission.storage.isGranted) {
          hasPermission = true;
        } else {
          // İzin iste
          Map<Permission, PermissionStatus> permissions = await [
            Permission.photos,
            Permission.storage,
          ].request();
          
          hasPermission = permissions[Permission.photos] == PermissionStatus.granted ||
                         permissions[Permission.storage] == PermissionStatus.granted;
        }
      } else if (Platform.isIOS) {
        // iOS için photos izni
        if (photosPermission.isGranted) {
          hasPermission = true;
        } else {
          photosPermission = await Permission.photos.request();
          hasPermission = photosPermission.isGranted;
        }
      }
      
      if (!hasPermission) {
        setState(() {
          _isUploading = false;
          _photoErrorMessage = 'Galeri erişimi için izin gerekli. Lütfen uygulama ayarlarından izin verin.';
        });
        
        // Kullanıcıyı ayarlara yönlendir
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('İzin Gerekli'),
              content: const Text('Profil fotoğrafı değiştirmek için galeri erişimi gereklidir. Uygulama ayarlarından izin verebilirsiniz.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    openAppSettings();
                  },
                  child: const Text('Ayarlara Git'),
                ),
              ],
            ),
          );
        }
        return;
      }
      
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        
        // Fotoğrafı hemen yükle
        final response = await _userService.updateProfilePhoto(imageFile);
        
        if (response.success) {
          // Fotoğraf güncellemesi başarılıysa, en güncel profil bilgilerini sunucudan al
          try {
            // Get the most up-to-date profile data from the server using the refresh method
            final latestProfile = await _userService.refreshUserProfile();
            
            // Update local state with the latest profile data
            setState(() {
              _userProfile = latestProfile;
              _profileImage = imageFile;
              _photoUpdateSuccess = true;
              _photoErrorMessage = '';
            });
            
            debugPrint('Edit Profile: Fotoğraf güncellendi, local state güncellendi - Ad: ${latestProfile.name}, Soyad: ${latestProfile.surname}');
            debugPrint('Profil fotoğrafı güncellendi, en güncel profil bilgileri alındı ve SecureStorage\'a kaydedildi');
          } catch (e) {
            debugPrint('Profil fotoğrafı güncellendi fakat en güncel profil bilgileri alınamadı: $e');
            // Still update the image locally even if we can't refresh the full profile
            setState(() {
              _profileImage = imageFile;
              _photoUpdateSuccess = true;
              _photoErrorMessage = '';
            });
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profil fotoğrafı başarıyla güncellendi'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          setState(() {
            _photoErrorMessage = 'Fotoğraf yüklenemedi: ${response.message}';
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fotoğraf yüklenirken hata oluştu: ${response.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _photoErrorMessage = 'Fotoğraf seçilirken hata oluştu: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf işlenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;  // Yükleme tamamlandı
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Değişiklik kontrol et
      final currentName = _userProfile?.name ?? '';
      final currentSurname = _userProfile?.surname ?? '';
      final currentEmail = _userProfile?.email ?? '';
      
      final newName = _nameController.text.trim();
      final newSurname = _surnameController.text.trim();
      final newEmail = _emailController.text.trim();
      
      // Hiçbir değişiklik yapılmamışsa uyar
      if (currentName == newName && 
          currentSurname == newSurname && 
          currentEmail == newEmail) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil bilgilerinizde herhangi bir değişiklik yapmadınız.'),
            backgroundColor: Colors.orange,
          ),
        );
        return; // İşlemi sonlandır
      }
      
      setState(() {
        _isSaving = true;
        _errorMessage = '';
      });
      
      try {
        // Güncellenmiş profil verilerini oluştur (sadece name, surname ve email)
        final updatedProfile = UpdateUserRequest(
          name: newName,
          surname: newSurname,
          email: newEmail.isNotEmpty ? newEmail : null,
        );
        
        // Debug: Hangi alanların değiştiğini logla
        final changes = <String>[];
        if (currentName != newName) changes.add('Ad: "$currentName" → "$newName"');
        if (currentSurname != newSurname) changes.add('Soyad: "$currentSurname" → "$newSurname"');
        if (currentEmail != newEmail) changes.add('Email: "$currentEmail" → "$newEmail"');
        debugPrint('Profil değişiklikleri: ${changes.join(', ')}');
        
        // Profil güncelleme işlemini yap - v1/api/user/profile endpoint'ine gönder
        final response = await _userService.updateUserProfile(updatedProfile);
        
        if (mounted) {
          final success = response.success;
          final message = response.message ?? '';
          
          // Backend'den "değişiklik yapılmadı" mesajı geldiyse özel handle et
          if (!success && message.contains('değişiklik yapılmadı')) {
            debugPrint('Backend: Herhangi bir değişiklik yapılmadı');
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profil bilgilerinizde herhangi bir değişiklik yapılmadı.'),
                backgroundColor: Colors.orange,
              ),
            );
            
            setState(() {
              _isSaving = false;
            });
            return; // İşlemi sonlandır
          }
          
          if (success) {
            debugPrint('Profil güncelleme API başarılı');
            
            // Önce local state'i hemen güncelle (optimistic update)
            setState(() {
              if (_userProfile != null) {
                _userProfile = UserProfile(
                  name: newName,
                  surname: newSurname,
                  email: newEmail.isNotEmpty ? newEmail : _userProfile!.email,
                  profileUrl: _userProfile!.profileUrl,
                  active: _userProfile!.active,
                  phoneVerified: _userProfile!.phoneVerified,
                  birthday: _userProfile!.birthday,
                  identityNumber: _userProfile!.identityNumber,
                  userNumber: _userProfile!.userNumber,
                  emailVerified: _userProfile!.emailVerified,
                  walletActivated: _userProfile!.walletActivated,
                  roles: _userProfile!.roles,
                );
                _fillFormWithUserData(_userProfile!);
              }
              _isSaving = false; // Kaydetme işlemi tamamlandı
            });
            
            debugPrint('Edit Profile: Local state güncellendi - Ad: $newName, Soyad: $newSurname');
            
            // Backend'e zaman tanı ve sonra API'den güncel veriyi al
            await Future.delayed(const Duration(milliseconds: 1000));
            
            try {
              // 🔄 Önce SecureStorage'ı temizle
              final secureStorage = SecureStorageService();
              debugPrint('🧹 Edit Profile: SecureStorage temizleniyor...');
              await secureStorage.setUserFirstName('');
              await secureStorage.setUserLastName('');
              
              final latestProfile = await _userService.refreshUserProfile();
              debugPrint('API\'den en güncel profil alındı - Ad: ${latestProfile.name}, Soyad: ${latestProfile.surname}');
              
              // En güncel veriyle state'i tekrar güncelle
              setState(() {
                _userProfile = latestProfile;
                _fillFormWithUserData(latestProfile);
              });
              
              // 🔍 Final kontrol - SecureStorage'daki verileri de kontrol et
              final finalStoredName = await secureStorage.getUserFirstName();
              final finalStoredSurname = await secureStorage.getUserLastName();
              debugPrint('🔍 Edit Profile Final - SecureStorage: $finalStoredName $finalStoredSurname');
              debugPrint('🔍 Edit Profile Final - UI State: ${latestProfile.name} ${latestProfile.surname}');
              
              debugPrint('Final UI state güncellendi - Ad: ${latestProfile.name}, Soyad: ${latestProfile.surname}');
            } catch (e) {
              debugPrint('En güncel profil alma hatası: $e');
              // Hata olsa bile optimistic update geçerli kalacak
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profiliniz başarıyla güncellendi.'),
                backgroundColor: AppTheme.successColor,
              ),
            );
            
            debugPrint('Edit Profile: Navigator.pop çağrılıyor - Final state: ${_userProfile?.name} ${_userProfile?.surname}');
            Navigator.pop(context, true); // Pass true to indicate update was successful
          } else {
            setState(() {
              _errorMessage = 'Profil güncellenirken bir hata oluştu.';
              _isSaving = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Profil güncellenirken bir hata oluştu: $e';
            _isSaving = false;
          });
        }
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
          'Profili Düzenle',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: _isLoading ? null : _loadUserProfile,
            tooltip: 'Profili Yenile',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingIndicator()
            : _errorMessage.isNotEmpty
                ? _buildErrorView()
                : _buildProfileForm(),
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

  Widget _buildProfileForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileImageSection(),
            const SizedBox(height: 32),
            _buildPersonalInfoSection(),
            const SizedBox(height: 32),
            if (_errorMessage.isNotEmpty) _buildErrorMessage(),
            const SizedBox(height: 16),
            _buildSaveButton(),
            const SizedBox(height: 16),
            _buildProfileDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.errorColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _photoUpdateSuccess 
                        ? Colors.green.withOpacity(0.5) 
                        : AppTheme.primaryColor.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _isUploading 
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: _profileImage != null
                          ? Image.file(
                              _profileImage!,
                              fit: BoxFit.cover,
                            )
                          : _userProfile?.profileUrl != null
                              ? Image.network(
                                  _userProfile!.profileUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 60,
                                      color: AppTheme.primaryColor,
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppTheme.primaryColor,
                                ),
                    ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploading ? null : _pickImage,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _isUploading ? Colors.grey : AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ),
              if (_photoUpdateSuccess)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Profil Fotoğrafını Değiştir',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          if (_photoErrorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _photoErrorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.errorColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kişisel Bilgiler',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '* ile işaretlenen alanlar zorunludur',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _nameController,
          label: 'Ad *',
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen adınızı girin';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _surnameController,
          label: 'Soyad *',
          icon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen soyadınızı girin';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'E-posta (İsteğe bağlı)',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Lütfen geçerli bir e-posta adresi girin';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    // We no longer need this section, as email is now in the personal info section
    return const SizedBox.shrink();
  }

  Widget _buildProfileDetails() {
    if (_userProfile == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Hesap Bilgileri',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow('Hesap Durumu', _userProfile!.active == true ? 'Aktif' : 'Pasif'),
        _buildInfoRow('Telefon Doğrulaması', _userProfile!.phoneVerified == true ? 'Doğrulanmış' : 'Doğrulanmamış'),
        if (_userProfile!.emailVerified != null)
          _buildInfoRow('E-posta Doğrulaması', _userProfile!.emailVerified == true ? 'Doğrulanmış' : 'Doğrulanmamış'),
        if (_userProfile!.walletActivated != null)
          _buildInfoRow('Cüzdan Durumu', _userProfile!.walletActivated == true ? 'Aktif' : 'Pasif'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: readOnly ? Colors.grey.shade400 : Colors.grey.shade300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.errorColor,
                width: 1,
              ),
            ),
            prefixIcon: Icon(
              icon,
              color: AppTheme.primaryColor,
            ),
          ),
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Değişiklikleri Kaydet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}