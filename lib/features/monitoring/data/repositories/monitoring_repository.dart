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
      throw Exception(_handleDioError(e, 'Failed to fetch logs'));
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
      throw Exception(_handleDioError(e, 'Failed to upload image'));
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
      throw Exception(_handleDioError(e, 'Failed to submit monitoring'));
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
          'nomor_baris': detail['nomor_baris'],
          'locations': detail['locations'],
          'status_task': 'PENDING',
          'created_at': now,
          'local_image_path': detail['local_image_path'],
          'nama_anggota': detail['nama_anggota'],
        });
      }
    });
  }

  Future<List<MonitoringLogModel>> fetchOfflineLogs() async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> logs = await db.query('pending_logs', orderBy: 'created_at DESC');
    List<MonitoringLogModel> results = [];

    for (var log in logs) {
      final List<Map<String, dynamic>> detailsRaw = await db.rawQuery('''
        SELECT d.*, t.name as task_name
        FROM pending_details d
        LEFT JOIN task_types t ON d.task_type_id = t.id
        WHERE d.log_local_id = ?
      ''', [log['id']]);
      
      List<MonitoringDetailModel> details = detailsRaw.map((d) {
        return MonitoringDetailModel(
          detailId: 'LOCAL-${d['id']}',
          taskName: d['task_name'] ?? 'Tugas Tidak Diketahui',
          quantity: d['quantity'] ?? '0',
          condition: d['conditions'] ?? 'BAIK',
          photoPath: d['local_image_path'] ?? '', // Use local path for offline view
          description: d['descriptions'] ?? '',
          nomorBaris: d['nomor_baris'] ?? '',
          location: d['locations'] ?? '',
          statusTask: d['status_task'] ?? 'PENDING',
          namaAnggota: d['nama_anggota'] ?? '',
        );
      }).toList();

      results.add(MonitoringLogModel(
        id: 'LOCAL-${log['id']}',
        date: log['created_at'] ?? '',
        workerName: log['worker_name'] ?? '',
        mandorName: 'Anda (Offline)',
        status: log['status_approval'] ?? 'PENDING',
        details: details,
      ));
    }

    return results;
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
          return Map<String, dynamic>.from(d);
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
      throw Exception(_handleDioError(e, 'Failed to sync logs'));
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
      
      if (e is DioException) {
        throw Exception(_handleDioError(e, 'Gagal mengambil daftar tugas. Hubungkan ke internet untuk pertama kali.'));
      }
      throw Exception('Gagal mengambil daftar tugas: $e');
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
      throw Exception(_handleDioError(e, 'Failed to fetch pending approvals'));
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
      throw Exception(_handleDioError(e, 'Failed to submit approval'));
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

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Failed to submit detail approval');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e, 'Failed to submit detail approval'));
    }
  }

  String _handleDioError(DioException e, String defaultMessage) {
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
      return 'Koneksi internet bermasalah. Silakan coba lagi.';
    }

    if (e.response?.statusCode == 503) {
      return 'Server sedang dalam pemeliharaan (503). Silakan coba beberapa saat lagi.';
    }

    if (e.response?.statusCode == 404) {
      return 'Endpoint tidak ditemukan (404).';
    }
    
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'] ?? defaultMessage;
      }
    }
    
    return 'Terjadi kesalahan sistem. Silakan coba lagi.';
  }
}
