import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _locationTracking = true;
  bool _shareActivityData = true;
  bool _personalisedAds = false;
  bool _dataCollection = true;
  bool _cookiesEnabled = true;

  static const String _locationTrackingKey = 'location_tracking_enabled';

  @override
  void initState() {
    super.initState();
    _loadLocationTracking();
  }

  Future<void> _loadLocationTracking() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _locationTracking = prefs.getBool(_locationTrackingKey) ?? true;
    });
  }

  Future<void> _saveLocationTracking(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationTrackingKey, value);
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
          'Gizlilik Ayarları',
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
              _buildInfoCard(),
              const SizedBox(height: 24),
              _buildSectionTitle('Konum ve Aktivite'),
              _buildSettingsCard([
                _buildSwitchItem(
                  icon: Icons.location_on,
                  title: 'Konum Takibi',
                  subtitle: 'Uygulamanın konumunuzu takip etmesine izin verin',
                  value: _locationTracking,
                  onChanged: (value) {
                    setState(() {
                      _locationTracking = value;
                    });
                    _saveLocationTracking(value);
                  },
                ),
                const Divider(),
                _buildSwitchItem(
                  icon: Icons.directions_bus,
                  title: 'Seyahat Verilerini Paylaş',
                  subtitle: 'Seyahat verilerinizi hizmet iyileştirme için paylaşın',
                  value: _shareActivityData,
                  onChanged: (value) {
                    setState(() {
                      _shareActivityData = value;
                    });
                  },
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('Veri ve Reklamlar'),
              _buildSettingsCard([
                _buildSwitchItem(
                  icon: Icons.ads_click,
                  title: 'Kişiselleştirilmiş Reklamlar',
                  subtitle: 'İlgi alanlarınıza göre reklamlar gösterin',
                  value: _personalisedAds,
                  onChanged: (value) {
                    setState(() {
                      _personalisedAds = value;
                    });
                  },
                ),
                const Divider(),
                _buildSwitchItem(
                  icon: Icons.data_usage,
                  title: 'Veri Toplama',
                  subtitle: 'Uygulama kullanım verilerinizi toplamaya izin verin',
                  value: _dataCollection,
                  onChanged: (value) {
                    setState(() {
                      _dataCollection = value;
                    });
                  },
                ),
                const Divider(),
                _buildSwitchItem(
                  icon: Icons.cookie,
                  title: 'Çerezler',
                  subtitle: 'Çerezleri etkinleştirin veya devre dışı bırakın',
                  value: _cookiesEnabled,
                  onChanged: (value) {
                    setState(() {
                      _cookiesEnabled = value;
                    });
                  },
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('Hesap Gizliliği'),
              _buildSettingsCard([
                _buildActionItem(
                  icon: Icons.delete,
                  title: 'Verileri Sil',
                  subtitle: 'Tüm kişisel verilerinizi silmek için talep gönderin',
                  onTap: () {
                    _showDeleteDataDialog();
                  },
                ),
                const Divider(),
                _buildActionItem(
                  icon: Icons.download,
                  title: 'Verilerimi İndir',
                  subtitle: 'Kişisel verilerinizin bir kopyasını indirin',
                  onTap: () {
                    _showDownloadDataDialog();
                  },
                ),
              ]),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.infoColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.privacy_tip,
            color: AppTheme.infoColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Gizlilik ayarlarınız, kişisel verilerinizin nasıl kullanıldığını ve korunduğunu kontrol etmenizi sağlar.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
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

  Widget _buildSettingsCard(List<Widget> children) {
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
        children: children,
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gizlilik ayarlarınız kaydedildi.'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Ayarları Kaydet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verileri Silme Talebi'),
        content: const Text(
          'Tüm kişisel verilerinizi silmek için bir talep göndermek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'İptal',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Veri silme talebiniz alındı.'),
                  backgroundColor: AppTheme.infoColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Talep Gönder'),
          ),
        ],
      ),
    );
  }

  void _showDownloadDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verileri İndirme'),
        content: const Text(
          'Kişisel verilerinizin bir kopyasını indirmek istediğinizden emin misiniz? Verileriniz e-posta adresinize gönderilecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'İptal',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Veri indirme talebiniz alındı. Verileriniz e-posta adresinize gönderilecektir.'),
                  backgroundColor: AppTheme.infoColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('İndir'),
          ),
        ],
      ),
    );
  }
} 