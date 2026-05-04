import 'package:flutter_bloc/flutter_bloc.dart';
import 'monitoring_event.dart';
import 'monitoring_state.dart';
import '../../data/repositories/monitoring_repository.dart';

class MonitoringBloc extends Bloc<MonitoringEvent, MonitoringState> {
  final MonitoringRepository _monitoringRepository = MonitoringRepository();

  MonitoringBloc() : super(MonitoringInitial()) {
    on<FetchLogs>(_onFetchLogs);
    on<FetchTaskTypes>(_onFetchTaskTypes);
    on<SubmitMonitoring>(_onSubmitMonitoring);
    on<SaveMonitoringLocally>(_onSaveMonitoringLocally);
    on<SyncMonitoringLogs>(_onSyncMonitoringLogs);
    on<FetchPendingLogsCount>(_onFetchPendingLogsCount);
  }

  void _onFetchLogs(FetchLogs event, Emitter<MonitoringState> emit) async {
    emit(MonitoringLoading());
    try {
      final logs = await _monitoringRepository.fetchLogs();
      emit(MonitoringLoaded(logs));
    } catch (e) {
      emit(MonitoringError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onFetchTaskTypes(FetchTaskTypes event, Emitter<MonitoringState> emit) async {
    emit(MonitoringLoading());
    try {
      final taskTypes = await _monitoringRepository.fetchTaskTypes();
      emit(TaskTypesLoaded(taskTypes));
    } catch (e) {
      emit(MonitoringError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onSubmitMonitoring(SubmitMonitoring event, Emitter<MonitoringState> emit) async {
    emit(MonitoringLoading());
    try {
      await _monitoringRepository.submitMonitoring(
        workerName: event.workerName,
        details: event.details,
      );

      emit(const LogCreatedSuccess('Laporan berhasil disubmit!'));
      
      final logs = await _monitoringRepository.fetchLogs();
      emit(MonitoringLoaded(logs));
    } catch (e) {
      emit(MonitoringError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onSaveMonitoringLocally(SaveMonitoringLocally event, Emitter<MonitoringState> emit) async {
    emit(MonitoringLoading());
    try {
      await _monitoringRepository.saveLogLocally(
        workerName: event.workerName,
        details: event.details,
      );
      emit(const LogCreatedSuccess('Laporan disimpan secara lokal.'));
      
      // Update count
      final count = await _monitoringRepository.getPendingLogsCount();
      emit(PendingLogsCountLoaded(count));
    } catch (e) {
      emit(MonitoringError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onFetchPendingLogsCount(FetchPendingLogsCount event, Emitter<MonitoringState> emit) async {
    try {
      final count = await _monitoringRepository.getPendingLogsCount();
      emit(PendingLogsCountLoaded(count));
    } catch (e) {
      // Ignore error for count
    }
  }

  void _onSyncMonitoringLogs(SyncMonitoringLogs event, Emitter<MonitoringState> emit) async {
    emit(SyncingLogs());
    try {
      final pendingLogs = await _monitoringRepository.getPendingLogs();
      
      if (pendingLogs.isEmpty) {
        emit(const SyncSuccess('Tidak ada laporan yang perlu disinkronisasi.'));
        return;
      }

      List<Map<String, dynamic>> reportsToSubmit = [];

      for (var log in pendingLogs) {
        List<Map<String, dynamic>> details = [];
        
        for (var detail in log['details']) {
          String? photoPath = detail['photo_path'];
          
          // If there's a local image and no server photo_path yet, upload it
          if (detail['local_image_path'] != null) {
            try {
              photoPath = await _monitoringRepository.uploadImage(detail['local_image_path']);
            } catch (e) {
              // If image upload fails, we might want to skip this log or try again
              throw Exception('Gagal mengunggah foto untuk ${log['worker_name']}: $e');
            }
          }
          
          details.add({
            'task_type_id': detail['task_type_id'],
            'quantity': detail['quantity'],
            'conditions': detail['conditions'],
            'descriptions': detail['descriptions'],
            'nomor_baris': detail['nomor_baris'],
            'locations': detail['locations'],
            'photo_path': photoPath,
          });
        }
        
        reportsToSubmit.add({
          'worker_name': log['worker_name'],
          'details': details,
          'local_id': log['local_id'], // Keep track to delete later
        });
      }

      // Call bulk API
      await _monitoringRepository.bulkSubmitMonitoring(reportsToSubmit);

      // Delete from local DB
      for (var report in reportsToSubmit) {
        await _monitoringRepository.deleteLocalLog(report['local_id']);
      }

      emit(const SyncSuccess('Sinkronisasi berhasil!'));
      
      // Update count and logs
      final count = await _monitoringRepository.getPendingLogsCount();
      emit(PendingLogsCountLoaded(count));
      
      final logs = await _monitoringRepository.fetchLogs();
      emit(MonitoringLoaded(logs));
      
    } catch (e) {
      emit(MonitoringError('Gagal sinkronisasi: ${e.toString().replaceAll('Exception: ', '')}'));
    }
  }
}
