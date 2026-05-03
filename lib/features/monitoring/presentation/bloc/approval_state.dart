import 'package:equatable/equatable.dart';
import '../../data/models/monitoring_log_model.dart';

abstract class ApprovalState extends Equatable {
  const ApprovalState();
  
  @override
  List<Object> get props => [];
}

class ApprovalInitial extends ApprovalState {}

class ApprovalLoading extends ApprovalState {}

class ApprovalLoaded extends ApprovalState {
  final List<MonitoringLogModel> pendingLogs;

  const ApprovalLoaded(this.pendingLogs);

  @override
  List<Object> get props => [pendingLogs];
}

class ApprovalError extends ApprovalState {
  final String message;

  const ApprovalError(this.message);

  @override
  List<Object> get props => [message];
}

class ApprovalSuccess extends ApprovalState {
  final String message;

  const ApprovalSuccess(this.message);

  @override
  List<Object> get props => [message];
}
