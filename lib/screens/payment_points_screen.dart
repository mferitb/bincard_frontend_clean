import 'package:flutter/material.dart';
import '../models/payment_point_model.dart';
import '../services/payment_point_service.dart';
import 'payment_point_detail_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/map_service.dart';
import '../constants/api_constants.dart';
import '../services/user_service.dart';

class PaymentPointsScreen extends StatefulWidget {
  const PaymentPointsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentPointsScreen> createState() => _PaymentPointsScreenState();
}

class _PaymentPointsScreenState extends State<PaymentPointsScreen> {
  late Future<List<PaymentPoint>> _paymentPointsFuture;
  final _formKey = GlobalKey<FormState>();

  // Filtre alanları
  String? _name;
  String? _city;
  String? _district;
  String? _workingHours;
  bool? _active;
  List<String> _selectedPaymentMethods = [];
  double? _latitude;
  double? _longitude;
  double _radiusKm = 5.0; // Default 5 km
  bool _showNearby = false;
  double _mapZoom = 13.0;

  final List<String> _allPaymentMethods = [
    'CASH', 'CREDIT_CARD', 'DEBIT_CARD', 'QR_CODE'
  ];

  List<PaymentPoint> _lastFetchedPoints = [];

  // Yeni: Hızlı şehir ve ödeme yöntemi filtreleme için controllerlar
  final TextEditingController _cityFilterController = TextEditingController();
  String? _quickCity;
  String? _quickPaymentMethod;

  void _filterByCity() {
    if (_quickCity != null && _quickCity!.isNotEmpty) {
      setState(() {
        _paymentPointsFuture = PaymentPointService().getByCity(_quickCity!);
      });
    }
  }

  void _filterByPaymentMethod() {
    if (_quickPaymentMethod != null && _quickPaymentMethod!.isNotEmpty) {
      setState(() {
        _paymentPointsFuture = PaymentPointService().getByPaymentMethod(_quickPaymentMethod!);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _paymentPointsFuture = PaymentPointService().getAllPaymentPoints();
    _setInitialUserLocation();
  }

  void _setInitialUserLocation() async {
    final mapService = MapService();
    final hasPermission = await mapService.checkLocationPermission();
    if (!hasPermission) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Konum servisi kapalıysa ayarları açmaya zorlama, sadece default göster
        return;
      }
    }
    final pos = await mapService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
    }
  }

  void _search() async {
    final mapService = MapService();
    final hasPermission = await mapService.checkLocationPermission();
    if (!hasPermission) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await mapService.openLocationSettings();
      }
      return;
    }
    final pos = await mapService.getCurrentLocation();
    if (pos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum alınamadı.')));
      }
      return;
    }
    setState(() {
      _latitude = pos.latitude;
      _longitude = pos.longitude;
      if (_name != null && _name!.isNotEmpty) {
        _paymentPointsFuture = PaymentPointService().searchPaymentPoints(
          query: _name!,
          latitude: pos.latitude,
          longitude: pos.longitude,
          page: 0,
        );
      } else {
        _paymentPointsFuture = PaymentPointService().getAllPaymentPoints();
      }
    });
  }

  void _getNearby() async {
    final mapService = MapService();
    final hasPermission = await mapService.checkLocationPermission();
    if (!hasPermission) {
      // Konum servisleri kapalıysa doğrudan ayarları aç
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await mapService.openLocationSettings();
      }
      // Diğer durumlarda (izin reddi vs.) hiçbir şey gösterilmez
      return;
    }
    final pos = await mapService.getCurrentLocation();
    if (pos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum alınamadı.')));
      }
      return;
    }
    setState(() {
      _latitude = pos.latitude;
      _longitude = pos.longitude;
      _radiusKm = 5.0; // Yakındakiler butonunda daima 5 km
      _mapZoom = 16.0; // Yakınlaştır
      _paymentPointsFuture = PaymentPointService().getNearbyPaymentPoints(
        latitude: pos.latitude,
        longitude: pos.longitude,
        radiusKm: _radiusKm,
        page: 0,
        size: 10,
      );
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum servisleri kapalı.')));
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum izni reddedildi.')));
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum izni kalıcı olarak reddedildi.')));
      return;
    }
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _latitude = pos.latitude;
      _longitude = pos.longitude;
    });
  }

  // latlng ve MapLocationPickerScreen ile ilgili kodları kaldır

  void _updateLastFetchedPoints(List<PaymentPoint> points) {
    setState(() {
      _lastFetchedPoints = points;
    });
  }

  GoogleMapController? _mapController;
  Set<Marker> _googleMarkers = {};

  void _updateGoogleMarkers(List<PaymentPoint> points) {
    final markers = points.map((point) => Marker(
      markerId: MarkerId(point.id.toString()),
      position: LatLng(point.location.latitude, point.location.longitude),
      infoWindow: InfoWindow(title: point.name),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentPointDetailScreen(paymentPointId: point.id),
          ),
        );
      },
    )).toSet();
    // Kullanıcı konumu markerı
    if (_latitude != null && _longitude != null) {
      markers.add(Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(_latitude!, _longitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Mevcut Konum'),
      ));
    }
    setState(() {
      _googleMarkers = markers;
    });
  }

  // _initialMapCenter fonksiyonu artık Google Maps LatLng ile olacak veya kullanılmıyorsa tamamen kaldırılacak

  Widget _buildStatusChip(bool active) {
    return Chip(
      label: Text(active ? 'Aktif' : 'Pasif', style: const TextStyle(color: Colors.white)),
      backgroundColor: active ? Colors.green : Colors.red,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }

  IconData _paymentMethodIcon(String method) {
    switch (method) {
      case 'CASH':
        return Icons.attach_money;
      case 'CREDIT_CARD':
        return Icons.credit_card;
      case 'DEBIT_CARD':
        return Icons.account_balance_wallet;
      case 'QR_CODE':
        return Icons.qr_code;
      default:
        return Icons.payment;
    }
  }

  Color _paymentMethodSelectedColor(BuildContext context, String method) {
    switch (method) {
      case 'CASH':
        return Colors.green;
      case 'CREDIT_CARD':
        return Colors.blue;
      case 'DEBIT_CARD':
        return Colors.redAccent.shade100;
      case 'QR_CODE':
        return Theme.of(context).primaryColor;
      default:
        return Theme.of(context).chipTheme.selectedColor ?? Colors.grey.shade200;
    }
  }

  Color _paymentMethodIconColor(BuildContext context, String method) {
    switch (method) {
      case 'CASH':
        return Colors.green;
      case 'CREDIT_CARD':
        return Colors.blue;
      case 'DEBIT_CARD':
        return Colors.redAccent.shade100;
      case 'QR_CODE':
        return Theme.of(context).primaryColor;
      default:
        return Colors.blueGrey;
    }
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'CASH':
        return 'Nakit';
      case 'CREDIT_CARD':
        return 'Kredi Kartı';
      case 'DEBIT_CARD':
        return 'Banka Kartı';
      case 'QR_CODE':
        return 'QR Kod';
      default:
        return method;
    }
  }

  Future<Widget> _buildUserLocationMarker() async {
    final userService = UserService();
    try {
      final profile = await userService.getUserProfile();
      if (profile.profileUrl != null && profile.profileUrl!.isNotEmpty) {
        return Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              profile.profileUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_pin_circle, color: Colors.blue, size: 32),
            ),
          ),
        );
      }
    } catch (_) {}
    // Profil fotoğrafı yoksa mavi ikon
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.shade700,
        border: Border.all(color: Colors.white, width: 5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.person_pin_circle, color: Colors.white, size: 32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme Noktaları'),
      ),
      body: Column(
        children: [
          // --- YENİ: En üstte arama çubuğu ---
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Ödeme noktası ara...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    ),
                    onChanged: (value) {
                      _name = value.isEmpty ? null : value;
                    },
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  child: const Icon(Icons.search),
                ),
              ],
            ),
          ),
          // Harita sabit (Google Maps)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 260,
                child: FutureBuilder<List<PaymentPoint>>(
                  future: _paymentPointsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Hata: \\${snapshot.error}'));
                    }
                    final points = snapshot.data ?? [];
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_lastFetchedPoints != points) {
                        _updateLastFetchedPoints(points);
                        _updateGoogleMarkers(points);
                      }
                    });
                    return GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _latitude != null && _longitude != null
                            ? LatLng(_latitude!, _longitude!)
                            : points.isNotEmpty
                                ? LatLng(points.first.location.latitude, points.first.location.longitude)
                                : const LatLng(39.925533, 32.866287),
                        zoom: _mapZoom,
                      ),
                      markers: _googleMarkers,
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    );
                  },
                ),
              ),
            ),
          ),
          // Filtreleme barı sabit
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                title: Row(
                  children: const [
                    Icon(Icons.filter_alt_outlined),
                    SizedBox(width: 8),
                    Text('Filtrele / Ara', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.65,
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                        child: Form(
                          key: _formKey,
                          child: Wrap(
                            runSpacing: 8,
                            children: [
                              // Çalışma saatleri filtresi kaldırıldı
                              Wrap(
                                spacing: 8,
                                children: _allPaymentMethods.map((method) {
                                  final selected = _selectedPaymentMethods.contains(method);
                                  return FilterChip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_paymentMethodIcon(method), size: 16, color: selected ? Colors.white : Colors.black54),
                                        const SizedBox(width: 4),
                                        Text(_paymentMethodLabel(method), style: TextStyle(color: selected ? Colors.white : Colors.black87)),
                                      ],
                                    ),
                                    selected: selected,
                                    selectedColor: _paymentMethodSelectedColor(context, method),
                                    checkmarkColor: Colors.white,
                                    showCheckmark: false,
                                    onSelected: (isSelected) {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedPaymentMethods.add(method);
                                        } else {
                                          _selectedPaymentMethods.remove(method);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _search,
                                    icon: const Icon(Icons.search),
                                    label: const Text('Ara'),
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sadece liste kaydırılabilir
          Expanded(
            child: FutureBuilder<List<PaymentPoint>>(
              future: _paymentPointsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Hata: \\${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Ödeme noktası bulunamadı.'));
                }
                final points = snapshot.data!;
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: points.length,
                  itemBuilder: (context, index) {
                    final point = points[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentPointDetailScreen(paymentPointId: point.id),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on, color: Theme.of(context).primaryColor, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            point.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      point.address.street,
                                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                                    ),
                                    Text(
                                      point.address.district + ', ' + point.address.city,
                                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(point.workingHours, style: const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        ...point.paymentMethods.map((m) => Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(_paymentMethodIcon(m), size: 18, color: _paymentMethodIconColor(context, m)),
                                              const SizedBox(width: 4),
                                              Text(_paymentMethodLabel(m), style: TextStyle(color: _paymentMethodIconColor(context, m))),
                                            ],
                                          ),
                                        )),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 