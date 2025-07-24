import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/api_constants.dart';
import '../services/station_service.dart';
import '../models/station_model.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  final Map<String, dynamic>? initialLocation;
  final String? locationType;

  const MapScreen({super.key, this.initialLocation, this.locationType});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _selectedFilter = 'Tümü';
  bool _showFilterPanel = false;

  // Filtre seçenekleri
  final List<Map<String, dynamic>> _filterOptions = [
    {
      'id': 'all',
      'name': 'Tümü',
      'icon': Icons.layers,
      'color': AppTheme.primaryColor,
    },
    {
      'id': 'bus',
      'name': 'Otobüsler',
      'icon': Icons.directions_bus,
      'color': Colors.orange.shade700,
    },
    {
      'id': 'payment',
      'name': 'Ödeme Noktaları',
      'icon': Icons.payments,
      'color': AppTheme.successColor,
    },
    {
      'id': 'restaurant',
      'name': 'Restoranlar',
      'icon': Icons.restaurant,
      'color': Colors.red.shade700,
    },
    {
      'id': 'card_renewal',
      'name': 'Kart Yenileme',
      'icon': Icons.credit_card_rounded,
      'color': AppTheme.infoColor,
    },
    {
      'id': 'qr_payment',
      'name': 'QR Ödeme',
      'icon': Icons.qr_code,
      'color': AppTheme.accentColor,
    },
  ];

  // Örnek harita noktaları
  final List<Map<String, dynamic>> _mapPoints = [
    {
      'id': '1',
      'name': 'Merkez Metro İstasyonu',
      'type': 'payment',
      'icon': Icons.storefront,
      'color': AppTheme.successColor,
      'location': {'lat': 41.0082, 'lng': 28.9784},
      'isOpen': true,
      'distance': '1.2 km',
    },
    {
      'id': '2',
      'name': 'Belediye Binası',
      'type': 'payment',
      'icon': Icons.account_balance,
      'color': AppTheme.successColor,
      'location': {'lat': 41.0099, 'lng': 28.9619},
      'isOpen': true,
      'distance': '2.5 km',
    },
    {
      'id': '3',
      'name': 'Üniversite Kampüsü',
      'type': 'payment',
      'icon': Icons.school,
      'color': AppTheme.successColor,
      'location': {'lat': 41.0105, 'lng': 28.9712},
      'isOpen': true,
      'distance': '4.7 km',
    },
    {
      'id': '4',
      'name': 'Merkez Restoran',
      'type': 'restaurant',
      'icon': Icons.restaurant,
      'color': Colors.red.shade700,
      'location': {'lat': 41.0121, 'lng': 28.9760},
      'isOpen': true,
      'distance': '0.7 km',
    },
    {
      'id': '5',
      'name': 'Kart Yenileme Merkezi',
      'type': 'card_renewal',
      'icon': Icons.credit_card_rounded,
      'color': AppTheme.infoColor,
      'location': {'lat': 41.0150, 'lng': 28.9790},
      'isOpen': true,
      'distance': '1.9 km',
    },
    {
      'id': '6',
      'name': 'QR Ödeme Noktası - AVM',
      'type': 'qr_payment',
      'icon': Icons.qr_code,
      'color': AppTheme.accentColor,
      'location': {'lat': 41.0171, 'lng': 28.9819},
      'isOpen': true,
      'distance': '2.3 km',
    },
    {
      'id': '7',
      'name': '11A - Belediye Durağı',
      'type': 'bus',
      'icon': Icons.directions_bus,
      'color': Colors.orange.shade700,
      'location': {'lat': 41.0090, 'lng': 28.9615},
      'isOpen': true,
      'distance': '2.6 km',
      'busNumber': '11A',
    },
    {
      'id': '8',
      'name': '22B - AVM Durağı',
      'type': 'bus',
      'icon': Icons.directions_bus,
      'color': Colors.orange.shade700,
      'location': {'lat': 41.0095, 'lng': 28.9750},
      'isOpen': true,
      'distance': '1.8 km',
      'busNumber': '22B',
    },
  ];

  List<Map<String, dynamic>> get _filteredPoints {
    if (_selectedFilter == 'Tümü') {
      return _mapPoints;
    } else {
      final filterId =
          _filterOptions.firstWhere(
            (filter) => filter['name'] == _selectedFilter,
            orElse: () => _filterOptions.first,
          )['id'];

      return _mapPoints.where((point) => point['type'] == filterId).toList();
    }
  }

  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  bool _isLoading = false;
  String? _error;
  List<StationModel> _stations = [];

  @override
  void initState() {
    super.initState();
    if (widget.locationType == 'bus') {
      _fetchNearbyStations();
    }
    // Eğer belirli bir konum tipi ile açıldıysa, o filtreyi seç
    if (widget.locationType != null) {
      final matchingFilter = _filterOptions.firstWhere(
        (filter) => filter['id'] == widget.locationType,
        orElse: () => _filterOptions.first,
      );
      _selectedFilter = matchingFilter['name'];
    }
  }

  Future<void> _fetchNearbyStations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _currentLatLng = LatLng(pos.latitude, pos.longitude);
      final stations = await StationService().getNearbyStations(latitude: pos.latitude, longitude: pos.longitude);
      setState(() {
        _stations = stations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Duraklar yüklenemedi: $e';
        _isLoading = false;
      });
    }
  }

  LatLng get _initialLatLng {
    if (widget.initialLocation != null) {
      return LatLng(
        widget.initialLocation!['lat'] ?? 41.0082,
        widget.initialLocation!['lng'] ?? 28.9784,
      );
    }
    if (_currentLatLng != null) {
      return _currentLatLng!;
    }
    return const LatLng(41.0082, 28.9784);
  }

  Set<Marker> get _mapMarkers {
    if (widget.locationType == 'bus' && _stations.isNotEmpty) {
      return _stations.map((station) {
        return Marker(
          markerId: MarkerId(station.id.toString()),
          position: LatLng(station.latitude, station.longitude),
          infoWindow: InfoWindow(title: station.name),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        );
      }).toSet();
    }
    // ... eski örnek markerlar (isteğe bağlı, bus değilse)
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Harita', style: TextStyle(color: Colors.white)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: () {
              // Konumu merkeze al
              _showSnackbar('Konum merkezleniyor...');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Gerçek uygulamada burada bir harita widget'ı olacak
          _buildMapPlaceholder(),

          // Filtre paneli
          if (_showFilterPanel) _buildFilterPanel(),

          // Alt bilgi paneli
          Positioned(bottom: 0, left: 0, right: 0, child: _buildInfoPanel()),

          // Filtre butonu
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'filterButton',
              mini: true,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.filter_list),
              onPressed: () {
                setState(() {
                  _showFilterPanel = !_showFilterPanel;
                });
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.directions),
        onPressed: () {
          // Yol tarifi al
          _showSnackbar('Yol tarifi alınıyor...');
        },
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _initialLatLng,
        zoom: 13,
      ),
      markers: _mapMarkers,
      onMapCreated: (controller) {
        _mapController = controller;
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }

  Widget _buildFilterPanel() {
    return Positioned(
      top: 70,
      right: 16,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 180,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                _filterOptions.map((filter) {
                  final isSelected = filter['name'] == _selectedFilter;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      filter['icon'],
                      color:
                          isSelected ? AppTheme.primaryColor : filter['color'],
                    ),
                    title: Text(
                      filter['name'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color:
                            isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.textPrimaryColor,
                      ),
                    ),
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter['name'];
                        _showFilterPanel = false;
                      });
                    },
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Yakındaki Noktalar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: Icon(Icons.sort, size: 16, color: AppTheme.primaryColor),
                label: Text(
                  'Sırala',
                  style: TextStyle(fontSize: 14, color: AppTheme.primaryColor),
                ),
                onPressed: () {
                  _showSortOptions(context);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _stations.isEmpty
                    ? Center(child: Text('Yakında nokta yok'))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _stations.length,
                        itemBuilder: (context, index) {
                          final station = _stations[index];
                          return Card(
                            margin: const EdgeInsets.only(right: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              onTap: () {
                                // Detay gösterimi veya haritada merkeze alma eklenebilir
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 150,
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.directions_bus, color: AppTheme.primaryColor, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            station.active ? 'Açık' : 'Kapalı',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: station.active ? AppTheme.successColor : AppTheme.errorColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      station.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: AppTheme.primaryColor,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            station.district,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondaryColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 32,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu filtreye uygun nokta bulunamadı',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPointCard(Map<String, dynamic> point) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _showPointDetails(context, point);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(point['icon'], color: point['color'], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point['isOpen'] ? 'Açık' : 'Kapalı',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            point['isOpen']
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                point['name'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.directions,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    point['distance'],
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPointDetails(BuildContext context, Map<String, dynamic> point) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: point['color'].withOpacity(0.2),
                    child: Icon(point['icon'], color: point['color']),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          point['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    point['isOpen']
                                        ? AppTheme.successColor.withOpacity(0.2)
                                        : AppTheme.errorColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                point['isOpen'] ? 'Açık' : 'Kapalı',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      point['isOpen']
                                          ? AppTheme.successColor
                                          : AppTheme.errorColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              point['distance'],
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (point['type'] == 'bus')
                _buildDetailRow('Hat', point['busNumber']),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Konum',
                '${point['location']['lat']}, ${point['location']['lng']}',
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.directions,
                    label: 'Yol Tarifi',
                    onTap: () {
                      Navigator.pop(context);
                      _showSnackbar(
                        '${point['name']} için yol tarifi alınıyor...',
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.star_border,
                    label: 'Favorilere Ekle',
                    onTap: () {
                      Navigator.pop(context);
                      _showSnackbar('${point['name']} favorilere eklendi');
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.share,
                    label: 'Paylaş',
                    onTap: () {
                      Navigator.pop(context);
                      _showSnackbar('${point['name']} konumu paylaşılıyor...');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 16, color: AppTheme.textSecondaryColor),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primaryColor),
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

  void _showSortOptions(BuildContext context) {
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
                'Sıralama Seçenekleri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.near_me, color: AppTheme.primaryColor),
                title: const Text('Yakınlığa Göre'),
                onTap: () {
                  Navigator.pop(context);
                  _showSnackbar('Noktalar yakınlığa göre sıralandı');
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.sort_by_alpha,
                  color: AppTheme.secondaryColor,
                ),
                title: const Text('İsme Göre (A-Z)'),
                onTap: () {
                  Navigator.pop(context);
                  _showSnackbar('Noktalar isme göre sıralandı');
                },
              ),
              ListTile(
                leading: Icon(Icons.star, color: AppTheme.accentColor),
                title: const Text('Popülerliğe Göre'),
                onTap: () {
                  Navigator.pop(context);
                  _showSnackbar('Noktalar popülerliğe göre sıralandı');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
