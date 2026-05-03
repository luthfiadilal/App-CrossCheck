import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  late Dio dio;

  // URL untuk emulator Android mengarah ke localhost mesin host
  // Jika menggunakan device asli, ganti dengan IP Address WiFi komputer (misal: http://192.168.1.5:5000/api)
  static const String baseUrl = 'https://api.crosscheck.my.id/api';

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    // Menambahkan Interceptor untuk menyisipkan Token di setiap request
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Bisa menambahkan logika khusus jika token expired (401)
          return handler.next(e);
        },
      ),
    );
  }
}
