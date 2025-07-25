import 'package:flutter/material.dart';
import '../services/places_service.dart';
import '../theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/api_constants.dart';
import '../screens/home_screen.dart';
import '../screens/saved_cards_screen.dart';
import '../screens/wallet_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/qr_code_screen.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({Key? key}) : super(key: key);

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  final PlacesService _placesService = PlacesService();
  
  // State variables
  Position? _currentPosition;
  List<Place> _places = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = PlacesService.placeCategories.keys.first;
  String? _selectedType;
  int _selectedIndex = 0;
  
  // Map controller
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    // Varsayılan ilk kategoriye göre ilk tip seçili olsun
    _selectedType = PlacesService.placeCategories[_selectedCategory]?.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedType != null) {
        _searchPlaces(_selectedType!);
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final position = await _placesService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Konum alınamadı. Lütfen konum izinlerini kontrol edin.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Konum alınırken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchPlaces(String type) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum bilgisi bulunamadı')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _selectedType = type;
      _places = [];
      _markers = {};
    });

    try {
      final places = await _placesService.searchNearbyPlaces(
        type: type,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: 10000, // 10 km - daha geniş arama yarıçapı
      );

      setState(() {
        _places = places;
        _isLoading = false;
      });

      _updateMarkers();
    } catch (e) {
      setState(() {
        _error = 'Yerler aranırken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  void _updateMarkers() {
    final markers = <Marker>{};
    
    // Kullanıcı konumu marker'ı
    if (_currentPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Mevcut Konum'),
      ));
    }

    // Place marker'ları
    for (int i = 0; i < _places.length; i++) {
      final place = _places[i];
      if (place.geometry != null) {
        markers.add(Marker(
          markerId: MarkerId('place_$i'),
          position: LatLng(
            place.geometry!.location.lat,
            place.geometry!.location.lng,
          ),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.address,
          ),
          onTap: () => _showPlaceDetails(place),
        ));
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  void _showPlaceDetails(Place place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Place name
              Text(
                place.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Address
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      place.address,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Rating and price level
              Row(
                children: [
                  if (place.rating != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          place.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (place.userRatingsTotal != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${place.userRatingsTotal})',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(width: 16),
                  if (place.priceLevel != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.attach_money, color: Colors.green, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '₺' * place.priceLevel!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              
              // Open now status
              if (place.openNow != null) ...[
                Row(
                  children: [
                    Icon(
                      place.openNow! ? Icons.check_circle : Icons.cancel,
                      color: place.openNow! ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      place.openNow! ? 'Açık' : 'Kapalı',
                      style: TextStyle(
                        fontSize: 16,
                        color: place.openNow! ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Yol tarifi aç
                        _openDirections(place);
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('Yol Tarifi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Paylaş
                        _sharePlace(place);
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Paylaş'),
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

  void _openDirections(Place place) {
    if (place.geometry != null) {
      final url = '${ApiConstants.googleMapsDirectionsUrl}?api=1&destination=${place.geometry!.location.lat},${place.geometry!.location.lng}';
      // URL'yi açmak için url_launcher kullanılabilir
      debugPrint('Yol tarifi URL: $url');
    }
  }

  void _sharePlace(Place place) {
    final shareText = '${place.name}\n${place.address}';
    // Share paketi kullanılarak paylaşım yapılabilir
    debugPrint('Paylaşım metni: $shareText');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Yakındaki Yerler'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: AppTheme.primaryColor),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHorizontalFilters(),
          Expanded(
            child: _buildFullScreenMap(),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        elevation: 10,
        color: Colors.white,
        shadowColor: Colors.black.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Ana Sayfa',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.credit_card_rounded,
                label: 'Kartlarım',
                index: 1,
              ),
              const SizedBox(width: 40),
              _buildNavItem(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Cüzdan',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: 'Profil',
                index: 3,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 10),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QRCodeScreen(isScanner: true),
              ),
            );
          },
          backgroundColor: AppTheme.primaryColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 26),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SavedCardsScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WalletScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalFilters() {
    final categories = PlacesService.placeCategories.keys.toList();
    final types = PlacesService.placeCategories[_selectedCategory]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCategory == category;
              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedCategory = category;
                      _selectedType = PlacesService.placeCategories[category]?.first;
                    });
                    if (_selectedType != null) {
                      _searchPlaces(_selectedType!);
                    }
                  }
                },
                selectedColor: AppTheme.primaryColor,
                backgroundColor: Colors.grey[200],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: types.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final type = types[index];
              final label = PlacesService.placeTypes[type] ?? type;
              final isSelected = _selectedType == type;
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedType = type;
                    });
                    _searchPlaces(type);
                  }
                },
                selectedColor: AppTheme.primaryColor,
                backgroundColor: Colors.grey[200],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFullScreenMap() {
    if (_currentPosition == null) {
      return _buildErrorState();
    }
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 14,
          ),
          markers: _markers,
          onMapCreated: (controller) {
            _mapController = controller;
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
        ),
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Bir hata oluştu',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _getCurrentLocation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tekrar Dene'),
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
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Yakınınızda ${PlacesService.placeTypes[_selectedType] ?? _selectedType} bulunamadı',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Arama yarıçapını artırmayı deneyin',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Yemek & İçecek':
        return Icons.restaurant;
      case 'Alışveriş':
        return Icons.shopping_bag;
      case 'Sağlık':
        return Icons.local_hospital;
      case 'Finans':
        return Icons.account_balance;
      case 'Ulaşım':
        return Icons.directions_car;
      case 'Eğitim':
        return Icons.school;
      case 'Kültür & Eğlence':
        return Icons.movie;
      case 'Spor & Güzellik':
        return Icons.fitness_center;
      case 'Hizmetler':
        return Icons.miscellaneous_services;
      case 'Konaklama':
        return Icons.hotel;
      default:
        return Icons.place;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'restaurant':
        return Icons.restaurant;
      case 'cafe':
        return Icons.coffee;
      case 'store':
      case 'supermarket':
      case 'convenience_store':
        return Icons.store;
      case 'bakery':
        return Icons.cake;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'hospital':
        return Icons.local_hospital;
      case 'bank':
      case 'atm':
        return Icons.account_balance;
      case 'gas_station':
        return Icons.local_gas_station;
      case 'parking':
        return Icons.local_parking;
      case 'school':
      case 'university':
        return Icons.school;
      case 'library':
        return Icons.local_library;
      case 'museum':
        return Icons.museum;
      case 'movie_theater':
        return Icons.movie;
      case 'gym':
        return Icons.fitness_center;
      case 'beauty_salon':
        return Icons.face;
      case 'laundry':
        return Icons.local_laundry_service;
      case 'post_office':
        return Icons.mail;
      case 'police':
        return Icons.local_police;
      case 'fire_station':
        return Icons.local_fire_department;
      case 'bus_station':
      case 'train_station':
        return Icons.directions_bus;
      case 'airport':
        return Icons.flight;
      case 'hotel':
      case 'lodging':
        return Icons.hotel;
      case 'shopping_mall':
        return Icons.shopping_bag;
      case 'clothing_store':
        return Icons.checkroom;
      case 'electronics_store':
        return Icons.devices;
      case 'book_store':
        return Icons.book;
      case 'jewelry_store':
        return Icons.diamond;
      case 'shoe_store':
        return Icons.sports_soccer;
      case 'furniture_store':
        return Icons.chair;
      case 'hardware_store':
        return Icons.hardware;
      case 'liquor_store':
        return Icons.local_bar;
      case 'pet_store':
        return Icons.pets;
      case 'veterinary_care':
        return Icons.medical_services;
      case 'dentist':
      case 'doctor':
        return Icons.medical_services;
      case 'real_estate_agency':
        return Icons.home;
      case 'travel_agency':
        return Icons.flight_takeoff;
      case 'car_rental':
      case 'car_dealer':
      case 'car_repair':
      case 'car_wash':
        return Icons.directions_car;
      default:
        return Icons.place;
    }
  }
} 