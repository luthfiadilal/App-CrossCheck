import 'package:flutter_bloc/flutter_bloc.dart';
import 'approval_event.dart';
import 'approval_state.dart';
import '../../data/repositories/monitoring_repository.dart';

class ApprovalBloc extends Bloc<ApprovalEvent, ApprovalState> {
  final MonitoringRepository _monitoringRepository = MonitoringRepository();

  ApprovalBloc() : super(ApprovalInitial()) {
    on<FetchPendingApprovals>(_onFetchPendingApprovals);
    on<SubmitApprovalDecision>(_onSubmitApprovalDecision);
    on<SubmitDetailApprovalDecision>(_onSubmitDetailApprovalDecision);
  }

  void _onFetchPendingApprovals(FetchPendingApprovals event, Emitter<ApprovalState> emit) async {
    emit(ApprovalLoading());
    try {
      final logs = await _monitoringRepository.fetchPendingApprovals();
      emit(ApprovalLoaded(logs));
    } catch (e) {
      emit(ApprovalError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onSubmitDetailApprovalDecision(SubmitDetailApprovalDecision event, Emitter<ApprovalState> emit) async {
    emit(ApprovalLoading());
    try {
      await _monitoringRepository.submitDetailApproval(
        detailId: event.detailId,
        status: event.status,
      );
      emit(ApprovalSuccess('Status tugas berhasil diperbarui ke ${event.status}'));
      
      // Kita perlu me-refresh data pending untuk mendapatkan status terbaru
      final logs = await _monitoringRepository.fetchPendingApprovals();
      emit(ApprovalLoaded(logs));
    } catch (e) {
      emit(ApprovalError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onSubmitApprovalDecision(SubmitApprovalDecision event, Emitter<ApprovalState> emit) async {
    emit(ApprovalLoading());
    try {
      await _monitoringRepository.submitApproval(
        logId: event.logId,
        status: event.status,
        notes: event.notes,
      );
      emit(const ApprovalSuccess('Keputusan approval berhasil dikirim'));
      
      // Refresh list
      final logs = await _monitoringRepository.fetchPendingApprovals();
      emit(ApprovalLoaded(logs));
    } catch (e) {
      emit(ApprovalError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
