import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Gelişmiş cache interceptor: endpoint bazlı süre, cache limiti, manuel temizleme
class AdvancedCacheInterceptor extends Interceptor {
  final Map<String, Duration> endpointCacheDurations;
  final int maxCacheEntries;

  AdvancedCacheInterceptor({
    this.endpointCacheDurations = const {},
    this.maxCacheEntries = 100,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.method.toUpperCase() == 'GET') {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cacheKey(options);
      final cached = prefs.getString(cacheKey);
      final cacheTime = prefs.getInt('${cacheKey}_time');
      final duration = endpointCacheDurations[options.path] ?? Duration(minutes: 5);
      if (cached != null && cacheTime != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - cacheTime < duration.inMilliseconds) {
          handler.resolve(Response(
            requestOptions: options,
            data: json.decode(cached),
            statusCode: 200,
            extra: {'fromCache': true},
          ));
          return;
        }
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (response.requestOptions.method.toUpperCase() == 'GET' && response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cacheKey(response.requestOptions);
      await _evictIfNeeded(prefs);
      prefs.setString(cacheKey, json.encode(response.data));
      prefs.setInt('${cacheKey}_time', DateTime.now().millisecondsSinceEpoch);
    }
    handler.next(response);
  }

  String _cacheKey(RequestOptions options) {
    final path = options.path;
    final query = options.queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&');
    return 'cache_${path}_$query';
  }

  Future<void> _evictIfNeeded(SharedPreferences prefs) async {
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_') && !k.endsWith('_time')).toList();
    if (keys.length >= maxCacheEntries) {
      // En eskiyi sil
      keys.sort((a, b) => (prefs.getInt('${a}_time') ?? 0).compareTo(prefs.getInt('${b}_time') ?? 0));
      await prefs.remove(keys.first);
      await prefs.remove('${keys.first}_time');
    }
  }

  /// Manuel cache temizleme
  static Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_')).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
