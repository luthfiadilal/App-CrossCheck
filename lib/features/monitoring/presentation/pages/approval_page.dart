import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/approval_bloc.dart';
import '../bloc/approval_event.dart';
import '../bloc/approval_state.dart';
import 'approval_detail_page.dart';
import '../../data/models/monitoring_log_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key});

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    context.read<ApprovalBloc>().add(FetchPendingApprovals());
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.primaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                String name = 'User';
                if (state is AuthSuccess) {
                  name = state.user.name;
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, $name!',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Berikut laporan yang perlu Anda tinjau.',
                        style: TextStyle(fontSize: 16, color: AppColors.grey),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
            _buildFilterBar(),
            Expanded(
              child: BlocBuilder<ApprovalBloc, ApprovalState>(
                builder: (context, state) {
                  if (state is ApprovalLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                      ),
                    );
                  } else if (state is ApprovalLoaded) {
                    List<MonitoringLogModel> filteredLogs = state.pendingLogs;

                    if (_selectedDate != null) {
                      String formattedSelected = DateFormat(
                        'yyyy-MM-dd',
                      ).format(_selectedDate!);
                      filteredLogs = state.pendingLogs.where((log) {
                        return log.date.split('T')[0] == formattedSelected;
                      }).toList();
                    }

                    if (filteredLogs.isEmpty) {
                      return _buildEmptyState();
                    }

                    // Kelompokkan log berdasarkan tanggal
                    Map<String, List<MonitoringLogModel>> groupedLogs = {};
                    for (var log in filteredLogs) {
                      String dateKey = log.date.split('T')[0];
                      if (!groupedLogs.containsKey(dateKey)) {
                        groupedLogs[dateKey] = [];
                      }
                      groupedLogs[dateKey]!.add(log);
                    }

                    var sortedDates = groupedLogs.keys.toList()
                      ..sort((a, b) => b.compareTo(a));

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: sortedDates.length,
                      itemBuilder: (context, dateIndex) {
                        String dateStr = sortedDates[dateIndex];
                        DateTime dateObj = DateTime.parse(dateStr);
                        String formattedHeader = DateFormat(
                          'EEEE, d MMMM yyyy',
                          'id_ID',
                        ).format(dateObj);
                        List<MonitoringLogModel> logsForDate =
                            groupedLogs[dateStr]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 16,
                                bottom: 8,
                                left: 4,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: AppColors.primaryGreen,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    formattedHeader,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...logsForDate.map((log) => _buildWorkerCard(log)),
                          ],
                        );
                      },
                    );
                  } else if (state is ApprovalError) {
                    return Center(child: Text(state.message));
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightGreen, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null
                          ? 'Filter Berdasarkan Tanggal'
                          : DateFormat(
                              'd MMMM yyyy',
                              'id_ID',
                            ).format(_selectedDate!),
                      style: TextStyle(
                        color: _selectedDate == null
                            ? AppColors.grey
                            : AppColors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primaryGreen),
                onPressed: () => setState(() => _selectedDate = null),
                tooltip: 'Reset Filter',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedDate == null
                ? 'Semua laporan sudah diproses'
                : 'Tidak ada laporan di tanggal ini',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(MonitoringLogModel log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ApprovalDetailPage(log: log),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.workerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${log.id} • ${log.details.length} Tugas',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
