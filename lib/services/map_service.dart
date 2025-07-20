import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../constants/api_constants.dart';

class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  static const String _lastPermissionRequestKey = 'last_location_permission_request';
  static const String _locationTrackingKey = 'location_tracking_enabled';

  // Konum takibi açık mı kontrol et
  Future<bool> isLocationTrackingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationTrackingKey) ?? true;
  }

  // Konum izni kontrolü
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Konum servisi açık mı kontrol et
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Konum servisleri devre dışı.');
      return false;
    }

    // Konum izni var mı kontrol et
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // İzin iste
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Konum izinleri reddedildi.');
        await _setLastPermissionRequestToday();
        return false;
      }
    }

    // Kalıcı olarak reddedildi mi kontrol et
    if (permission == LocationPermission.deniedForever) {
      debugPrint(
        'Konum izinleri kalıcı olarak reddedildi, ayarlardan açılması gerekiyor.',
      );
      await _setLastPermissionRequestToday();
      return false;
    }

    return true;
  }

  // Mevcut konumu al
  Future<Position?> getCurrentLocation() async {
    try {
      if (!await checkLocationPermission()) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Konum alınamadı: $e');
      return null;
    }
  }

  // Konum bilgisini API'ye gönder
  Future<void> sendLocationToApi(double latitude, double longitude) async {
    try {
      final apiService = ApiService();
      await apiService.post(
        ApiConstants.userLocationEndpoint,
        data: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        },
      );
      debugPrint('Konum API\'ye gönderildi: $latitude, $longitude');
    } catch (e) {
      debugPrint('Konum API\'ye gönderilemedi: $e');
    }
  }

  // Son izin istenen günü kaydet
  Future<void> _setLastPermissionRequestToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    await prefs.setString(_lastPermissionRequestKey, today.toIso8601String().substring(0, 10));
  }

  // Bugün izin istendi mi kontrol et
  Future<bool> isPermissionRequestedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_lastPermissionRequestKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return last == today;
  }

  // Mevcut konum LatLng tipinde
  Future<LatLng?> getCurrentLatLng() async {
    final position = await getCurrentLocation();
    if (position == null) return null;

    return LatLng(position.latitude, position.longitude);
  }

  // İki konum arasındaki mesafeyi hesapla (metre cinsinden)
  double calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  // Haritada gösterilecek marker'ları oluştur
  Set<Marker> createMarkers(List<Map<String, dynamic>> points) {
    final Set<Marker> markers = {};

    for (final point in points) {
      final id = point['id'] as String;
      final position = point['position'] as LatLng;
      final title = point['title'] as String;
      final snippet = point['snippet'] as String?;
      final icon = point['icon'] as BitmapDescriptor?;

      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: position,
          infoWindow: InfoWindow(title: title, snippet: snippet),
          icon: icon ?? BitmapDescriptor.defaultMarker,
        ),
      );
    }

    return markers;
  }

  // Konum ayarlarını açma
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  // Uygulama ayarlarını açma
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
