import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class PlacesService {
  static const String _apiKey = 'AIzaSyBRYfrvFsxgARSM_iE7JA1EHu1nSpaWAxc'; // Google Places API için bu anahtarın aktif olması gerekiyor
  
  // Place türleri ve Türkçe isimleri
  static const Map<String, String> placeTypes = {
    'restaurant': 'Restoran',
    'cafe': 'Kafe',
    'store': 'Market',
    'supermarket': 'Süpermarket',
    'grocery_or_supermarket': 'Süpermarket', // Google Places API'de doğru type
    'bakery': 'Fırın',
    'pharmacy': 'Eczane',
    'hospital': 'Hastane',
    'bank': 'Banka',
    'atm': 'ATM',
    'gas_station': 'Benzin İstasyonu',
    'parking': 'Otopark',
    'school': 'Okul',
    'university': 'Üniversite',
    'library': 'Kütüphane',
    'museum': 'Müze',
    'movie_theater': 'Sinema',
    'gym': 'Spor Salonu',
    'beauty_salon': 'Güzellik Salonu',
    'laundry': 'Çamaşırhane',
    'post_office': 'Postane',
    'police': 'Polis Merkezi',
    'fire_station': 'İtfaiye',
    'bus_station': 'Otobüs Durağı',
    'train_station': 'Tren İstasyonu',
    'airport': 'Havaalanı',
    'hotel': 'Otel',
    'lodging': 'Konaklama',
    'shopping_mall': 'AVM',
    'clothing_store': 'Giyim Mağazası',
    'electronics_store': 'Elektronik Mağazası',
    'book_store': 'Kitapçı',
    'jewelry_store': 'Kuyumcu',
    'shoe_store': 'Ayakkabı Mağazası',
    'furniture_store': 'Mobilya Mağazası',
    'hardware_store': 'Hırdavatçı',
    'convenience_store': 'Bakkal',
    'liquor_store': 'Şarapçı',
    'pet_store': 'Pet Shop',
    'veterinary_care': 'Veteriner',
    'dentist': 'Diş Hekimi',
    'doctor': 'Doktor',
    'real_estate_agency': 'Emlak Ofisi',
    'travel_agency': 'Seyahat Acentesi',
    'car_rental': 'Araç Kiralama',
    'car_dealer': 'Oto Galeri',
    'car_repair': 'Oto Tamir',
    'car_wash': 'Oto Yıkama',
  };

  // Place türlerini kategorilere ayır
  static const Map<String, List<String>> placeCategories = {
    'Yemek & İçecek': [
      'restaurant', 'cafe', 'bakery', 'liquor_store'
    ],
    'Alışveriş': [
      'grocery_or_supermarket', 'store', 'convenience_store', 'shopping_mall',
      'clothing_store', 'electronics_store', 'book_store', 'jewelry_store',
      'shoe_store', 'furniture_store', 'hardware_store'
    ],
    'Sağlık': [
      'pharmacy', 'hospital', 'veterinary_care', 'dentist', 'doctor'
    ],
    'Finans': [
      'bank', 'atm'
    ],
    'Ulaşım': [
      'gas_station', 'parking', 'bus_station', 'train_station', 'airport',
      'car_rental', 'car_dealer', 'car_repair', 'car_wash'
    ],
    'Eğitim': [
      'school', 'university', 'library'
    ],
    'Kültür & Eğlence': [
      'museum', 'movie_theater'
    ],
    'Spor & Güzellik': [
      'gym', 'beauty_salon'
    ],
    'Hizmetler': [
      'laundry', 'post_office', 'police', 'fire_station', 'pet_store',
      'real_estate_agency', 'travel_agency'
    ],
    'Konaklama': [
      'hotel', 'lodging'
    ],
  };

  // Kullanıcının konumunu al
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Konum servisi kapalı');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Konum izni reddedildi');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Konum izni kalıcı olarak reddedildi');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Konum alınırken hata: $e');
      return null;
    }
  }

  // Yakındaki yerleri ara
  Future<List<Place>> searchNearbyPlaces({
    required String type,
    required double latitude,
    required double longitude,
    double radius = 5000, // 5 km
  }) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$latitude,$longitude'
        '&radius=${radius.toInt()}'
        '&type=$type'
        '&key=$_apiKey'
      );

      debugPrint('Places API URL: $url');

      final response = await http.get(url);
      
      debugPrint('Places API Response Status: ${response.statusCode}');
      debugPrint('Places API Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'];
        
        debugPrint('Places API Status: $status');
        
        if (status == 'OK') {
          final results = data['results'] as List;
          debugPrint('Found ${results.length} places');
          
          List<Place> places = [];
          
          for (var result in results) {
            final place = Place.fromJson(result);
            // Mesafeyi hesapla
            place.distance = Geolocator.distanceBetween(
              latitude,
              longitude,
              place.geometry?.location.lat ?? 0,
              place.geometry?.location.lng ?? 0,
            );
            places.add(place);
            debugPrint('Place: ${place.name} - Distance: ${place.distance?.toStringAsFixed(0)}m');
          }
          
          // Mesafeye göre sırala
          places.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
          
          return places;
        } else if (status == 'ZERO_RESULTS') {
          debugPrint('No places found for type: $type');
          return [];
        } else {
          debugPrint('Places API Error: $status');
          return [];
        }
      } else {
        debugPrint('Places API HTTP Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Yakındaki yerler aranırken hata: $e');
      return [];
    }
  }

  // Place detaylarını al
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=place_id,name,formatted_address,formatted_phone_number,website,rating,user_ratings_total,price_level,opening_hours,photos,geometry,types'
        '&key=$_apiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'];
        
        if (result != null) {
          return PlaceDetails.fromJson(result);
        }
      } else {
        debugPrint('Place Details API hatası: ${response.statusCode}');
      }
      
      return null;
    } catch (e) {
      debugPrint('Place detayları alınırken hata: $e');
      return null;
    }
  }

  // Fotoğraf URL'sini al
  String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=$maxWidth&photo_reference=$photoReference&key=$_apiKey';
  }
}

// Place modeli
class Place {
  final String id;
  final String name;
  final String address;
  final double? rating;
  final int? userRatingsTotal;
  final int? priceLevel;
  final bool? openNow;
  final List<String>? types;
  final Geometry? geometry;
  final List<Photo>? photos;
  double? distance; // Mesafe bilgisi

  Place({
    required this.id,
    required this.name,
    required this.address,
    this.rating,
    this.userRatingsTotal,
    this.priceLevel,
    this.openNow,
    this.types,
    this.geometry,
    this.photos,
    this.distance,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['place_id'] ?? '',
      name: json['name'] ?? '',
      address: json['vicinity'] ?? '',
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
      priceLevel: json['price_level'],
      openNow: json['opening_hours']?['open_now'],
      types: json['types'] != null 
          ? List<String>.from(json['types'])
          : null,
      geometry: json['geometry'] != null 
          ? Geometry.fromJson(json['geometry'])
          : null,
      photos: json['photos'] != null 
          ? (json['photos'] as List).map((photo) => Photo.fromJson(photo)).toList()
          : null,
    );
  }
}

// Place detayları modeli
class PlaceDetails {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? website;
  final double? rating;
  final int? userRatingsTotal;
  final int? priceLevel;
  final bool? openNow;
  final List<String>? openingHours;
  final List<String>? types;
  final List<Photo>? photos;
  final Geometry? geometry;

  PlaceDetails({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.website,
    this.rating,
    this.userRatingsTotal,
    this.priceLevel,
    this.openNow,
    this.openingHours,
    this.types,
    this.photos,
    this.geometry,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    return PlaceDetails(
      id: json['place_id'] ?? '',
      name: json['name'] ?? '',
      address: json['formatted_address'] ?? '',
      phone: json['formatted_phone_number'],
      website: json['website'],
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
      priceLevel: json['price_level'],
      openNow: json['opening_hours']?['open_now'],
      openingHours: json['opening_hours']?['weekday_text'] != null 
          ? List<String>.from(json['opening_hours']['weekday_text'])
          : null,
      types: json['types'] != null 
          ? List<String>.from(json['types'])
          : null,
      photos: json['photos'] != null 
          ? (json['photos'] as List).map((photo) => Photo.fromJson(photo)).toList()
          : null,
      geometry: json['geometry'] != null 
          ? Geometry.fromJson(json['geometry'])
          : null,
    );
  }
}

// Geometry modeli
class Geometry {
  final Location location;

  Geometry({required this.location});

  factory Geometry.fromJson(Map<String, dynamic> json) {
    return Geometry(
      location: Location.fromJson(json['location']),
    );
  }
}

// Location modeli
class Location {
  final double lat;
  final double lng;

  Location({required this.lat, required this.lng});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: json['lat']?.toDouble() ?? 0.0,
      lng: json['lng']?.toDouble() ?? 0.0,
    );
  }
}

// Photo modeli
class Photo {
  final String photoReference;
  final int? height;
  final int? width;

  Photo({
    required this.photoReference,
    this.height,
    this.width,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      photoReference: json['photo_reference'] ?? '',
      height: json['height'],
      width: json['width'],
    );
  }

  String getPhotoUrl(String apiKey, {int maxWidth = 400}) {
    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=$maxWidth&photo_reference=$photoReference&key=$apiKey';
  }
}
