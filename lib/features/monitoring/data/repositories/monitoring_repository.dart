import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../models/monitoring_log_model.dart';
import '../models/task_type_model.dart';

class MonitoringRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<MonitoringLogModel>> fetchLogs() async {
    try {
      final response = await _apiClient.dio.get('/monitoring');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => MonitoringLogModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch logs');
      }
    } on DioException catch (e) {
       if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch logs');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<String> uploadImage(String filePath) async {
    try {
      String fileName = filePath.split('/').last;
      FormData formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _apiClient.dio.post('/upload', data: formData);

      if (response.statusCode == 200) {
        return response.data['data']['url'];
      } else {
        throw Exception('Failed to upload image');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to upload image');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<MonitoringLogModel> submitMonitoring({
    required String workerName,
    required List<Map<String, dynamic>> details,
  }) async {
    try {
      final response = await _apiClient.dio.post('/monitoring', data: {
        'worker_name': workerName,
        'details': details,
      });

      if (response.statusCode == 201) {
        return MonitoringLogModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to submit monitoring');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to submit monitoring');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<List<MonitoringLogModel>> fetchPendingApprovals() async {
    try {
      final response = await _apiClient.dio.get('/approval/pending');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => MonitoringLogModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch pending approvals');
      }
    } on DioException catch (e) {
       if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch pending approvals');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<void> submitApproval({
    required String logId,
    required String status,
    required String notes,
  }) async {
    try {
      final response = await _apiClient.dio.post('/approval', data: {
        'log_id': logId,
        'status_approval': status,
        'notes': notes,
      });

      if (response.statusCode != 201) {
        throw Exception('Failed to submit approval');
      }
    } on DioException catch (e) {
       if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to submit approval');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<void> submitDetailApproval({
    required String detailId,
    required String status,
  }) async {
    try {
      final response = await _apiClient.dio.post('/approval/detail', data: {
        'detail_id': detailId,
        'status': status,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to submit detail approval');
      }
    } on DioException catch (e) {
       if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to submit detail approval');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<List<TaskTypeModel>> fetchTaskTypes() async {
    try {
      final response = await _apiClient.dio.get('/task-types');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => TaskTypeModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch task types');
      }
    } catch (e) {
      throw Exception('Error fetching task types: $e');
    }
  }
}
