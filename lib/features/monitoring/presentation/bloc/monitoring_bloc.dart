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
      
      // Optionally fetch logs again
      final logs = await _monitoringRepository.fetchLogs();
      emit(MonitoringLoaded(logs));
    } catch (e) {
      emit(MonitoringError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
