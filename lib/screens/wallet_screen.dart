import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'card_activities_screen.dart';
import 'transfer_screen.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';
import '../services/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'wallet_transfer_detail_screen.dart';
import 'add_balance_screen.dart';
import 'wallet_create_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic>? _walletData;
  String? _walletError;
  bool _isLoading = false;

  List<dynamic> _activities = [];
  bool _isActivitiesLoading = false;
  String? _activitiesError;

  @override
  void initState() {
    super.initState();
    _fetchWallet();
    _fetchActivities();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchWallet() async {
    setState(() {
      _isLoading = true;
      _walletError = null;
    });
    try {
      final api = ApiService();
      final accessToken = await SecureStorageService().getAccessToken();
      final response = await api.get(
        ApiConstants.myWalletEndpoint,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      if (response.data['success'] == false && response.data['message'] != null) {
        setState(() {
          _walletData = null;
          _walletError = response.data['message'];
        });
      } else {
        setState(() {
          _walletData = response.data;
          _walletError = null;
        });
      }
    } catch (e) {
      setState(() {
        _walletData = null;
        _walletError = 'Cüzdan bilgisi alınamadı';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchActivities() async {
    setState(() {
      _isActivitiesLoading = true;
      _activitiesError = null;
    });
    try {
      final api = ApiService();
      final accessToken = await SecureStorageService().getAccessToken();
      final now = DateTime.now();
      final start = '${now.year}-01-01';
      final end = '${now.year}-12-31';
      final response = await api.get(
        ApiConstants.walletActivitiesEndpoint(
          type: null, // Tüm aktiviteler için null, sadece transferler için 'TRANSFER_SENT' veya 'TRANSFER_RECEIVED' yazılabilir
          start: start,
          end: end,
          page: 0,
          size: 50,
        ),
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      if (response.data['success'] == true && response.data['data'] != null) {
        setState(() {
          _activities = response.data['data']['content'] ?? [];
        });
      } else {
        setState(() {
          _activities = [];
          _activitiesError = response.data['message'] ?? 'Aktiviteler alınamadı';
        });
      }
    } catch (e) {
      setState(() {
        _activities = [];
        _activitiesError = 'Aktiviteler alınamadı';
      });
    } finally {
      setState(() {
        _isActivitiesLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
            'Cüzdanım',
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
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
          'Cüzdanım',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddBalanceScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Bakiye Yükle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/transfer');
                    },
                    icon: const Icon(Icons.sync_alt),
                    label: const Text('Transfer Yap'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Cüzdan Aktiviteleri', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 12),
            _buildActivitiesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_walletError != null) {
      return Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(_walletError!, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WalletCreateScreen(),
                    ),
                  );
                },
                child: const Text('Cüzdan Oluştur'),
              ),
            ],
          ),
        ),
      );
    }
    if (_walletData == null) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 8,
      shadowColor: AppTheme.primaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
              AppTheme.accentColor,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toplam Bakiye', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  (_walletData!['balance'] ?? 0).toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 4),
                Text('₺', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Son Güncelleme: ' + _formatDate(_walletData!['lastUpdated']), style: const TextStyle(color: Colors.white, fontSize: 14)),
            if (_walletData!['wiban'] != null) ...[
              const SizedBox(height: 8),
              Text('WIBAN: ' + _walletData!['wiban'], style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesList() {
    if (_isActivitiesLoading && _activities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_activitiesError != null) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_activitiesError!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    if (_activities.isEmpty) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Hiç aktivite bulunamadı.'),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _activities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return Card(
          elevation: 2,
          child: ListTile(
            leading: Icon(
              activity['activityType'] == 'TRANSFER_SENT'
                  ? Icons.call_made
                  : activity['activityType'] == 'TRANSFER_RECEIVED'
                      ? Icons.call_received
                      : Icons.swap_horiz,
              color: activity['activityType'] == 'TRANSFER_SENT'
                  ? Colors.red
                  : activity['activityType'] == 'TRANSFER_RECEIVED'
                      ? Colors.green
                      : AppTheme.primaryColor,
            ),
            title: Text(activity['description'] ?? '-'),
            subtitle: Text(_formatDate(activity['activityDate'])),
            trailing: Text(
              (activity['amount'] ?? 0).toString() + ' ₺',
              style: TextStyle(
                color: (activity['amount'] ?? 0) < 0 ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: (activity['transferId'] != null)
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WalletTransferDetailScreen(transferId: activity['transferId']),
                      ),
                    );
                  }
                : null,
          ),
        );
      },
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr.toString().replaceAll(' ', 'T'));
      final months = [
        'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
      ];
      String month = months[date.month - 1];
      String day = date.day.toString();
      String year = date.year.toString();
      String hour = date.hour.toString().padLeft(2, '0');
      String minute = date.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute';
    } catch (e) {
      return dateStr.toString();
    }
  }
}
