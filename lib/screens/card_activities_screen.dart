import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CardActivitiesScreen extends StatefulWidget {
  final String cardNumber;
  final String cardName;
  final List<Color> cardColor;

  const CardActivitiesScreen({
    super.key,
    required this.cardNumber,
    required this.cardName,
    required this.cardColor,
  });

  @override
  State<CardActivitiesScreen> createState() => _CardActivitiesScreenState();
}

class _CardActivitiesScreenState extends State<CardActivitiesScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // Demo veri - gerçek uygulamada API'den gelecek
  final List<Map<String, dynamic>> _allActivities = [];
  List<Map<String, dynamic>> _displayedActivities = [];
  String _selectedFilter = 'Tümü';
  final List<String> _filterOptions = [
    'Tümü',
    'Ödeme',
    'Yükleme',
    'Transfer',
    'Geçiş',
  ];
  final Map<String, IconData> _activityIcons = {
    'Ödeme': FontAwesomeIcons.moneyBill,
    'Yükleme': Icons.add_circle_outline,
    'Transfer': Icons.sync_alt,
    'Geçiş': FontAwesomeIcons.bus,
  };

  final Map<String, Color> _activityColors = {
    'Ödeme': Colors.red,
    'Yükleme': Colors.green,
    'Transfer': Colors.blue,
    'Geçiş': Colors.orange,
  };

  @override
  void initState() {
    super.initState();
    _generateDemoData();
    _loadInitialData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMoreData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _generateDemoData() {
    // Demo veriler oluştur - gerçek uygulamada silinecek
    final List<String> locations = [
      'Kadıköy-Kartal Metro',
      'Üsküdar-Çekmeköy Metro',
      'Metrobüs',
      'Marmaray',
      'Şehir Hatları Vapur',
      'E-5 Otobüs',
      'Havaalanı Otobüsü',
      'Kadıköy İskele',
      'Taksim Metro',
      'Mecidiyeköy Metrobüs',
    ];

    final List<String> activityTypes = [
      'Ödeme',
      'Yükleme',
      'Transfer',
      'Geçiş',
    ];

    // Son 3 ay için rastgele veriler oluştur
    final now = DateTime.now();
    for (int i = 0; i < 100; i++) {
      final daysAgo = i ~/ 2; // Her iki aktiviteyi bir gün önceye ayarla
      final activityDate = now.subtract(Duration(days: daysAgo));

      final activityType = activityTypes[i % activityTypes.length];
      final isIncome = activityType == 'Yükleme' || activityType == 'Transfer';

      double amount;
      String description;

      switch (activityType) {
        case 'Ödeme':
          amount = 7.5 + (i % 5) * 2.5;
          description = 'Market Alışverişi';
          break;
        case 'Yükleme':
          amount = 50.0 + (i % 5) * 50.0;
          description = 'Bakiye Yükleme';
          break;
        case 'Transfer':
          amount = 25.0 + (i % 3) * 25.0;
          description = 'Karttan Karta Transfer';
          break;
        case 'Geçiş':
          amount = 7.5;
          description = locations[i % locations.length];
          break;
        default:
          amount = 10.0;
          description = 'Diğer İşlem';
      }

      // Saati rastgele ayarla
      final hour = 8 + (i % 14); // 8:00 - 22:00 arası
      final minute = (i * 7) % 60;

      _allActivities.add({
        'id': i,
        'date': activityDate,
        'formattedDate':
            '${activityDate.day}.${activityDate.month}.${activityDate.year}',
        'time':
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        'type': activityType,
        'description': description,
        'amount': amount,
        'isIncome': isIncome,
        'location':
            activityType == 'Geçiş' ? locations[i % locations.length] : null,
      });
    }

    // Tarihe göre sırala (en yeni en üstte)
    _allActivities.sort((a, b) => b['date'].compareTo(a['date']));
  }

  void _loadInitialData() {
    setState(() {
      _currentPage = 1;
      _applyFilter();
    });
  }

  void _loadMoreData() {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // API çağrısını simüle et
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _currentPage++;
          _applyFilter();
          _isLoading = false;
        });
      }
    });
  }

  void _applyFilter() {
    final filteredList =
        _selectedFilter == 'Tümü'
            ? _allActivities
            : _allActivities
                .where((activity) => activity['type'] == _selectedFilter)
                .toList();

    final endIndex = _currentPage * _itemsPerPage;
    final startIndex = endIndex - _itemsPerPage;

    if (endIndex <= filteredList.length) {
      _displayedActivities = filteredList.sublist(0, endIndex);
    } else {
      _displayedActivities = filteredList;
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
          'Kart Aktiviteleri',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardInfo(),
          const SizedBox(height: 16),
          _buildFilterBar(),
          const SizedBox(height: 16),
          Expanded(
            child:
                _displayedActivities.isEmpty
                    ? _buildEmptyState()
                    : _buildActivityList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCardInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.cardColor,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.cardColor.first.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              FontAwesomeIcons.creditCard,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.cardName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.cardNumber,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = filter == _selectedFilter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
                _loadInitialData();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    color:
                        isSelected ? Colors.white : AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityList() {
    // Aktiviteleri tarihe göre grupla
    final Map<String, List<Map<String, dynamic>>> groupedActivities = {};
    for (final activity in _displayedActivities) {
      final date = activity['formattedDate'];
      if (!groupedActivities.containsKey(date)) {
        groupedActivities[date] = [];
      }
      groupedActivities[date]!.add(activity);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: groupedActivities.keys.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= groupedActivities.keys.length) {
          return _buildLoadingIndicator();
        }

        final date = groupedActivities.keys.elementAt(index);
        final activitiesForDate = groupedActivities[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                date,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            ...activitiesForDate
                .map((activity) => _buildActivityItem(activity))
                ,
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final type = activity['type'];
    final isIncome = activity['isIncome'];
    final color = _activityColors[type] ?? Colors.grey;
    final icon = _activityIcons[type] ?? Icons.history;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
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
                Text(
                  activity['description'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['time'],
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                if (activity['location'] != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          activity['location'],
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Text(
            isIncome
                ? '+${activity['amount'].toStringAsFixed(2)} ₺'
                : '-${activity['amount'].toStringAsFixed(2)} ₺',
            style: TextStyle(
              color: isIncome ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
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
              FontAwesomeIcons.listUl,
              size: 48,
              color: AppTheme.primaryColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aktivite Bulunamadı',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Bu kart için henüz aktivite kaydı bulunmuyor veya seçilen filtre için sonuç yok.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
