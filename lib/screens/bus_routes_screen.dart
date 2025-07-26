import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'map_screen.dart';
import 'bus_tracking_screen.dart';
import '../services/station_service.dart';
import '../models/station_model.dart';

class BusRoutesScreen extends StatefulWidget {
  const BusRoutesScreen({super.key});

  @override
  State<BusRoutesScreen> createState() => _BusRoutesScreenState();
}

class _BusRoutesScreenState extends State<BusRoutesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<int> _favoriteStationIds = [];

  List<StationModel> _stations = [];
  bool _isLoading = true;
  bool _hasError = false;

  // --- Eklenenler: Anahtar kelime önerileri için ---
  List<String> _keywordSuggestions = [];
  bool _isKeywordLoading = false;
  
  @override
  void initState() {
    super.initState();
    _fetchNearbyStations();
    _fetchFavoriteStations();
    // --- Arama kutusu değişimini dinle ---
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() async {
    final value = _searchController.text;
    setState(() {
      _searchQuery = value;
    });
    if (value.isNotEmpty) {
      setState(() {
        _isKeywordLoading = true;
      });
      final suggestions = await StationService().getStationKeywords(query: value);
      setState(() {
        _keywordSuggestions = suggestions.take(3).toList();
        _isKeywordLoading = false;
      });
    } else {
      setState(() {
        _keywordSuggestions = [];
      });
    }
  }

  Future<void> _fetchNearbyStations() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      double latitude = position.latitude;
      double longitude = position.longitude;
      final stations = await StationService().getNearbyStations(latitude: latitude, longitude: longitude);
      print('API yanıtı ile gelen duraklar:');
      for (var s in stations) {
        print('Durak: ${s.id}, ${s.name}, (${s.latitude}, ${s.longitude})');
      }
      setState(() {
        _stations = stations;
        _isLoading = false;
      });
    } catch (e) {
      print('Duraklar çekilirken hata oluştu: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchFavoriteStations() async {
    try {
      final favorites = await StationService().getFavoriteStations();
      setState(() {
        _favoriteStationIds = favorites.map((e) => e.id).toList();
      });
    } catch (e) {
      print('Favori duraklar alınamadı: $e');
    }
  }

  Future<void> _toggleFavorite(int stationId) async {
    if (_favoriteStationIds.contains(stationId)) {
      final success = await StationService().removeFavoriteStation(stationId);
      if (success) {
        setState(() {
          _favoriteStationIds.remove(stationId);
        });
      }
    } else {
      final success = await StationService().addFavoriteStation(stationId);
      if (success) {
        setState(() {
          _favoriteStationIds.add(stationId);
        });
      }
    }
  }

  List<StationModel> get _filteredStations {
    if (_searchQuery.isEmpty) {
      return _stations;
    }
    return _stations.where((station) {
      return station.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Otobüs Seferleri', style: TextStyle(color: Colors.white)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.map, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MapScreen(locationType: 'bus'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _hasError
                    ? Center(child: Text('Bir hata oluştu'))
                    : _filteredStations.isEmpty
                        ? _buildNoStops()
                        : _buildStationsList(),
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

  Widget _buildSearchBar() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.primaryColor,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Hat numarası veya güzergah ara...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              // onChanged kaldırıldı, dinleyici ile yönetiliyor
            ),
          ),
        ),
        // --- Anahtar kelime önerileri kutusu ---
        if (_searchController.text.isNotEmpty)
          Container(
            color: Colors.white,
            child: _isKeywordLoading
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: LinearProgressIndicator(),
                  )
                : Column(
                    children: _keywordSuggestions.map((suggestion) => ListTile(
                          leading: const Icon(Icons.search),
                          title: Text(suggestion),
                          onTap: () {
                            _searchController.text = suggestion;
                            _searchController.selection = TextSelection.fromPosition(
                              TextPosition(offset: suggestion.length),
                            );
                            // İstersen burada arama da tetiklenebilir:
                            // _onSearchChanged();
                          },
                        )).toList(),
                  ),
          ),
      ],
    );
  }

  Widget _buildNoResults() {
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
            'Sonuç bulunamadı',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

  }

  Widget _buildNoStops() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus,
            size: 80,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Yakında durak yok',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationsList() {
    print('Ekrana basılan duraklar:');
    for (var s in _filteredStations) {
      print('Durak: ${s.id}, ${s.name}, (${s.latitude}, ${s.longitude})');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStations.length,
      itemBuilder: (context, index) {
        final station = _filteredStations[index];
        final isFavorite = _favoriteStationIds.contains(station.id);
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MapScreen(
                  locationType: 'bus',
                  initialLocation: {
                    'lat': station.latitude,
                    'lng': station.longitude,
                  },
                ),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        station.name.substring(0, 2),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${station.city}, ${station.district}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite ? AppTheme.accentColor : AppTheme.textSecondaryColor,
                    ),
                    onPressed: () => _toggleFavorite(station.id),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }

  Widget _buildStopsList(List<String> stops) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundVariant1,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children:
            stops.map((stop) {
              bool isLast = stop == stops.last;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color:
                                  isLast
                                      ? AppTheme.successColor
                                      : AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 30,
                              color: AppTheme.primaryColor.withOpacity(0.5),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        stop,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isLast
                                  ? AppTheme.successColor
                                  : AppTheme.textPrimaryColor,
                          fontWeight:
                              isLast ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
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
                'Filtrele',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.star, color: AppTheme.accentColor),
                title: const Text('Favoriler'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                    if (_favoriteStationIds.isNotEmpty) {
                      _searchQuery = '_favorites_';
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Henüz favori hat eklenmemiş'),
                        ),
                      );
                    }
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.access_time, color: AppTheme.primaryColor),
                title: const Text('Şu Anda Çalışan Hatlar'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _searchQuery = '_active_';
                    _searchController.clear();
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.swap_vert, color: AppTheme.infoColor),
                title: const Text('İsim (Hat) Numarasına Göre Sırala'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _stations.sort((a, b) => a.name.compareTo(b.name));
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.map, color: AppTheme.secondaryColor),
                title: const Text('Haritada Göster'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapScreen(locationType: 'bus'),
                    ),
                  );
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

  void _showTimeTable(BuildContext context, Map<String, dynamic> route) {
    final List<String> morningHours = [
      '06:00',
      '06:15',
      '06:30',
      '06:45',
      '07:00',
      '07:15',
      '07:30',
      '07:45',
      '08:00',
      '08:15',
      '08:30',
      '08:45',
      '09:00',
      '09:30',
      '10:00',
      '10:30',
      '11:00',
      '11:30',
    ];

    final List<String> afternoonHours = [
      '12:00',
      '12:30',
      '13:00',
      '13:30',
      '14:00',
      '14:30',
      '15:00',
      '15:30',
      '16:00',
      '16:15',
      '16:30',
      '16:45',
      '17:00',
      '17:15',
      '17:30',
      '17:45',
    ];

    final List<String> eveningHours = [
      '18:00',
      '18:15',
      '18:30',
      '18:45',
      '19:00',
      '19:30',
      '20:00',
      '20:30',
      '21:00',
      '21:30',
      '22:00',
      '22:30',
      '23:00',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        route['number'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Sefer Sıklığı: ${route["frequency"]}',
                          style: TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Kalkış Saatleri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimeSection('Sabah', morningHours),
                      const SizedBox(height: 16),
                      _buildTimeSection('Öğlen & İkindi', afternoonHours),
                      const SizedBox(height: 16),
                      _buildTimeSection('Akşam & Gece', eveningHours),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Kapat'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeSection(String title, List<String> hours) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              hours.map((hour) {
                final isNow = _isCurrentTime(hour);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isNow
                            ? AppTheme.primaryColor
                            : AppTheme.backgroundVariant1,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isNow
                              ? AppTheme.primaryColor
                              : AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    hour,
                    style: TextStyle(
                      fontSize: 14,
                      color: isNow ? Colors.white : AppTheme.textSecondaryColor,
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  bool _isCurrentTime(String time) {
    final now = TimeOfDay.now();
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    return now.hour == hour &&
        (now.minute >= minute && now.minute < minute + 15);
  }
}
