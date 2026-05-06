import 'package:equatable/equatable.dart';
import '../../data/models/monitoring_log_model.dart';

abstract class MonitoringEvent extends Equatable {
  const MonitoringEvent();

  @override
  List<Object?> get props => [];
}

class FetchLogs extends MonitoringEvent {}

class FetchOfflineLogs extends MonitoringEvent {}

class FetchTaskTypes extends MonitoringEvent {}

class SubmitMonitoring extends MonitoringEvent {
  final String workerName;
  final List<Map<String, dynamic>> details;

  const SubmitMonitoring({required this.workerName, required this.details});

  @override
  List<Object> get props => [workerName, details];
}

class SaveMonitoringLocally extends MonitoringEvent {
  final String workerName;
  final List<Map<String, dynamic>> details;
  final String? serverLogId;

  const SaveMonitoringLocally({
    required this.workerName,
    required this.details,
    this.serverLogId,
  });

  @override
  List<Object?> get props => [workerName, details, serverLogId];
}

class UpdateMonitoringLocally extends MonitoringEvent {
  final int localId;
  final String workerName;
  final List<Map<String, dynamic>> details;
  final String? serverLogId;

  const UpdateMonitoringLocally({
    required this.localId,
    required this.workerName,
    required this.details,
    this.serverLogId,
  });

  @override
  List<Object?> get props => [localId, workerName, details, serverLogId];
}

class SyncMonitoringLogs extends MonitoringEvent {}

class FetchPendingLogsCount extends MonitoringEvent {}

class DownloadLogForEdit extends MonitoringEvent {
  final MonitoringLogModel log;

  const DownloadLogForEdit(this.log);

  @override
  List<Object> get props => [log];
}
