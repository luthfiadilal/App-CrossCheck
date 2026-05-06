class MonitoringPhotoModel {
  final String photoId;
  final String photoPath;
  final String caption;

  MonitoringPhotoModel({
    required this.photoId,
    required this.photoPath,
    required this.caption,
  });

  factory MonitoringPhotoModel.fromJson(Map<String, dynamic> json) {
    return MonitoringPhotoModel(
      photoId: json['photo_id'] ?? '',
      photoPath: json['photo_path'] ?? '',
      caption: json['caption'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'photo_id': photoId,
    'photo_path': photoPath,
    'caption': caption,
  };
}

class MonitoringDetailModel {
  final String detailId;
  final String taskTypeId;
  final String taskName;
  final String quantity;
  final String condition;
  final String photoPath; // Deprecated but kept for compatibility
  final String description;
  final String nomorBaris;
  final String location;
  final String statusTask;
  final String namaAnggota;
  final List<MonitoringPhotoModel> photos;

  MonitoringDetailModel({
    required this.detailId,
    required this.taskTypeId,
    required this.taskName,
    required this.quantity,
    required this.condition,
    required this.photoPath,
    required this.description,
    required this.nomorBaris,
    required this.location,
    required this.statusTask,
    required this.namaAnggota,
    required this.photos,
  });

  factory MonitoringDetailModel.fromJson(Map<String, dynamic> json) {
    String taskName = 'Tanpa Nama';
    String taskTypeId = json['task_type_id'] ?? '';
    var taskTypeJson = json['taskType'];
    
    if (taskTypeJson != null) {
      if (taskTypeJson is Map) {
        taskName = taskTypeJson['task_name'] ?? 'Tanpa Nama';
        if (taskTypeId.isEmpty) taskTypeId = taskTypeJson['id'] ?? '';
      } else if (taskTypeJson is List && taskTypeJson.isNotEmpty) {
        taskName = taskTypeJson[0]['task_name'] ?? 'Tanpa Nama';
        if (taskTypeId.isEmpty) taskTypeId = taskTypeJson[0]['id'] ?? '';
      }
    }

    List<MonitoringPhotoModel> photos = [];
    if (json['photos'] != null) {
      photos = (json['photos'] as List)
          .map((p) => MonitoringPhotoModel.fromJson(p))
          .toList();
    } else if (json['photo_path'] != null && json['photo_path'] != '') {
      // Compatibility for old single photo
      photos.add(MonitoringPhotoModel(
        photoId: 'LEGACY',
        photoPath: json['photo_path'],
        caption: '',
      ));
    }

    return MonitoringDetailModel(
      detailId: json['detail_id'] ?? '',
      taskTypeId: taskTypeId,
      taskName: taskName,
      quantity: json['quantity']?.toString() ?? '0',
      condition: json['conditions'] ?? 'BAIK',
      photoPath: json['photo_path'] ?? '',
      description: json['descriptions'] ?? '',
      nomorBaris: json['nomor_baris'] ?? '',
      location: json['locations'] ?? '',
      statusTask: json['status_task'] ?? 'PENDING',
      namaAnggota: json['nama_anggota'] ?? '',
      photos: photos,
    );
  }
}

class MonitoringLogModel {
  final String id;
  final String date;
  final String workerName;
  final String mandorName;
  final String status;
  final List<MonitoringDetailModel> details;

  MonitoringLogModel({
    required this.id,
    required this.date,
    required this.workerName,
    required this.mandorName,
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
      mandorName: json['mandor']?['name'] ?? 'Mandor Tidak Diketahui',
      status: json['status_approval'] ?? 'PENDING',
      details: details,
    );
  }

  String get taskName => details.isNotEmpty ? details[0].taskName : 'Tanpa Tugas';
  String get quantity => details.isNotEmpty ? details[0].quantity : '0';
  String get nomorBaris => details.isNotEmpty ? details[0].nomorBaris : 'N/A';
  String get namaAnggota => details.isNotEmpty ? details[0].namaAnggota : 'N/A';
}
