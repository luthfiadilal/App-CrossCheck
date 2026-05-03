class MonitoringDetailModel {
  final String detailId;
  final String taskName;
  final String quantity;
  final String condition;
  final String photoPath;
  final String description;
  final String location;
  final String statusTask;

  MonitoringDetailModel({
    required this.detailId,
    required this.taskName,
    required this.quantity,
    required this.condition,
    required this.photoPath,
    required this.description,
    required this.location,
    required this.statusTask,
  });

  factory MonitoringDetailModel.fromJson(Map<String, dynamic> json) {
    // Handle taskType as either a Map or a List of Maps
    String taskName = 'Tanpa Nama';
    var taskTypeJson = json['taskType'];
    
    if (taskTypeJson != null) {
      if (taskTypeJson is Map) {
        taskName = taskTypeJson['task_name'] ?? 'Tanpa Nama';
      } else if (taskTypeJson is List && taskTypeJson.isNotEmpty) {
        taskName = taskTypeJson[0]['task_name'] ?? 'Tanpa Nama';
      }
    }

    return MonitoringDetailModel(
      detailId: json['detail_id'] ?? '',
      taskName: taskName,
      quantity: json['quantity']?.toString() ?? '0',
      condition: json['conditions'] ?? 'BAIK',
      photoPath: json['photo_path'] ?? '',
      description: json['descriptions'] ?? '',
      location: json['locations'] ?? '',
      statusTask: json['status_task'] ?? 'PENDING',
    );
  }
}

class MonitoringLogModel {
  final String id;
  final String date;
  final String workerName;
  final String status;
  final List<MonitoringDetailModel> details;

  MonitoringLogModel({
    required this.id,
    required this.date,
    required this.workerName,
    required this.status,
    required this.details,
  });

  factory MonitoringLogModel.fromJson(Map<String, dynamic> json) {
    List<MonitoringDetailModel> details = [];
    if (json['details'] != null) {
      details = (json['details'] as List)
          .map((d) => MonitoringDetailModel.fromJson(d))
          .toList();
    }

    return MonitoringLogModel(
      id: json['log_id'] ?? '',
      date: json['created_at'] ?? '',
      workerName: json['worker_name'] ?? '',
      status: json['status_approval'] ?? 'PENDING',
      details: details,
    );
  }

  // Helper properties for summary (compatibility with old code)
  String get taskName => details.isNotEmpty ? details[0].taskName : 'Tanpa Tugas';
  String get quantity => details.isNotEmpty ? details[0].quantity : '0';
}
