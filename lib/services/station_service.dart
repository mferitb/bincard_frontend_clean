import 'dart:convert';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../models/station_model.dart';
import 'api_service.dart';

class StationService {
  Future<List<String>> getStationKeywords({
    required String query,
  }) async {
    try {
      final response = await ApiService().dio.get(
        '/station/keywords',
        queryParameters: {
          'query': query,
        },
      );
      print('Anahtar kelime API yanıtı:');
      print(response.data);
      if (response.statusCode == 200) {
        if (response.data is List) {
          return List<String>.from(response.data);
        } else if (response.data['data'] is List) {
          return List<String>.from(response.data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Anahtar kelime API hatası: $e');
      return [];
    }
  }
  Future<List<StationModel>> getStationSearch({
    required String name,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await ApiService().dio.get(
        '/station/search',
        queryParameters: {
          'name': name,
          'page': page,
          'size': size,
        },
      );
      print('API ham yanıtı (search):');
      print(response.data);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null && data['content'] != null) {
          final List<dynamic> list = data['content'];
          return list.map((e) => StationModel.fromJson(e)).toList();
        } else {
          print('API yanıtında data veya content null! (search)');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Arama API hatası: $e');
      return [];
    }
  }
  // final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Future<StationModel?> getStationById(int id) async {
    try {
      final response = await ApiService().dio.get('/station/$id');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return StationModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<StationModel>> getNearbyStations({
    required double latitude,
    required double longitude,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await ApiService().dio.get(
        '/station/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'page': page,
          'size': size,
        },
      );
      print('API ham yanıtı:');
      print(response.data);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null && data['content'] != null) {
          final List<dynamic> list = data['content'];
          return list.map((e) => StationModel.fromJson(e)).toList();
        } else {
          print('API yanıtında data veya content null!');
          return [];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<StationModel>> getFavoriteStations() async {
    try {
      final response = await ApiService().dio.get('/station/favorite');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> list = response.data['data'];
        return list.map((e) => StationModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Favori duraklar alınırken hata: $e');
      return [];
    }
  }

  Future<bool> addFavoriteStation(int stationId) async {
    try {
      final response = await ApiService().dio.post('/station/add-favorite', queryParameters: {'stationId': stationId});
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('Favori durağa eklerken hata: $e');
      return false;
    }
  }

  Future<bool> removeFavoriteStation(int stationId) async {
    try {
      final response = await ApiService().dio.delete('/station/remove-favorite', queryParameters: {'stationId': stationId});
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('Favori duraktan çıkarırken hata: $e');
      return false;
    }
  }
} 