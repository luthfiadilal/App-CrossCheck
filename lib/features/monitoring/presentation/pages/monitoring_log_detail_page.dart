import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/monitoring_log_model.dart';
import '../bloc/monitoring_bloc.dart';
import '../bloc/monitoring_event.dart';
import '../bloc/monitoring_state.dart';
import '../widgets/status_badge.dart';

class MonitoringLogDetailPage extends StatelessWidget {
  final MonitoringLogModel log;

  const MonitoringLogDetailPage({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    DateTime logDate = DateTime.parse(log.date).toLocal();
    String formattedDate = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(logDate);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Detail Laporan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocListener<MonitoringBloc, MonitoringState>(
        listener: (context, state) {
          if (state is LogCreatedSuccess &&
              state.message.contains('siap untuk diperbaiki')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.primaryGreen,
              ),
            );
            Navigator.pop(context);
          } else if (state is MonitoringError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, formattedDate),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (log.status == 'RE-CHECK') ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange),
                                SizedBox(width: 8),
                                Text(
                                  'Perlu Perbaikan (RE-CHECK)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Laporan ini perlu diperbaiki. Anda dapat mendownload kembali data ini ke daftar PENDING untuk diedit di lapangan.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                context.read<MonitoringBloc>().add(
                                  DownloadLogForEdit(log),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('Download untuk Edit'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    const Row(
                      children: [
                        Icon(Icons.list_alt, color: AppColors.primaryGreen),
                        SizedBox(width: 8),
                        Text(
                          'DAFTAR TUGAS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...log.details.map(
                      (detail) => _buildDetailCard(context, detail),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String formattedDate) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ID Laporan',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          '#${log.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    StatusBadge(status: log.status),
                  ],
                ),
                const Divider(height: 32),
                _buildHeaderInfo(
                  Icons.person_outline,
                  'Nama Verifikator',
                  log.workerName,
                ),
                const SizedBox(height: 12),
                _buildHeaderInfo(
                  Icons.calendar_today_outlined,
                  'Tanggal',
                  formattedDate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryGreen),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailCard(BuildContext context, MonitoringDetailModel detail) {
    return InkWell(
      onTap: () => _showTaskDetail(context, detail),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
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
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                      _buildTaskStatus(detail.statusTask),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    'Lokasi',
                    detail.location,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.format_list_numbered_outlined,
                    'Nomor Baris',
                    detail.nomorBaris,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.person_pin_outlined,
                    'Nama Anggota',
                    detail.namaAnggota,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.monitor_weight_outlined,
                    'Kuantitas',
                    detail.quantity,
                  ),
                  if (detail.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.description_outlined,
                      'Keterangan',
                      detail.description,
                    ),
                  ],
                ],
              ),
            ),
            if (detail.photos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dokumentasi:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: detail.photos.length,
                        itemBuilder: (context, idx) {
                          final photo = detail.photos[idx];
                          final fullImageUrl =
                              photo.photoPath.startsWith('http')
                              ? photo.photoPath
                              : (photo.photoPath.startsWith('/uploads/')
                                    ? 'https://api.crosscheck.my.id${photo.photoPath}'
                                    : photo
                                          .photoPath); // Handle local path if needed

                          return Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => _showFullScreenImage(
                                    context,
                                    fullImageUrl,
                                    photo.caption,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child:
                                        photo.photoPath.startsWith(
                                              '/uploads/',
                                            ) ||
                                            photo.photoPath.startsWith('http')
                                        ? Image.network(
                                            fullImageUrl,
                                            height: 120,
                                            width: 140,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      height: 120,
                                                      width: 140,
                                                      color: Colors.grey[100],
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                          )
                                        : Image.file(
                                            File(photo.photoPath),
                                            height: 120,
                                            width: 140,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      height: 120,
                                                      width: 140,
                                                      color: Colors.grey[100],
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                          ),
                                  ),
                                ),
                                if (photo.caption.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    photo.caption,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black87,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(
    BuildContext context,
    String imageUrl,
    String caption,
  ) {
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
                child: imageUrl.startsWith('http')
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Gagal memuat gambar',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                      )
                    : Image.file(
                        File(imageUrl),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Gagal memuat gambar',
                                    style: TextStyle(color: Colors.white),
                                  ),
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

  void _showTaskDetail(BuildContext context, MonitoringDetailModel detail) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                          _buildTaskStatus(detail.statusTask),
                        ],
                      ),
                      const SizedBox(height: 24),
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
                        _buildImageGallery(context, detail.photos),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

  Widget _buildGridItem(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
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

  Widget _buildImageGallery(
    BuildContext context,
    List<MonitoringPhotoModel> photos,
  ) {
    return Column(
      children: photos.map((photo) {
        final fullImageUrl = photo.photoPath.startsWith('http')
            ? photo.photoPath
            : (photo.photoPath.startsWith('/uploads/')
                  ? 'https://api.crosscheck.my.id${photo.photoPath}'
                  : photo.photoPath);

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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(
                    context,
                    fullImageUrl,
                    photo.caption,
                  ),
                  child:
                      photo.photoPath.startsWith('/uploads/') ||
                          photo.photoPath.startsWith('http')
                      ? Image.network(
                          fullImageUrl,
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 250,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                      : Image.file(
                          File(photo.photoPath),
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 250,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
                ),
              ),
              if (photo.caption.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontFamily: 'Roboto',
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(color: Colors.grey),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskStatus(String status) {
    Color color = Colors.grey;
    if (status.toUpperCase() == 'APPROVED') color = Colors.green;
    if (status.toUpperCase() == 'RECHECK') color = Colors.orange;
    if (status.toUpperCase() == 'REJECTED') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
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

  Color _getConditionColor(String condition) {
    switch (condition.toUpperCase()) {
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
}
