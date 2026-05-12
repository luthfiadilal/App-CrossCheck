class ApprovalHistoryModel {
  final String approvalId;
  final String logId;
  final String approverId;
  final String approverName;
  final String approverRole;
  final String statusApproval;
  final String notes;
  final String actionDate;

  ApprovalHistoryModel({
    required this.approvalId,
    required this.logId,
    required this.approverId,
    required this.approverName,
    required this.approverRole,
    required this.statusApproval,
    required this.notes,
    required this.actionDate,
  });

  factory ApprovalHistoryModel.fromJson(Map<String, dynamic> json) {
    final approver = json['approver'] as Map<String, dynamic>?;
    return ApprovalHistoryModel(
      approvalId: json['approval_id'] ?? '',
      logId: json['log_id'] ?? '',
      approverId: json['approver_id'] ?? '',
      approverName: approver?['name'] ?? 'Tidak Diketahui',
      approverRole: approver?['role'] ?? '',
      statusApproval: json['status_approval'] ?? '',
      notes: json['notes'] ?? '',
      actionDate: json['action_date'] ?? '',
    );
  }
}

class MonitoringPhotoModel {
  final String photoId;
  final String photoPath; // Maps to 'image' in local DB or 'photo_path' in API
  final String caption;
  final String? filename;
  final int? size;
  final String? mimetype;

  MonitoringPhotoModel({
    required this.photoId,
    required this.photoPath,
    required this.caption,
    this.filename,
    this.size,
    this.mimetype,
  });

  factory MonitoringPhotoModel.fromJson(Map<String, dynamic> json) {
    return MonitoringPhotoModel(
      photoId: json['photo_id'] ?? '',
      photoPath: json['photo_path'] ?? json['image'] ?? '',
      caption: json['caption'] ?? '',
      filename: json['filename'],
      size: json['size'],
      mimetype: json['mimetype'],
    );
  }

  Map<String, dynamic> toJson() => {
    'photo_id': photoId,
    'photo_path': photoPath,
    'image': photoPath, // Include both for compatibility
    'caption': caption,
    'filename': filename,
    'size': size,
    'mimetype': mimetype,
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
  final List<ApprovalHistoryModel> approvalHistories;

  MonitoringLogModel({
    required this.id,
    required this.date,
    required this.workerName,
    required this.mandorName,
    required this.status,
    required this.details,
    this.approvalHistories = const [],
  });

  factory MonitoringLogModel.fromJson(Map<String, dynamic> json) {
    List<MonitoringDetailModel> details = [];
    if (json['details'] != null) {
      details = (json['details'] as List)
          .map((d) => MonitoringDetailModel.fromJson(d))
          .toList();
    }

    List<ApprovalHistoryModel> approvalHistories = [];
    if (json['approvalHistories'] != null) {
      final raw = json['approvalHistories'] as List;
      approvalHistories = raw
          .map((a) => ApprovalHistoryModel.fromJson(a))
          .toList();
      // Sort descending by actionDate
      approvalHistories.sort((a, b) => b.actionDate.compareTo(a.actionDate));
    }

    return MonitoringLogModel(
      id: json['log_id'] ?? '',
      date: json['created_at'] ?? '',
      workerName: json['worker_name'] ?? '',
      mandorName: json['mandor']?['name'] ?? 'Mandor Tidak Diketahui',
      status: json['status_approval'] ?? 'PENDING',
      details: details,
      approvalHistories: approvalHistories,
    );
  }

  String get taskName => details.isNotEmpty ? details[0].taskName : 'Tanpa Tugas';
  String get quantity => details.isNotEmpty ? details[0].quantity : '0';
  String get nomorBaris => details.isNotEmpty ? details[0].nomorBaris : 'N/A';
  String get namaAnggota => details.isNotEmpty ? details[0].namaAnggota : 'N/A';
}
