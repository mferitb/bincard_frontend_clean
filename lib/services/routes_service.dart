import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/route_model.dart';
import '../constants/api_constants.dart';
import 'secure_storage_service.dart';

class RouteScheduleDTO {
  final List<String> weekdayHours;
  final List<String> weekendHours;

  RouteScheduleDTO({
    required this.weekdayHours,
    required this.weekendHours,
  });

  factory RouteScheduleDTO.fromJson(Map<String, dynamic> json) {
    return RouteScheduleDTO(
      weekdayHours: List<String>.from(json['weekdayHours'] ?? []),
      weekendHours: List<String>.from(json['weekendHours'] ?? []),
    );
  }
}

class RouteNameDTO {
  final int id;
  final String name;
  final String code;
  final String routeType;
  final String color;
  final String startStationName;
  final String endStationName;
  final int estimatedDurationMinutes;
  final double totalDistanceKm;
  final RouteScheduleDTO routeSchedule;
  final bool hasOutgoingDirection;
  final bool hasReturnDirection;

  RouteNameDTO({
    required this.id,
    required this.name,
    required this.code,
    required this.routeType,
    required this.color,
    required this.startStationName,
    required this.endStationName,
    required this.estimatedDurationMinutes,
    required this.totalDistanceKm,
    required this.routeSchedule,
    required this.hasOutgoingDirection,
    required this.hasReturnDirection,
  });

  factory RouteNameDTO.fromJson(Map<String, dynamic> json) {
    return RouteNameDTO(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      routeType: json['routeType'],
      color: json['color'],
      startStationName: json['startStationName'],
      endStationName: json['endStationName'],
      estimatedDurationMinutes: json['estimatedDurationMinutes'],
      totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
      routeSchedule: RouteScheduleDTO.fromJson(json['routeSchedule']),
      hasOutgoingDirection: json['hasOutgoingDirection'] ?? false,
      hasReturnDirection: json['hasReturnDirection'] ?? false,
    );
  }
}

class RoutesService {
  Future<List<RouteModel>> fetchRoutes() async {
    final url = ApiConstants.baseUrl + '/route';
    print('[fetchRoutes] URL: ' + url);
    print('[fetchRoutes] Headers: ' + ApiConstants.headers.toString());
    final response = await http.get(Uri.parse(url), headers: ApiConstants.headers);
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List data = body['data'] ?? body;
      return data.map((e) => RouteModel.fromJson(e)).toList();
    } else {
      throw Exception('Rotalar yüklenemedi');
    }
  }

  Future<RouteModel> getRouteById(int id) async {
    final url = ApiConstants.baseUrl + '/route/$id';
    print('[getRouteById] URL: ' + url);
    print('[getRouteById] Headers: ' + ApiConstants.headers.toString());
    final response = await http.get(Uri.parse(url), headers: ApiConstants.headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return RouteModel.fromJson(data['data'] ?? data);
    } else {
      throw Exception('Rota bulunamadı');
    }
  }

  Future<List<RouteSearchModel>> searchRoutes(String query) async {
    final url = '${ApiConstants.baseUrl}/route/search?name=$query';
    print('[searchRoutes] URL: $url');
    print('[searchRoutes] Headers: ${ApiConstants.headers.toString()}');
    
    final response = await http.get(Uri.parse(url), headers: ApiConstants.headers);
    
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List data = body['data'] ?? [];
      return data.map((e) => RouteSearchModel.fromJson(e)).toList();
    } else {
      throw Exception('Rota araması yapılamadı');
    }
  }

  Future<bool> addFavoriteRoute(int routeId) async {
    final url = ApiConstants.baseUrl + '/route/favorite?routeId=$routeId';
    final token = await SecureStorageService().getAccessToken();
    final headers = {
      ...ApiConstants.headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.post(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body['success'] == true;
    }
    return false;
  }

  Future<List<RouteNameDTO>> getFavoriteRoutes() async {
    final url = ApiConstants.baseUrl + '/route/favorites';
    final token = await SecureStorageService().getAccessToken();
    final headers = {
      ...ApiConstants.headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List data = body['data'] ?? [];
      return data.map((e) => RouteNameDTO.fromJson(e)).toList();
    }
    return [];
  }
} 