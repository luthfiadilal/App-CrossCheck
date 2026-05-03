import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/approval_bloc.dart';
import '../bloc/approval_event.dart';
import '../bloc/approval_state.dart';
import '../../data/models/monitoring_log_model.dart';
import '../../../auth/presentation/widgets/primary_button.dart';

class ApprovalDetailPage extends StatefulWidget {
  final MonitoringLogModel log;

  const ApprovalDetailPage({super.key, required this.log});

  @override
  State<ApprovalDetailPage> createState() => _ApprovalDetailPageState();
}

class _ApprovalDetailPageState extends State<ApprovalDetailPage> {
  final TextEditingController _notesController = TextEditingController();
  late MonitoringLogModel _currentLog;

  @override
  void initState() {
    super.initState();
    _currentLog = widget.log;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _onAction(String status) {
    context.read<ApprovalBloc>().add(
      SubmitApprovalDecision(
        logId: _currentLog.id,
        status: status,
        notes: _notesController.text,
      ),
    );
  }

  void _onDetailAction(String detailId, String status) {
    context.read<ApprovalBloc>().add(
      SubmitDetailApprovalDecision(detailId: detailId, status: status),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        title: const Text('Detail Approval'),
      ),
      body: BlocConsumer<ApprovalBloc, ApprovalState>(
        listener: (context, state) {
          if (state is ApprovalSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.primaryGreen,
              ),
            );
            if (state.message.contains('Keputusan approval berhasil dikirim')) {
              Navigator.pop(context);
            }
          } else if (state is ApprovalError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is ApprovalLoaded) {
            // Update local log data when state refreshes
            setState(() {
              _currentLog = state.pendingLogs.firstWhere(
                (element) => element.id == _currentLog.id,
                orElse: () => _currentLog,
              );
            });
          }
        },
        builder: (context, state) {
          bool allApproved = _currentLog.details.every(
            (d) => d.statusTask == 'APPROVED',
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                const Text(
                  'RINCIAN PEKERJAAN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const Divider(),
                ..._currentLog.details.map(
                  (detail) => _buildDetailItem(detail),
                ),
                const SizedBox(height: 24),
                const Text(
                  'TINDAKAN APPROVAL AKHIR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const Divider(),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan Final (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _onAction('RE-CHECK'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('RE-CHECK'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PrimaryButton(
                        text: 'APPROVE SEMUA',
                        isLoading: state is ApprovalLoading,
                        // Hanya aktif jika semua detail sudah APPROVED
                        onPressed: allApproved
                            ? () => _onAction('APPROVED')
                            : null,
                      ),
                    ),
                  ],
                ),
                if (!allApproved)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '* Setujui semua tugas di atas terlebih dahulu',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildHeaderRow('ID Laporan', _currentLog.id),
          _buildHeaderRow('Nama Pekerja', _currentLog.workerName),
          _buildHeaderRow('Tanggal', _currentLog.date),
          _buildHeaderRow('Status Log', _currentLog.status),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDetailItem(MonitoringDetailModel detail) {
    bool isApproved = detail.statusTask == 'APPROVED';
    bool isRecheck = detail.statusTask == 'RECHECK';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isApproved
              ? Colors.green
              : (isRecheck ? Colors.orange : Colors.grey[300]!),
          width: isApproved || isRecheck ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    detail.taskName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _buildStatusBadge(detail.statusTask),
              ],
            ),
            const SizedBox(height: 8),
            Text('Lokasi: ${detail.location}'),
            Text('Jumlah: ${detail.quantity}'),
            if (detail.description.isNotEmpty)
              Text('Ket: ${detail.description}'),
            const SizedBox(height: 12),
            if (detail.photoPath.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://api.crosscheck.my.id${detail.photoPath}',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isRecheck
                        ? null
                        : () => _onDetailAction(detail.detailId, 'RECHECK'),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('RECHECK'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isApproved
                        ? null
                        : () => _onDetailAction(detail.detailId, 'APPROVED'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('APPROVE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'APPROVED') color = Colors.green;
    if (status == 'RECHECK') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

Color _getConditionColor(String condition) {
  switch (condition) {
    case 'BAIK':
      return Colors.green;
    case 'SEDANG':
      return Colors.orange;
    case 'BURUK':
      return Colors.red;
    default:
      return Colors.grey;
  }
}
