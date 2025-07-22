import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/api_constants.dart';

class WeatherService {
  // static const String _baseUrl = ...
  // static const String _apiKey = ...
  // Bunlar kaldırıldı, ApiConstants üzerinden alınacak

  Future<WeatherData?> getWeather(double lat, double lon) async {
    final url = '${ApiConstants.openWeatherBaseUrl}/weather?lat=$lat&lon=$lon&appid=${ApiConstants.openWeatherApiKey}&units=metric&lang=tr';
    final response = await http.get(Uri.parse(url));
    debugPrint('Weather API status:  [32m [1m [4m${response.statusCode} [0m');
    debugPrint('Weather API body: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return WeatherData.fromJson(data);
    } else {
      return null;
    }
  }
}

class WeatherData {
  final double temperature;
  final String description;
  final String iconCode;
  final String? cityName;
  final double? windSpeed;
  final int? humidity;
  final int? pressure;

  WeatherData({
    required this.temperature,
    required this.description,
    required this.iconCode,
    this.cityName,
    this.windSpeed,
    this.humidity,
    this.pressure,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'],
      iconCode: json['weather'][0]['icon'],
      cityName: json['name'],
      windSpeed: json['wind'] != null && json['wind']['speed'] != null ? (json['wind']['speed'] as num).toDouble() : null,
      humidity: json['main'] != null && json['main']['humidity'] != null ? (json['main']['humidity'] as num).toInt() : null,
      pressure: json['main'] != null && json['main']['pressure'] != null ? (json['main']['pressure'] as num).toInt() : null,
    );
  }

  String getIconUrl() => '${ApiConstants.openWeatherBaseUrl.replaceFirst('/data/2.5', '')}/img/wn/$iconCode@2x.png';
}