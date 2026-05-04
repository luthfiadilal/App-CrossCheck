import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/monitoring_bloc.dart';
import '../bloc/monitoring_event.dart';
import '../bloc/monitoring_state.dart';
import 'create_monitoring_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class MandorHomePage extends StatefulWidget {
  const MandorHomePage({super.key});

  @override
  State<MandorHomePage> createState() => _MandorHomePageState();
}

class _MandorHomePageState extends State<MandorHomePage> {
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    context.read<MonitoringBloc>().add(FetchPendingLogsCount());
    // Pre-fetch task types to cache them for offline use
    context.read<MonitoringBloc>().add(FetchTaskTypes());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MonitoringBloc, MonitoringState>(
      listener: (context, state) {
        if (state is PendingLogsCountLoaded) {
          setState(() => _pendingCount = state.count);
        } else if (state is SyncSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
        } else if (state is MonitoringError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  String name = 'Mandor';
                  if (state is AuthSuccess) {
                    name = state.user.name;
                  }
                  return Text(
                    'Halo, $name!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Siap untuk melaporkan pekerjaan hari ini?',
                style: TextStyle(fontSize: 16, color: AppColors.grey),
              ),
              const SizedBox(height: 48),

              // New Reporting Card
              _buildActionCard(
                icon: Icons.assignment_add,
                iconColor: AppColors.orange,
                title: 'Laporan Baru',
                subtitle:
                    'Mulai input data lokasi, tugas, dan foto pekerjaan yang sedang dilakukan.',
                buttonText: 'Mulai Pekerjaan Baru',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateMonitoringPage(),
                    ),
                  ).then((_) {
                    // Refresh count when back from creation
                    context.read<MonitoringBloc>().add(FetchPendingLogsCount());
                  });
                },
              ),

              const SizedBox(height: 24),

              // Sync Card
              BlocBuilder<MonitoringBloc, MonitoringState>(
                builder: (context, state) {
                  final isSyncing = state is SyncingLogs;

                  return _buildActionCard(
                    icon: Icons.sync,
                    iconColor: AppColors.primaryGreen,
                    title: 'Sinkronisasi Data',
                    subtitle: _pendingCount > 0
                        ? 'Ada $_pendingCount laporan yang belum disinkronisasi ke server.'
                        : 'Semua data sudah tersinkronisasi.',
                    buttonText: isSyncing
                        ? 'Sedang Sinkronisasi...'
                        : 'Sinkronkan Sekarang',
                    isLoading: isSyncing,
                    backgroundColor: AppColors.paleGreen,
                    onPressed: _pendingCount > 0 && !isSyncing
                        ? () => context.read<MonitoringBloc>().add(
                            SyncMonitoringLogs(),
                          )
                        : null,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Color backgroundColor = AppColors.paleYellow,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 64, color: iconColor),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: onPressed == null
                  ? Colors.grey
                  : AppColors.primaryGreen,
              foregroundColor: AppColors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    buttonText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
