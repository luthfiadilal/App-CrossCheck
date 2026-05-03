import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/database/database_helper.dart';
import '../models/monitoring_log_model.dart';
import '../models/task_type_model.dart';
import 'package:sqflite/sqflite.dart';

class MonitoringRepository {
  final ApiClient _apiClient = ApiClient();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

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

  // --- LOCAL DATABASE METHODS ---

  Future<void> saveLogLocally({
    required String workerName,
    required List<Map<String, dynamic>> details,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    
    await db.transaction((txn) async {
      // Insert Header
      final logId = await txn.insert('pending_logs', {
        'worker_name': workerName,
        'mandor_id': null, // Will be filled by backend using req.user
        'status_approval': 'PENDING',
        'created_at': now,
        'updated_at': now,
      });

      // Insert Details
      for (var detail in details) {
        await txn.insert('pending_details', {
          'log_local_id': logId,
          'task_type_id': detail['task_type_id'],
          'quantity': detail['quantity'],
          'conditions': detail['conditions'],
          'photo_path': detail['photo_path'],
          'descriptions': detail['descriptions'],
          'locations': detail['locations'],
          'status_task': 'PENDING',
          'created_at': now,
          'local_image_path': detail['local_image_path'],
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> getPendingLogs() async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> logs = await db.query('pending_logs');
    List<Map<String, dynamic>> results = [];

    for (var log in logs) {
      final List<Map<String, dynamic>> details = await db.query(
        'pending_details',
        where: 'log_local_id = ?',
        whereArgs: [log['id']],
      );
      
      results.add({
        'local_id': log['id'],
        'worker_name': log['worker_name'],
        'status_approval': log['status_approval'],
        'created_at': log['created_at'],
        'updated_at': log['updated_at'],
        'details': details.map((d) {
          // Create a mutable map
          final map = Map<String, dynamic>.from(d);
          return map;
        }).toList(),
      });
    }

    return results;
  }

  Future<int> getPendingLogsCount() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pending_logs'));
    return count ?? 0;
  }

  Future<void> deleteLocalLog(int localId) async {
    final db = await _dbHelper.database;
    await db.delete('pending_logs', where: 'id = ?', whereArgs: [localId]);
    await db.delete('pending_details', where: 'log_local_id = ?', whereArgs: [localId]);
  }

  Future<void> bulkSubmitMonitoring(List<Map<String, dynamic>> reports) async {
    try {
      final response = await _apiClient.dio.post('/monitoring/bulk', data: reports);

      if (response.statusCode != 201) {
        throw Exception('Failed to bulk submit monitoring');
      }
    } on DioException catch (e) {
       if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to sync logs');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // --- TASK TYPE CACHING ---

  Future<List<TaskTypeModel>> fetchTaskTypes() async {
    final db = await _dbHelper.database;
    
    try {
      // Try to fetch from remote first
      final response = await _apiClient.dio.get('/task-types');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        final taskTypes = data.map((json) => TaskTypeModel.fromJson(json)).toList();
        
        // Cache to local
        await db.delete('task_types');
        for (var task in taskTypes) {
          await db.insert('task_types', task.toJson());
        }
        
        return taskTypes;
      } else {
        throw Exception('Failed to fetch task types from server');
      }
    } catch (e) {
      // If remote fails, fetch from local
      final List<Map<String, dynamic>> localData = await db.query('task_types');
      if (localData.isNotEmpty) {
        return localData.map((json) => TaskTypeModel.fromJson(json)).toList();
      }
      throw Exception('Error fetching task types: $e');
    }
  }

  // --- APPROVAL METHODS (UNCHANGED) ---

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
}
