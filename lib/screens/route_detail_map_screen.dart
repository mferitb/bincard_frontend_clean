import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../models/route_model.dart';
import '../models/station_model.dart';
import '../services/routes_service.dart';
import '../services/map_service.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';

class RouteDetailMapScreen extends StatefulWidget {
  final int routeId;
  
  const RouteDetailMapScreen({
    Key? key,
    required this.routeId,
  }) : super(key: key);

  @override
  State<RouteDetailMapScreen> createState() => _RouteDetailMapScreenState();
}

class _RouteDetailMapScreenState extends State<RouteDetailMapScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  RouteModel? _route;
  bool _isLoading = true;
  String? _error;
  
  // Direction filtering - default to outgoing, removed 'all' option
  String _selectedDirection = 'outgoing'; // 'outgoing', 'return'
  DirectionModel? _currentDirection;
  
  // Map data
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _busStationIcon;
  
  // Animation controller for route details panel
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _showRouteDetails = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _fetchRouteData();
    _loadBusStationIcon();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchRouteData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final route = await RoutesService().getRouteById(widget.routeId);
      setState(() {
        _route = route;
        _isLoading = false;
      });
      
      _updateMapData();
    } catch (e) {
      setState(() {
        _error = 'Rota yüklenemedi: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBusStationIcon() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/bus-station.png');
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 80, // Resize to appropriate size for map
        targetHeight: 80,
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ByteData? byteData = await frameInfo.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List uint8List = byteData!.buffer.asUint8List();
      
      setState(() {
        _busStationIcon = BitmapDescriptor.fromBytes(uint8List);
      });
    } catch (e) {
      debugPrint('Bus station icon yüklenemedi: $e');
      // Fallback to default icon
      setState(() {
        _busStationIcon = BitmapDescriptor.defaultMarker;
      });
    }
  }

  void _updateMapData() {
    if (_route == null) return;

    _markers.clear();
    _polylines.clear();

    // Filter directions based on selection with improved logic
    List<DirectionModel> directionsToShow = [];
    
    switch (_selectedDirection) {
      case 'outgoing':
        directionsToShow = _route!.directions
            .where((d) => d.type.toLowerCase().contains('gidiş') || 
                         d.type.toLowerCase().contains('outgoing') ||
                         d.name.toLowerCase().contains('gidiş') ||
                         d.name.toLowerCase().contains('outgoing'))
            .toList();
        // If no outgoing found, show first direction
        if (directionsToShow.isEmpty && _route!.directions.isNotEmpty) {
          directionsToShow = [_route!.directions.first];
        }
        break;
      case 'return':
        directionsToShow = _route!.directions
            .where((d) => d.type.toLowerCase().contains('dönüş') || 
                         d.type.toLowerCase().contains('return') ||
                         d.type.toLowerCase().contains('geliş') ||
                         d.name.toLowerCase().contains('dönüş') ||
                         d.name.toLowerCase().contains('return') ||
                         d.name.toLowerCase().contains('geliş'))
            .toList();
        // If no return found, show last direction
        if (directionsToShow.isEmpty && _route!.directions.length > 1) {
          directionsToShow = [_route!.directions.last];
        }
        break;
    }
    
    // If still no directions found, show all
    if (directionsToShow.isEmpty) {
      directionsToShow = _route!.directions;
    }

    // Add markers for stations
    Set<String> addedStations = {};
    
    for (var direction in directionsToShow) {
      Color directionColor = _selectedDirection == 'outgoing'
          ? AppTheme.primaryColor
          : AppTheme.accentColor;

      // Add start station marker
      if (!addedStations.contains(direction.startStation.id.toString())) {
        _markers.add(
          Marker(
            markerId: MarkerId('start_${direction.startStation.id}'),
            position: LatLng(
              direction.startStation.latitude,
              direction.startStation.longitude,
            ),
            infoWindow: InfoWindow(
              title: direction.startStation.name,
              snippet: 'Başlangıç Durağı',
            ),
            icon: _busStationIcon ?? BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
        addedStations.add(direction.startStation.id.toString());
      }

      // Add end station marker
      if (!addedStations.contains(direction.endStation.id.toString())) {
        _markers.add(
          Marker(
            markerId: MarkerId('end_${direction.endStation.id}'),
            position: LatLng(
              direction.endStation.latitude,
              direction.endStation.longitude,
            ),
            infoWindow: InfoWindow(
              title: direction.endStation.name,
              snippet: 'Bitiş Durağı',
            ),
            icon: _busStationIcon ?? BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
        addedStations.add(direction.endStation.id.toString());
      }

      // Add intermediate station markers and create polyline
      List<LatLng> polylinePoints = [];
      polylinePoints.add(LatLng(
        direction.startStation.latitude,
        direction.startStation.longitude,
      ));

      for (var node in direction.stationNodes) {
        // Add from station if not already added
        if (!addedStations.contains(node.fromStation.id.toString())) {
          _markers.add(
            Marker(
              markerId: MarkerId('station_${node.fromStation.id}'),
              position: LatLng(
                node.fromStation.latitude,
                node.fromStation.longitude,
              ),
              infoWindow: InfoWindow(
                title: node.fromStation.name,
                snippet: 'Durak',
              ),
              icon: _busStationIcon ?? BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet,
              ),
            ),
          );
          addedStations.add(node.fromStation.id.toString());
        }

        // Add to station if not already added
        if (!addedStations.contains(node.toStation.id.toString())) {
          _markers.add(
            Marker(
              markerId: MarkerId('station_${node.toStation.id}'),
              position: LatLng(
                node.toStation.latitude,
                node.toStation.longitude,
              ),
              infoWindow: InfoWindow(
                title: node.toStation.name,
                snippet: 'Durak',
              ),
              icon: _busStationIcon ?? BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet,
              ),
            ),
          );
          addedStations.add(node.toStation.id.toString());
        }

        // Add points to polyline
        polylinePoints.add(LatLng(
          node.fromStation.latitude,
          node.fromStation.longitude,
        ));
        polylinePoints.add(LatLng(
          node.toStation.latitude,
          node.toStation.longitude,
        ));
      }

      polylinePoints.add(LatLng(
        direction.endStation.latitude,
        direction.endStation.longitude,
      ));

      // Create polyline for this direction with improved styling
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route_${direction.id}'),
          points: polylinePoints,
          color: _selectedDirection == 'outgoing'
              ? AppTheme.primaryColor
              : Colors.orange, // Different solid color for return
          width: 5,
          patterns: [], // No dashed lines, all solid
        ),
      );
    }

    setState(() {});
    
    // Fit camera to show all markers
    if (_markers.isNotEmpty && _mapController != null) {
      _fitCameraToMarkers();
    }
  }

  void _fitCameraToMarkers() {
    if (_markers.isEmpty) return;

    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (var marker in _markers) {
      minLat = minLat < marker.position.latitude ? minLat : marker.position.latitude;
      maxLat = maxLat > marker.position.latitude ? maxLat : marker.position.latitude;
      minLng = minLng < marker.position.longitude ? minLng : marker.position.longitude;
      maxLng = maxLng > marker.position.longitude ? maxLng : marker.position.longitude;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }

  void _toggleRouteDetails() {
    setState(() {
      _showRouteDetails = !_showRouteDetails;
    });
    
    if (_showRouteDetails) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: Text(
          _route?.name ?? 'Rota Detayı',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchRouteData,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Google Map - Takes up 60% of screen
                    Expanded(
                      flex: 6,
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _route != null
                                  ? LatLng(
                                      _route!.startStation.latitude,
                                      _route!.startStation.longitude,
                                    )
                                  : const LatLng(41.0082, 28.9784),
                              zoom: 13,
                            ),
                            markers: _markers,
                            polylines: _polylines,
                            onMapCreated: (GoogleMapController controller) {
                              _mapController = controller;
                              if (_markers.isNotEmpty) {
                                Future.delayed(const Duration(milliseconds: 500), () {
                                  _fitCameraToMarkers();
                                });
                              }
                            },
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            mapType: MapType.normal,
                          ),

                          // Direction Filter Panel - Improved Design
                          Positioned(
                            top: 16,
                            left: 16,
                            right: 16,
                            child: _buildDirectionFilter(),
                          ),

                          // Legend - Improved Design
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: _buildLegend(),
                          ),
                        ],
                      ),
                    ),
                    
                    // Route Details Panel - Now below the map
                    Expanded(
                      flex: 4,
                      child: _buildRouteDetailsPanel(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDirectionFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip(
              'Gidiş',
              'outgoing',
              Icons.arrow_forward_rounded,
              AppTheme.primaryColor,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade200,
          ),
          Expanded(
            child: _buildFilterChip(
              'Dönüş',
              'return',
              Icons.arrow_back_rounded,
              AppTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon, Color color) {
    final isSelected = _selectedDirection == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDirection = value;
        });
        _updateMapData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                'Açıklama',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildLegendItem(
            Icons.directions_bus,
            'Durak',
            AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteDetailsPanel() {
    if (_route == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route header with improved design
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(_hexToColor(_route!.color)).withOpacity(0.1),
                          Color(_hexToColor(_route!.color)).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(_hexToColor(_route!.color)).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Color(_hexToColor(_route!.color)),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color(_hexToColor(_route!.color)).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _route!.code.length >= 2 
                                  ? _route!.code.substring(0, 2) 
                                  : _route!.code,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
                                _route!.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${_route!.startStation.name} → ${_route!.endStation.name}',
                                      style: TextStyle(
                                        fontSize: 14,
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
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Route info cards with improved design
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          Icons.timer_outlined,
                          '${_route!.estimatedDurationMinutes} dk',
                          'Süre',
                          AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          Icons.straighten,
                          '${_route!.totalDistanceKm.toStringAsFixed(1)} km',
                          'Mesafe',
                          AppTheme.accentColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          Icons.directions_bus_outlined,
                          '${_route!.directions.length}',
                          'Yön',
                          AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Schedule with improved design
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 20,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sefer Saatleri',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Weekday schedule
                  _buildScheduleCard(
                    'Hafta İçi',
                    Icons.calendar_today,
                    _route!.schedule.weekdayHours,
                    AppTheme.primaryColor,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Weekend schedule
                  _buildScheduleCard(
                    'Hafta Sonu',
                    Icons.weekend,
                    _route!.schedule.weekendHours,
                    AppTheme.accentColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(String title, IconData icon, List<String> hours, Color color) {
    // Clean hours by removing 'T' prefix if it exists
    List<String> cleanHours = hours.map((hour) {
      if (hour.startsWith('T')) {
        return hour.substring(1);
      }
      return hour;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (cleanHours.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cleanHours.take(6).map((hour) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    hour,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Sefer bilgisi mevcut değil',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (cleanHours.length > 6)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${cleanHours.length - 6} sefer daha',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

int _hexToColor(String hex) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) {
    hex = 'FF' + hex;
  }
  return int.parse(hex, radix: 16);
}