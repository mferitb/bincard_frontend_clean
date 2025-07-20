import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'bus_routes_screen.dart';
import 'saved_cards_screen.dart';
import 'qr_code_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';
  bool _isSearching = false;

  // Arama kategorileri
  final List<String> _categories = [
    'Tümü',
    'Kartlar',
    'Ödeme Noktaları',
    'Hatlar',
    'Yerler',
  ];

  // Örnek arama sonuçları
  final Map<String, List<Map<String, dynamic>>> _searchResults = {
    'Kartlar': [
      {
        'id': '1',
        'title': 'Öğrenci Kartı',
        'subtitle': 'Ahmet Yılmaz - 5312****3456',
        'icon': Icons.credit_card,
        'color': AppTheme.primaryColor,
        'route': 'saved_cards',
      },
      {
        'id': '2',
        'title': 'Standart Kart',
        'subtitle': 'Bakiye: ₺257,50',
        'icon': Icons.credit_card,
        'color': AppTheme.secondaryColor,
        'route': 'saved_cards',
      },
    ],
    'Ödeme Noktaları': [
      {
        'id': '1',
        'title': 'Merkez Metro İstasyonu',
        'subtitle': '1.2 km - Şimdi Açık',
        'icon': Icons.storefront,
        'color': AppTheme.successColor,
        'route': 'map',
        'location': {'lat': 41.0082, 'lng': 28.9784},
      },
      {
        'id': '2',
        'title': 'Belediye Binası',
        'subtitle': '2.5 km - Şimdi Açık',
        'icon': Icons.account_balance,
        'color': AppTheme.successColor,
        'route': 'map',
        'location': {'lat': 41.0099, 'lng': 28.9619},
      },
      {
        'id': '3',
        'title': 'Üniversite Kampüsü',
        'subtitle': '4.7 km - Şimdi Açık',
        'icon': Icons.school,
        'color': AppTheme.successColor,
        'route': 'map',
        'location': {'lat': 41.0105, 'lng': 28.9712},
      },
    ],
    'Hatlar': [
      {
        'id': '1',
        'title': '11A - Merkez-Üniversite',
        'subtitle': 'Sefer sıklığı: 15 dk',
        'icon': Icons.directions_bus,
        'color': Colors.orange.shade700,
        'route': 'bus_routes',
        'busNumber': '11A',
      },
      {
        'id': '2',
        'title': '22B - Merkez-Sanayi',
        'subtitle': 'Sefer sıklığı: 20 dk',
        'icon': Icons.directions_bus,
        'color': Colors.orange.shade700,
        'route': 'bus_routes',
        'busNumber': '22B',
      },
      {
        'id': '3',
        'title': '33C - Merkez-Sahil',
        'subtitle': 'Sefer sıklığı: 30 dk',
        'icon': Icons.directions_bus,
        'color': Colors.orange.shade700,
        'route': 'bus_routes',
        'busNumber': '33C',
      },
    ],
    'Yerler': [
      {
        'id': '1',
        'title': 'Merkez Restoran',
        'subtitle': '0.7 km - Şimdi Açık',
        'icon': Icons.restaurant,
        'color': Colors.red.shade700,
        'route': 'map',
        'location': {'lat': 41.0121, 'lng': 28.9760},
        'type': 'restaurant',
      },
      {
        'id': '2',
        'title': 'Kart Yenileme Merkezi',
        'subtitle': '1.9 km - Şimdi Açık',
        'icon': Icons.credit_card_rounded,
        'color': AppTheme.infoColor,
        'route': 'map',
        'location': {'lat': 41.0150, 'lng': 28.9790},
        'type': 'card_renewal',
      },
      {
        'id': '3',
        'title': 'QR Ödeme Noktası - AVM',
        'subtitle': '2.3 km - Şimdi Açık',
        'icon': Icons.qr_code,
        'color': AppTheme.accentColor,
        'route': 'map',
        'location': {'lat': 41.0171, 'lng': 28.9819},
        'type': 'qr_payment',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Arama sonuçlarını filtrele
  List<Map<String, dynamic>> get _filteredResults {
    if (_searchQuery.isEmpty) {
      // Boş arama durumunda kategoriye göre tüm sonuçları göster
      if (_tabController.index == 0) {
        // "Tümü" sekmesi için tüm kategorileri birleştir
        List<Map<String, dynamic>> allResults = [];
        _searchResults.forEach((key, value) {
          allResults.addAll(value);
        });
        return allResults;
      } else {
        // Diğer sekmeler için sadece o kategorideki sonuçları göster
        return _searchResults[_categories[_tabController.index]] ?? [];
      }
    } else {
      // Arama sorgusu varsa, kategoriye göre filtrele
      if (_tabController.index == 0) {
        // "Tümü" sekmesi için tüm kategorilerde ara
        List<Map<String, dynamic>> filteredResults = [];
        _searchResults.forEach((key, value) {
          filteredResults.addAll(
            value.where(
              (item) =>
                  item['title'].toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  item['subtitle'].toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
            ),
          );
        });
        return filteredResults;
      } else {
        // Diğer sekmeler için sadece o kategoride ara
        final categoryResults =
            _searchResults[_categories[_tabController.index]] ?? [];
        return categoryResults
            .where(
              (item) =>
                  item['title'].toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  item['subtitle'].toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
            )
            .toList();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        leading: BackButton(color: Colors.white),
        title: _isSearching 
            ? _buildSearchField() 
            : const Text(
                'Arama',
                style: TextStyle(color: Colors.white),
              ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white,
          tabs: _categories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: Column(
        children: [
          if (!_isSearching) _buildSearchHints(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_categories.length, (index) {
                return _buildSearchResultsList();
              }),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.filter_list),
        onPressed: () {
          _showFilterOptions(context);
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        hintText: 'Kart, ödeme noktası, hat, yer ara...',
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Widget _buildSearchHints() {
    final recentSearches = [
      'Öğrenci Kartı',
      'Merkez Metro',
      '11A',
      'Kart Yenileme',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Son Aramalar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                recentSearches.map((search) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _isSearching = true;
                        _searchQuery = search;
                        _searchController.text = search;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundVariant1,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history,
                            size: 16,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            search,
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsList() {
    if (_filteredResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: AppTheme.textSecondaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'Aramaya başlayın' : 'Sonuç bulunamadı',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Farklı bir arama yapmayı deneyin',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredResults.length,
      itemBuilder: (context, index) {
        final result = _filteredResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () => _navigateToResult(result),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: result['color'].withOpacity(0.2),
              child: Icon(result['icon'], color: result['color']),
            ),
            title: Text(
              result['title'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              result['subtitle'],
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ),
        );
      },
    );
  }

  void _navigateToResult(Map<String, dynamic> result) {
    switch (result['route']) {
      case 'saved_cards':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SavedCardsScreen()),
        );
        break;
      case 'bus_routes':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BusRoutesScreen()),
        );
        break;
      case 'qr_code':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const QRCodeScreen(isScanner: false),
          ),
        );
        break;
      case 'map':
        // Harita sayfasına gitmek için burada map sayfasını çağıracağız
        // (Bu bir sonraki adımda eklenecek)
        _showMapLocationSnackbar(result);
        break;
      default:
        // Varsayılan olarak bir şey yapma
        break;
    }
  }

  void _showMapLocationSnackbar(Map<String, dynamic> result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${result['title']} konumu haritada açılacak'),
        action: SnackBarAction(label: 'Tamam', onPressed: () {}),
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    final selectedCategory = _categories[_tabController.index];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtrele: $selectedCategory',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              if (selectedCategory == 'Kartlar' || selectedCategory == 'Tümü')
                ListTile(
                  leading: Icon(
                    Icons.credit_card,
                    color: AppTheme.primaryColor,
                  ),
                  title: const Text('Bakiyeye Göre Sırala'),
                  onTap: () {
                    Navigator.pop(context);
                    // Sıralama işlemini uygula
                  },
                ),
              if (selectedCategory == 'Ödeme Noktaları' ||
                  selectedCategory == 'Yerler' ||
                  selectedCategory == 'Tümü')
                ListTile(
                  leading: Icon(Icons.near_me, color: AppTheme.infoColor),
                  title: const Text('Yakındakileri Göster'),
                  onTap: () {
                    Navigator.pop(context);
                    // Yakındaki yerleri filtrele
                  },
                ),
              if (selectedCategory == 'Hatlar' || selectedCategory == 'Tümü')
                ListTile(
                  leading: Icon(Icons.access_time, color: AppTheme.accentColor),
                  title: const Text('Aktif Hatları Göster'),
                  onTap: () {
                    Navigator.pop(context);
                    // Aktif hatları filtrele
                  },
                ),
              ListTile(
                leading: Icon(
                  Icons.sort_by_alpha,
                  color: AppTheme.secondaryColor,
                ),
                title: const Text('A-Z Sırala'),
                onTap: () {
                  Navigator.pop(context);
                  // Alfabetik sırala
                },
              ),
              ListTile(
                leading: Icon(Icons.restore, color: AppTheme.errorColor),
                title: const Text('Filtreleri Temizle'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
