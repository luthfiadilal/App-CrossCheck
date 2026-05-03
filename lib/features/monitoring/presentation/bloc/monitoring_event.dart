import 'package:equatable/equatable.dart';
import '../../data/models/monitoring_log_model.dart';

abstract class MonitoringEvent extends Equatable {
  const MonitoringEvent();

  @override
  List<Object> get props => [];
}

class FetchLogs extends MonitoringEvent {}

class FetchTaskTypes extends MonitoringEvent {}

class SubmitMonitoring extends MonitoringEvent {
  final String workerName;
  final List<Map<String, dynamic>> details;

  const SubmitMonitoring({
    required this.workerName,
    required this.details,
  });

  @override
  List<Object> get props => [workerName, details];
}
