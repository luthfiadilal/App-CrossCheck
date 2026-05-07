import 'package:flutter_bloc/flutter_bloc.dart';
import 'monitoring_event.dart';
import 'monitoring_state.dart';
import '../../data/repositories/monitoring_repository.dart';

class MonitoringBloc extends Bloc<MonitoringEvent, MonitoringState> {
  final MonitoringRepository _monitoringRepository = MonitoringRepository();

  MonitoringBloc() : super(MonitoringInitial()) {
    on<FetchLogs>(_onFetchLogs);
    on<FetchOfflineLogs>(_onFetchOfflineLogs);
    on<FetchTaskTypes>(_onFetchTaskTypes);
    on<SubmitMonitoring>(_onSubmitMonitoring);
    on<SaveMonitoringLocally>(_onSaveMonitoringLocally);
    on<UpdateMonitoringLocally>(_onUpdateMonitoringLocally);
    on<SyncMonitoringLogs>(_onSyncMonitoringLogs);
    on<FetchPendingLogsCount>(_onFetchPendingLogsCount);
    on<DownloadLogForEdit>(_onDownloadLogForEdit);
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

  void _onFetchOfflineLogs(
    FetchOfflineLogs event,
    Emitter<MonitoringState> emit,
  ) async {
    emit(MonitoringLoading());
    try {
      final logs = await _monitoringRepository.fetchOfflineLogs();
      emit(MonitoringLoaded(logs));
    } catch (e) {
      emit(MonitoringError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onFetchTaskTypes(
    FetchTaskTypes event,
    Emitter<MonitoringState> emit,
  ) async {
    emit(MonitoringLoading());
    try {
      final taskTypes = await _monitoringRepository.fetchTaskTypes();
      emit(TaskTypesLoaded(taskTypes));
    } catch (e) {
      emit(MonitoringError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onSubmitMonitoring(
    SubmitMonitoring event,
    Emitter<MonitoringState> emit,
  ) async {
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

  void _onSaveMonitoringLocally(
    SaveMonitoringLocally event,
    Emitter<MonitoringState> emit,
  ) async {
    emit(MonitoringLoading());
    try {
      await _monitoringRepository.saveLogLocally(
        workerName: event.workerName,
        details: event.details,
        serverLogId: event.serverLogId,
      );
      emit(const LogCreatedSuccess('Laporan disimpan secara lokal.'));

      // Update count
      final count = await _monitoringRepository.getPendingLogsCount();
      emit(PendingLogsCountLoaded(count));
    } catch (e) {
      emit(MonitoringError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onUpdateMonitoringLocally(
    UpdateMonitoringLocally event,
    Emitter<MonitoringState> emit,
  ) async {
    emit(MonitoringLoading());
    try {
      await _monitoringRepository.updateLogLocally(
        localId: event.localId,
        workerName: event.workerName,
        details: event.details,
        serverLogId: event.serverLogId,
      );
      emit(const LogCreatedSuccess('Perubahan laporan berhasil disimpan.'));

      // Update count
      final count = await _monitoringRepository.getPendingLogsCount();
      emit(PendingLogsCountLoaded(count));
    } catch (e) {
      emit(MonitoringError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onFetchPendingLogsCount(
    FetchPendingLogsCount event,
    Emitter<MonitoringState> emit,
  ) async {
    try {
      final count = await _monitoringRepository.getPendingLogsCount();
      emit(PendingLogsCountLoaded(count));
    } catch (e) {
      // Ignore error for count
    }
  }

  void _onSyncMonitoringLogs(
    SyncMonitoringLogs event,
    Emitter<MonitoringState> emit,
  ) async {
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
          List<Map<String, dynamic>> detailPhotos = [];

          if (detail['photos'] != null) {
            for (var photo in (detail['photos'] as List)) {
                String? remotePath;
              try {
                String localPath = photo['image'] ?? photo['photo_path'];
                // Jika sudah berupa URL (dari server), jangan upload lagi
                if (localPath.startsWith('http') || localPath.startsWith('/uploads/')) {
                  remotePath = localPath;
                } else {
                  remotePath = await _monitoringRepository.uploadImage(localPath);
                }
                
                detailPhotos.add({
                  'photo_path': remotePath,
                  'caption': photo['caption'],
                });
              } catch (e) {
                throw Exception(
                  'Gagal mengunggah salah satu foto untuk ${log['worker_name']}: $e',
                );
              }
            }
          }

          details.add({
            'task_type_id': detail['task_type_id'],
            'quantity': detail['quantity'],
            'conditions': detail['conditions'],
            'descriptions': detail['descriptions'],
            'nomor_baris': detail['nomor_baris'],
            'locations': detail['locations'],
            'nama_anggota': detail['nama_anggota'],
            'status_task': detail['status_task'], // Include status (e.g. PENDING or APPROVED)
            'photos': detailPhotos,
          });
        }

        reportsToSubmit.add({
          'log_id': log['log_id'], // Critical for update logic on server
          'worker_name': log['worker_name'],
          'details': details,
          'created_at': log['created_at'],
          'updated_at': log['updated_at'],
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
      emit(
        MonitoringError(
          'Gagal sinkronisasi: ${e.toString().replaceAll('Exception: ', '')}',
        ),
      );
    }
  }

  void _onDownloadLogForEdit(
    DownloadLogForEdit event,
    Emitter<MonitoringState> emit,
  ) async {
    emit(MonitoringLoading());
    try {
      final log = event.log;

      // Convert MonitoringLogModel to local format and download images
      List<Map<String, dynamic>> details = await Future.wait(log.details.map((d) async {
        List<Map<String, dynamic>> photos = await Future.wait(d.photos.map((p) async {
          String localPath = p.photoPath;
          // Jika path dari server, download ke local agar bisa diakses offline
          if (p.photoPath.startsWith('/uploads/') || p.photoPath.startsWith('http')) {
            localPath = await _monitoringRepository.downloadImage(p.photoPath);
          }
          
          return {
            'image': localPath,
            'caption': p.caption,
            'filename': p.filename,
            'size': p.size,
            'mimetype': p.mimetype,
          };
        }).toList());

        return {
          'task_type_id': d.taskTypeId,
          'quantity': d.quantity,
          'conditions': d.condition,
          'descriptions': d.description,
          'nomor_baris': d.nomorBaris,
          'locations': d.location,
          'nama_anggota': d.namaAnggota,
          'status_task': d.statusTask,
          'photos': photos,
        };
      }).toList());

      await _monitoringRepository.saveLogLocally(
        workerName: log.workerName,
        details: details,
        serverLogId: log.id,
        status: log.status,
      );

      emit(
        const LogCreatedSuccess(
          'Laporan berhasil diunduh dan siap untuk diperbaiki secara offline.',
        ),
      );

      final count = await _monitoringRepository.getPendingLogsCount();
      emit(PendingLogsCountLoaded(count));
    } catch (e) {
      emit(MonitoringError('Gagal mendownload laporan: ${e.toString()}'));
    }
  }
}
