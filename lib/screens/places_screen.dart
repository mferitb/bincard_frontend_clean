import 'package:flutter/material.dart';
import '../services/places_service.dart';
import '../theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/api_constants.dart';

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
  String? _selectedCategory;
  String? _selectedType;
  
  // Map controller
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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
          // Category selection
          if (_selectedCategory == null) _buildCategorySelection(),
          
          // Type selection (if category is selected)
          if (_selectedCategory != null && _selectedType == null) 
            _buildTypeSelection(),
          
          // Map and results
          if (_selectedType != null)
            Expanded(
              child: _buildMapAndResults(),
            ),
        ],
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kategori Seçin',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: PlacesService.placeCategories.length,
                itemBuilder: (context, index) {
                  final category = PlacesService.placeCategories.keys.elementAt(index);
                  final types = PlacesService.placeCategories[category]!;
                  final icon = _getCategoryIcon(category);
                  
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryColor.withOpacity(0.1),
                              AppTheme.primaryColor.withOpacity(0.05),
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icon,
                              size: 40,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${types.length} seçenek',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
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
      ),
    );
  }

  Widget _buildTypeSelection() {
    final types = PlacesService.placeCategories[_selectedCategory]!;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    _selectedCategory!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: types.length,
                itemBuilder: (context, index) {
                  final type = types[index];
                  final label = PlacesService.placeTypes[type] ?? type;
                  final icon = _getTypeIcon(type);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text('Yakındaki $label'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _searchPlaces(type),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapAndResults() {
    if (_currentPosition == null) {
      return _buildErrorState();
    }

    return Column(
      children: [
        // Map
        Container(
          height: 200,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GoogleMap(
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
          ),
        ),
        
        // Results
        Expanded(
          child: _buildResultsList(),
        ),
      ],
    );
  }

  Widget _buildResultsList() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_places.isEmpty && _selectedType != null) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final place = _places[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getTypeIcon(_selectedType!),
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            title: Text(
              place.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.address,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                if (place.rating != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        place.rating!.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (place.userRatingsTotal != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${place.userRatingsTotal})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (place.openNow != null) ...[
                  Icon(
                    place.openNow! ? Icons.check_circle : Icons.cancel,
                    color: place.openNow! ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
            onTap: () => _showPlaceDetails(place),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              title: Container(
                height: 16,
                width: double.infinity,
                color: Colors.white,
              ),
              subtitle: Container(
                height: 12,
                width: double.infinity,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
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