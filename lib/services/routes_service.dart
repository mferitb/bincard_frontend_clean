import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/route_model.dart';
import '../constants/api_constants.dart';

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
} 