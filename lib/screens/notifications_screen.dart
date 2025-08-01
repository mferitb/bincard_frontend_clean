import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/notification_service.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  List<Map<String, dynamic>> _allNotifications = [];
  List<Map<String, dynamic>> _displayedNotifications = [];

  // Bildirim türleri
  final Map<String, IconData> _notificationIcons = {
    'info': Icons.info_outline,
    'success': Icons.check_circle_outline,
    'warning': Icons.warning_amber_outlined,
    'error': Icons.error_outline,
    'system': Icons.settings,
    'announcement': Icons.campaign_outlined,
    'campaign': Icons.campaign,
    'promotion': Icons.local_offer_outlined,
    'alert': Icons.notification_important_outlined,
    'event': Icons.event,
  };

  final Map<String, Color> _notificationColors = {
    'info': Colors.blue,
    'success': Colors.teal,
    'warning': Colors.orange,
    'error': Colors.red,
    'system': Colors.grey,
    'announcement': Colors.indigo,
    'campaign': Colors.purple,
    'promotion': Colors.pink,
    'alert': Colors.deepOrange,
    'event': Colors.green,
  };

  final Map<String, String> _tabTitles = {
    'all': 'Tümü',
    'success': 'Başarılar',
    'info': 'Bilgilendirme',
    'warning': 'Uyarılar',
    'error': 'Hatalar',
    'system': 'Sistem',
    'announcement': 'Duyurular',
    'campaign': 'Kampanyalar',
    'promotion': 'Tanıtımlar',
    'alert': 'Acil',
    'event': 'Etkinlikler',
  };

  // TabBar'da gösterilecek sekmeler (örnek: Tümü, Başarılar, Uyarılar, Duyurular)
  final List<String> _tabs = [
    'all', 'success', 'info', 'warning', 'error', 'announcement', 'campaign', 'promotion', 'alert', 'event'
  ];

  String _currentTab = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchNotifications();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _currentTab = _tabs[_tabController.index];
        _fetchNotifications();
      });
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMoreData();
      }
    });

    timeago.setLocaleMessages('tr', timeago.TrMessages());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Okunmuş bildirimleri SharedPreferences'a kaydet
  Future<void> _saveReadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotificationIds = _allNotifications
          .where((notification) => notification['isRead'] == true)
          .map((notification) => notification['id'].toString())
          .toList();
      await prefs.setStringList('read_notifications', readNotificationIds);
      debugPrint('Okunmuş bildirimler kaydedildi: $readNotificationIds');
    } catch (e) {
      debugPrint('Okunmuş bildirimleri kaydetme hatası: $e');
    }
  }

  // Okunmuş bildirimleri SharedPreferences'tan yükle
  Future<void> _loadReadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotificationIds = prefs.getStringList('read_notifications') ?? [];
      debugPrint('Yüklenen okunmuş bildirimler: $readNotificationIds');
      
      // Bildirimlerdeki okunmuş durumunu güncelle
      for (var notification in _allNotifications) {
        final notificationId = notification['id']?.toString();
        if (notificationId != null && readNotificationIds.contains(notificationId)) {
          notification['isRead'] = true;
        }
      }
    } catch (e) {
      debugPrint('Okunmuş bildirimleri yükleme hatası: $e');
    }
  }

  Future<void> _fetchNotifications({bool append = false}) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final service = NotificationService();
      String type = _currentTab == 'all' ? '' : _currentTab.toUpperCase();
      final response = await service.getNotifications(type: type, page: _currentPage, size: _itemsPerPage);
      final data = response.data;
      debugPrint('API response: ' + data.toString());
      final List content = data['content'] ?? [];
      final List<Map<String, dynamic>> notifications = content.map((e) {
        final map = Map<String, dynamic>.from(e);
        // type: enumdan stringe çevir, küçük harfe
        map['type'] = (map['type'] ?? '').toString().toLowerCase();
        map['isRead'] = map['read'] ?? false;
        map['date'] = map['sentAt'] != null ? DateTime.tryParse(map['sentAt']) : DateTime.now();
        return map;
      }).toList();
      debugPrint('Processed notifications: ' + notifications.toString());
      
      setState(() {
        if (append) {
          _allNotifications.addAll(notifications);
        } else {
          _allNotifications = notifications;
        }
      });
      
      // Okunmuş bildirimleri yükle
      await _loadReadNotifications();
      
      setState(() {
        _displayedNotifications = _currentTab == 'all'
          ? _allNotifications
          : _allNotifications.where((n) => n['type'] == _currentTab).toList();
        debugPrint('Displayed notifications: ' + _displayedNotifications.toString());
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Notification fetch error: ' + e.toString());
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadMoreData() {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _currentPage++;
    });
    _fetchNotifications(append: true);
  }

  void _markAllAsRead() {
    // Yerel olarak tüm bildirimleri okundu olarak işaretle
    setState(() {
      for (var notification in _allNotifications) {
        notification['isRead'] = true;
      }
    });
    
    // Değişiklikleri SharedPreferences'a kaydet
    _saveReadNotifications();
    
    // Başarı mesajı göster
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Tüm bildirimler okundu olarak işaretlendi'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _markNotificationAsRead(Map<String, dynamic> notification) {
    // Yerel olarak bildirimi okundu olarak işaretle
    setState(() {
      notification['isRead'] = true;
    });
    
    // Değişiklikleri SharedPreferences'a kaydet
    _saveReadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _allNotifications.where((n) => !n['isRead']).length;

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
          'Bildirimler',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                onPressed: _markAllAsRead,
                icon: Icon(
                  Icons.done_all,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                tooltip: 'Tümünü okundu olarak işaretle',
              ),
            ),
        ],
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          isScrollable: true,
          tabs: _tabs.map((tab) {
            // Her sekme için okunmamış bildirim sayısını hesapla
            int tabUnreadCount = 0;
            if (tab == 'all') {
              tabUnreadCount = _allNotifications.where((n) => !n['isRead']).length;
            } else {
              tabUnreadCount = _allNotifications.where((n) => n['type'] == tab && !n['isRead']).length;
            }
            return _buildTabWithBadge(_tabTitles[tab] ?? tab, tabUnreadCount);
          }).toList(),
        ),
      ),
      body:
          _displayedNotifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(),
    );
  }

  Widget _buildTabWithBadge(String title, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _displayedNotifications.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _displayedNotifications.length) {
          return _buildLoadingIndicator();
        }

        final notification = _displayedNotifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final type = notification['type'];
    final color = _notificationColors[type] ?? Colors.grey;
    final icon = _notificationIcons[type] ?? Icons.notifications_none;
    final isRead = notification['isRead'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          // Bildirimi okundu olarak işaretle
          _markNotificationAsRead(notification);

          // Bildirim detaylarını göster
          _showNotificationDetails(notification);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isRead ? Colors.white : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    isRead
                        ? Colors.black.withOpacity(0.05)
                        : color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isRead ? Colors.transparent : color.withOpacity(0.3),
              width: isRead ? 0 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'],
                              style: TextStyle(
                                fontWeight:
                                    isRead ? FontWeight.w600 : FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['message'],
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 14,
                          fontWeight:
                              isRead ? FontWeight.normal : FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeago.format(notification['date'], locale: 'tr'),
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor.withOpacity(0.7),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationDetails(Map<String, dynamic> notification) async {
    final service = NotificationService();
    try {
      final response = await service.getNotificationDetail(notification['id']);
      final detail = response.data;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(detail['title'] ?? ''),
          content: Text(detail['message'] ?? ''),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
            TextButton(
              onPressed: () async {
                await service.deleteNotification(notification['id']);
                Navigator.pop(context);
                _fetchNotifications();
              },
              child: const Text('Sil'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Hata durumunda basit bir dialog göster
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hata'),
          content: Text('Bildirim detayı alınamadı.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppTheme.primaryColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Bildirim Bulunamadı',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Bu kategoride henüz bildirim yok. Yeni bildirimler geldiğinde burada görüntülenecektir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
