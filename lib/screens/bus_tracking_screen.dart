import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import 'map_screen.dart';
import 'qr_code_screen.dart';

class BusTrackingScreen extends StatefulWidget {
  final String? busNumber;

  const BusTrackingScreen({super.key, this.busNumber});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  DateTime _lastUpdated = DateTime.now();

  // Örnek otobüs konum verileri
  final List<Map<String, dynamic>> _buses = [
    {
      'number': '11A',
      'name': 'Merkez - Üniversite',
      'licensePlate': '34 ABC 123',
      'currentStop': 'Belediye',
      'nextStop': 'Adliye',
      'arrivalTime': '3 dk',
      'distance': '1.2 km',
      'occupancy': 75, // %
      'isAccessible': true,
      'lastUpdated': DateTime.now().subtract(const Duration(minutes: 2)),
    },
    {
      'number': '22B',
      'name': 'Merkez - Sanayi',
      'licensePlate': '34 DEF 456',
      'currentStop': 'AVM',
      'nextStop': 'Stadyum',
      'arrivalTime': '5 dk',
      'distance': '2.1 km',
      'occupancy': 50, // %
      'isAccessible': true,
      'lastUpdated': DateTime.now().subtract(const Duration(minutes: 1)),
    },
    {
      'number': '33C',
      'name': 'Merkez - Sahil',
      'licensePlate': '34 GHI 789',
      'currentStop': 'Park',
      'nextStop': 'Müze',
      'arrivalTime': '7 dk',
      'distance': '3.4 km',
      'occupancy': 30, // %
      'isAccessible': false,
      'lastUpdated': DateTime.now().subtract(const Duration(minutes: 3)),
    },
    {
      'number': '44D',
      'name': 'Terminal - Merkez',
      'licensePlate': '34 JKL 012',
      'currentStop': 'Çarşı',
      'nextStop': 'Pazar',
      'arrivalTime': '2 dk',
      'distance': '0.8 km',
      'occupancy': 90, // %
      'isAccessible': true,
      'lastUpdated': DateTime.now().subtract(const Duration(minutes: 1)),
    },
    {
      'number': '55E',
      'name': 'Merkez - Havalimanı',
      'licensePlate': '34 MNO 345',
      'currentStop': 'Bulvar',
      'nextStop': 'Fuar',
      'arrivalTime': '10 dk',
      'distance': '5.5 km',
      'occupancy': 40, // %
      'isAccessible': true,
      'lastUpdated': DateTime.now().subtract(const Duration(minutes: 5)),
    },
  ];

  List<Map<String, dynamic>> get _filteredBuses {
    if (widget.busNumber != null) {
      return _buses.where((bus) => bus['number'] == widget.busNumber).toList();
    }

    if (_searchQuery.isEmpty) {
      return _buses;
    }

    return _buses.where((bus) {
      return bus['number'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          bus['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          bus['licensePlate'].toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    // Simüle edilmiş veri yenileme
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _lastUpdated = DateTime.now();
      _isRefreshing = false;
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title:
            widget.busNumber != null
                ? Text('${widget.busNumber} Takip', style: const TextStyle(color: Colors.white))
                : const Text('Otobüs Takip', style: TextStyle(color: Colors.white)),
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white), 
            onPressed: _refreshData
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.busNumber == null) _buildSearchBar(),
          _buildUpdateInfo(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child:
                  _filteredBuses.isEmpty ? _buildNoResults() : _buildBusList(),
            ),
          ),
        ],
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
            hintText: 'Hat numarası veya plaka ara...',
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

  Widget _buildUpdateInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.backgroundColor,
      child: Row(
        children: [
          if (_isRefreshing)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            )
          else
            Icon(
              Icons.access_time,
              size: 16,
              color: AppTheme.textSecondaryColor,
            ),
          const SizedBox(width: 8),
          Text(
            _isRefreshing
                ? 'Güncelleniyor...'
                : 'Son güncelleme: ${_formatTimeAgo(_lastUpdated)}',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
          ),
          const Spacer(),
          TextButton.icon(
            icon: Icon(
              Icons.my_location,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            label: Text(
              'Yakınımdakiler',
              style: TextStyle(fontSize: 12, color: AppTheme.primaryColor),
            ),
            onPressed: () {
              // Yakındaki otobüsleri göster
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 80,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Otobüs bulunamadı',
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

  Widget _buildBusList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredBuses.length,
      itemBuilder: (context, index) {
        final bus = _filteredBuses[index];
        final occupancy = bus['occupancy'] as int;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              _showBusDetails(context, bus);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                            bus['number'],
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
                              bus['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bus['licensePlate'],
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (bus['isAccessible'])
                        Icon(
                          Icons.accessible,
                          color: AppTheme.infoColor,
                          size: 22,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppTheme.primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Şu an: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        bus['currentStop'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward,
                        color: AppTheme.textSecondaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sonraki: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        bus['nextStop'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tahmini varış',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: AppTheme.primaryColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  bus['arrivalTime'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mesafe',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.directions,
                                  color: AppTheme.primaryColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  bus['distance'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Doluluk',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  _getOccupancyIcon(occupancy),
                                  color: _getOccupancyColor(occupancy),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$occupancy%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _getOccupancyColor(occupancy),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }

  IconData _getOccupancyIcon(int occupancy) {
    if (occupancy < 30) {
      return Icons.event_seat;
    } else if (occupancy < 70) {
      return Icons.airline_seat_recline_normal;
    } else {
      return Icons.people;
    }
  }

  Color _getOccupancyColor(int occupancy) {
    if (occupancy < 30) {
      return AppTheme.successColor;
    } else if (occupancy < 70) {
      return AppTheme.accentColor;
    } else {
      return AppTheme.errorColor;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk önce';
    } else {
      return '${difference.inHours} saat önce';
    }
  }

  void _showBusDetails(BuildContext context, Map<String, dynamic> bus) {
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        bus['number'],
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
                          bus['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bus['licensePlate'],
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Güncel Konum', bus['currentStop']),
              const SizedBox(height: 8),
              _buildDetailRow('Sonraki Durak', bus['nextStop']),
              const SizedBox(height: 8),
              _buildDetailRow('Tahmini Varış', bus['arrivalTime']),
              const SizedBox(height: 8),
              _buildDetailRow('Mesafe', bus['distance']),
              const SizedBox(height: 8),
              _buildDetailRow('Doluluk', '${bus['occupancy']}%'),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Engelli Erişimi',
                bus['isAccessible'] ? 'Var' : 'Yok',
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.map,
                    label: 'Haritada Göster',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => MapScreen(
                                locationType: 'bus',
                                initialLocation: {
                                  'lat': 41.0090,
                                  'lng': 28.9712,
                                },
                              ),
                        ),
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.qr_code,
                    label: 'QR Kod ile Ödeme',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const QRCodeScreen(isScanner: true),
                        ),
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.share,
                    label: 'Konum Paylaş',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${bus['name']} konumu paylaşıldı'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
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
}
