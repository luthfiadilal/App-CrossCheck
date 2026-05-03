import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data['data']);
        await saveSession(user);
        return user;
      } else {
        throw Exception('Login failed');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Login failed');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<UserModel> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      );

      if (response.statusCode == 201) {
        final user = UserModel.fromJson(response.data['data']);
        await saveSession(user);
        return user;
      } else {
        throw Exception('Register failed');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Register failed');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<void> saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user.token != null) {
      await prefs.setString('token', user.token!);
    }
    await prefs.setString('user_id', user.userId);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_role', user.role);
  }

  Future<UserModel?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    return UserModel(
      userId: prefs.getString('user_id') ?? '',
      name: prefs.getString('user_name') ?? '',
      email: prefs.getString('user_email') ?? '',
      role: prefs.getString('user_role') ?? '',
      token: token,
    );
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
