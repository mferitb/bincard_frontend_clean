import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:archive/archive.dart';

/// Gzip ile JSON payload'ı sıkıştıran interceptor
class GzipRequestInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.data != null && options.headers['Content-Type'] == 'application/json') {
      final jsonString = json.encode(options.data);
      final gzipBytes = GZipEncoder().encode(utf8.encode(jsonString) as Uint8List);
      options.data = gzipBytes;
      options.headers['Content-Encoding'] = 'gzip';
      options.headers['Content-Type'] = 'application/json';

      // Asenkron loglama
      Future(() {
        // Burada loglama işlemini dosyaya veya başka bir servise gönderebilirsin
        // Örnek: print ile loglama (geliştirilebilir)
        print('[GzipInterceptor] Sıkıştırılmış payload boyutu: ${gzipBytes?.length ?? 0} byte');
      });
    }
    super.onRequest(options, handler);
  }
}
