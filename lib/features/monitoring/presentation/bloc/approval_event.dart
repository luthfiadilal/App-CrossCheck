import 'package:equatable/equatable.dart';
import '../../data/models/monitoring_log_model.dart';

abstract class ApprovalEvent extends Equatable {
  const ApprovalEvent();

  @override
  List<Object> get props => [];
}

class FetchPendingApprovals extends ApprovalEvent {}

class SubmitApprovalDecision extends ApprovalEvent {
  final String logId;
  final String status;
  final String notes;

  const SubmitApprovalDecision({
    required this.logId,
    required this.status,
    required this.notes,
  });

  @override
  List<Object> get props => [logId, status, notes];
}

class SubmitDetailApprovalDecision extends ApprovalEvent {
  final String detailId;
  final String status;

  const SubmitDetailApprovalDecision({
    required this.detailId,
    required this.status,
  });

  @override
  List<Object> get props => [detailId, status];
}
