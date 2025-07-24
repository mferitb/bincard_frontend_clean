import 'dart:convert';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../models/station_model.dart';

class StationService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Future<StationModel?> getStationById(int id) async {
    try {
      final response = await _dio.get('/v1/api/station/$id');
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
      final response = await _dio.get(
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
        final List<dynamic> list = response.data['data']['content'];
        return list.map((e) => StationModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
} 