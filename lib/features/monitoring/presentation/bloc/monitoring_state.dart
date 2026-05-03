import 'package:equatable/equatable.dart';
import '../../data/models/monitoring_log_model.dart';
import '../../data/models/task_type_model.dart';

abstract class MonitoringState extends Equatable {
  const MonitoringState();
  
  @override
  List<Object> get props => [];
}

class MonitoringInitial extends MonitoringState {}

class MonitoringLoading extends MonitoringState {}

class MonitoringLoaded extends MonitoringState {
  final List<MonitoringLogModel> logs;

  const MonitoringLoaded(this.logs);

  @override
  List<Object> get props => [logs];
}

class TaskTypesLoaded extends MonitoringState {
  final List<TaskTypeModel> taskTypes;

  const TaskTypesLoaded(this.taskTypes);

  @override
  List<Object> get props => [taskTypes];
}

class MonitoringError extends MonitoringState {
  final String message;

  const MonitoringError(this.message);

  @override
  List<Object> get props => [message];
}

class LogCreatedSuccess extends MonitoringState {
  final String message;

  const LogCreatedSuccess(this.message);

  @override
  List<Object> get props => [message];
}
