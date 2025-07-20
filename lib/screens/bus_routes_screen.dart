import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'map_screen.dart';
import 'bus_tracking_screen.dart';

class BusRoutesScreen extends StatefulWidget {
  const BusRoutesScreen({super.key});

  @override
  State<BusRoutesScreen> createState() => _BusRoutesScreenState();
}

class _BusRoutesScreenState extends State<BusRoutesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<String> _favoriteRoutes = [];

  // Örnek otobüs seferleri listesi
  final List<Map<String, dynamic>> _routes = [
    {
      'number': '11A',
      'name': 'Merkez - Üniversite',
      'stops': ['Merkez', 'Belediye', 'Adliye', 'Hastane', 'Üniversite'],
      'startTime': '06:00',
      'endTime': '23:00',
      'frequency': '15 dk',
    },
    {
      'number': '22B',
      'name': 'Merkez - Sanayi',
      'stops': ['Merkez', 'AVM', 'Stadyum', 'Sanayi'],
      'startTime': '06:30',
      'endTime': '22:00',
      'frequency': '20 dk',
    },
    {
      'number': '33C',
      'name': 'Merkez - Sahil',
      'stops': ['Merkez', 'Park', 'Müze', 'Sahil'],
      'startTime': '07:00',
      'endTime': '23:30',
      'frequency': '30 dk',
    },
    {
      'number': '44D',
      'name': 'Terminal - Merkez',
      'stops': ['Terminal', 'Çarşı', 'Pazar', 'Merkez'],
      'startTime': '05:30',
      'endTime': '22:30',
      'frequency': '10 dk',
    },
    {
      'number': '55E',
      'name': 'Merkez - Havalimanı',
      'stops': ['Merkez', 'Bulvar', 'Fuar', 'Havalimanı'],
      'startTime': '04:00',
      'endTime': '00:00',
      'frequency': '45 dk',
    },
  ];

  List<Map<String, dynamic>> get _filteredRoutes {
    if (_searchQuery.isEmpty) {
      return _routes;
    }
    return _routes.where((route) {
      return route['number'].toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          route['name'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _toggleFavorite(String routeNumber) {
    setState(() {
      if (_favoriteRoutes.contains(routeNumber)) {
        _favoriteRoutes.remove(routeNumber);
      } else {
        _favoriteRoutes.add(routeNumber);
      }
    });
  }

  @override
  void dispose() {
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
            child:
                _filteredRoutes.isEmpty
                    ? _buildNoResults()
                    : _buildRoutesList(),
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
    return Container(
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
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
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

  Widget _buildRoutesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredRoutes.length,
      itemBuilder: (context, index) {
        final route = _filteredRoutes[index];
        final isFavorite = _favoriteRoutes.contains(route['number']);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            leading: Container(
              width: 48,
              height: 48,
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
            title: Text(
              route['name'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'İlk sefer: ${route['startTime']} - Son sefer: ${route['endTime']}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color:
                        isFavorite
                            ? AppTheme.accentColor
                            : AppTheme.textSecondaryColor,
                  ),
                  onPressed: () => _toggleFavorite(route['number']),
                ),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Duraklar'),
                    const SizedBox(height: 8),
                    _buildStopsList(route['stops']),
                    const SizedBox(height: 16),
                    _buildInfoRow('Sefer Sıklığı', route['frequency']),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.map,
                          label: 'Haritada Gör',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => MapScreen(
                                      locationType: 'bus',
                                      initialLocation: {
                                        'lat': 41.0082,
                                        'lng': 28.9784,
                                      },
                                    ),
                              ),
                            );
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.access_time,
                          label: 'Tüm Saatler',
                          onTap: () {
                            _showTimeTable(context, route);
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.location_on,
                          label: 'Otobüs Takip',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => BusTrackingScreen(
                                      busNumber: route['number'],
                                    ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
                    if (_favoriteRoutes.isNotEmpty) {
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
                title: const Text('Hat Numarasına Göre Sırala'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    final sortedRoutes = List<Map<String, dynamic>>.from(
                      _routes,
                    );
                    sortedRoutes.sort(
                      (a, b) => a['number'].compareTo(b['number']),
                    );
                    _routes.clear();
                    _routes.addAll(sortedRoutes);
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
