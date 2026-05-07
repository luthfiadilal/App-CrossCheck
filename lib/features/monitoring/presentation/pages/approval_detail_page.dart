import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Final RE-CHECK Button
                    Column(
                      children: [
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(
                            side: BorderSide(color: Colors.orange, width: 2),
                          ),
                          child: IconButton(
                            onPressed: () => _onAction('RE-CHECK'),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.orange,
                              size: 30,
                            ),
                            padding: const EdgeInsets.all(16),
                            tooltip: 'Re-Check Semua',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'RE-CHECK',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 48),
                    // Final APPROVE ALL Button
                    Column(
                      children: [
                        Material(
                          color: allApproved
                              ? AppColors.primaryGreen
                              : Colors.grey[200],
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: allApproved
                                ? () => _onAction('APPROVED')
                                : null,
                            icon: Icon(
                              Icons.check,
                              color: allApproved
                                  ? Colors.white
                                  : Colors.grey[400],
                              size: 30,
                            ),
                            padding: const EdgeInsets.all(16),
                            tooltip: 'Setujui Semua',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'APPROVE',
                          style: TextStyle(
                            color: allApproved
                                ? AppColors.primaryGreen
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
          _buildHeaderRow('Nama Mandor', _currentLog.mandorName),
          _buildHeaderRow(
            'Tanggal',
            DateFormat(
              'dd MMM yyyy, HH:mm',
            ).format(DateTime.parse(_currentLog.date).toLocal()),
          ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    if (value.isEmpty || value == 'N/A') return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          const Text(':', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(MonitoringDetailModel detail) {
    bool isApproved = detail.statusTask == 'APPROVED';
    bool isRecheck = detail.statusTask == 'RECHECK';

    return InkWell(
      onTap: () => _showTaskDetail(detail),
      borderRadius: BorderRadius.circular(12),
      child: Card(
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
              _buildDetailRow('Lokasi / Blok', detail.location),
              _buildDetailRow('Nomor Baris', detail.nomorBaris),
              _buildDetailRow('Nama Anggota', detail.namaAnggota),
              _buildDetailRow('Kuantitas', detail.quantity),
              _buildDetailRow(
                'Kondisi',
                detail.condition,
                valueColor: _getConditionColor(detail.condition),
              ),
              if (detail.description.isNotEmpty)
                _buildDetailRow('Deskripsi', detail.description),
              const SizedBox(height: 12),
              if (detail.photos.isNotEmpty)
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: detail.photos.length,
                    itemBuilder: (context, idx) {
                      final photo = detail.photos[idx];
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: GestureDetector(
                                onTap: () => _showFullScreenImage(
                                  'https://api.crosscheck.my.id${photo.photoPath}',
                                  photo.caption,
                                ),
                                child: Image.network(
                                  'https://api.crosscheck.my.id${photo.photoPath}',
                                  height: 100,
                                  width: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                        height: 100,
                                        width: 120,
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            if (photo.caption.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  photo.caption,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Lihat Detail',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppColors.primaryGreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskDetail(MonitoringDetailModel detail) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isApproved = detail.statusTask == 'APPROVED';
            bool isRecheck = detail.statusTask == 'RECHECK';

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
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
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                              _buildStatusBadge(detail.statusTask),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Detail Grid
                          _buildDetailGrid(detail),
                          const SizedBox(height: 32),
                          if (detail.description.isNotEmpty) ...[
                            const Text(
                              'DESKRIPSI / CATATAN',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              detail.description,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                          if (detail.photos.isNotEmpty) ...[
                            const Text(
                              'DOKUMENTASI FOTO',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildImageGallery(detail.photos),
                          ],
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                  // Bottom Actions
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isRecheck
                                ? null
                                : () {
                                    _onDetailAction(detail.detailId, 'RECHECK');
                                    Navigator.pop(context);
                                  },
                            icon: const Icon(Icons.close),
                            label: const Text('RE-CHECK'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isApproved
                                ? null
                                : () {
                                    _onDetailAction(detail.detailId, 'APPROVED');
                                    Navigator.pop(context);
                                  },
                            icon: const Icon(Icons.check),
                            label: const Text('APPROVE'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailGrid(MonitoringDetailModel detail) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _buildGridItem(Icons.location_on_outlined, 'Lokasi', detail.location),
        _buildGridItem(Icons.format_list_numbered, 'Baris', detail.nomorBaris),
        _buildGridItem(Icons.person_outline, 'Anggota', detail.namaAnggota),
        _buildGridItem(Icons.analytics_outlined, 'Kuantitas', detail.quantity),
        _buildGridItem(
          Icons.info_outline,
          'Kondisi',
          detail.condition,
          color: _getConditionColor(detail.condition),
        ),
      ],
    );
  }

  Widget _buildGridItem(IconData icon, String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color ?? Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<MonitoringPhotoModel> photos) {
    return Column(
      children: photos.map((photo) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(
                    'https://api.crosscheck.my.id${photo.photoPath}',
                    photo.caption,
                  ),
                  child: Image.network(
                    'https://api.crosscheck.my.id${photo.photoPath}',
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 250,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              if (photo.caption.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Text(
                    photo.caption,
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
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

  void _showFullScreenImage(String imageUrl, String caption) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.white, size: 50),
                        SizedBox(height: 16),
                        Text('Gagal memuat gambar', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            if (caption.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    caption,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
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
