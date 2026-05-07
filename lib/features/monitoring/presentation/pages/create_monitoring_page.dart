import 'dart:io';
import 'package:crosscheck/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:crosscheck/features/auth/presentation/widgets/primary_button.dart';
import 'package:crosscheck/features/monitoring/data/models/monitoring_log_model.dart';
import 'package:crosscheck/features/monitoring/presentation/pages/qr_scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/task_type_model.dart';
import '../bloc/monitoring_bloc.dart';
import '../bloc/monitoring_event.dart';
import '../bloc/monitoring_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class CreateMonitoringPage extends StatefulWidget {
  final MonitoringLogModel? initialLog;
  const CreateMonitoringPage({super.key, this.initialLog});

  @override
  State<CreateMonitoringPage> createState() => _CreateMonitoringPageState();
}

class _CreateMonitoringPageState extends State<CreateMonitoringPage> {
  final TextEditingController _workerNameController = TextEditingController();

  // Map untuk menyimpan detail yang sudah diisi, key: task_type_id
  final Map<String, Map<String, dynamic>> _filledDetails = {};
  List<TaskTypeModel> _availableTasks = [];

  @override
  void initState() {
    super.initState();
    // Fetch task types saat inisialisasi
    context.read<MonitoringBloc>().add(FetchTaskTypes());

    if (widget.initialLog != null) {
      _workerNameController.text = widget.initialLog!.workerName;
      for (var detail in widget.initialLog!.details) {
        _filledDetails[detail.taskTypeId] = {
          'task_type_id': detail.taskTypeId,
          'task_name': detail.taskName,
          'quantity': detail.quantity,
          'conditions': detail.condition,
          'descriptions': detail.description,
          'nomor_baris': detail.nomorBaris,
          'nama_anggota': detail.namaAnggota,
          'locations': detail.location,
          'status_task': detail.statusTask,
          'photos': detail.photos
              .map((p) => {
                    'image': p.photoPath,
                    'caption': p.caption,
                    'filename': p.filename,
                    'size': p.size,
                    'mimetype': p.mimetype,
                  })
              .toList(),
        };
      }
    } else {
      // Ambil nama user yang login dari AuthBloc
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthSuccess) {
        _workerNameController.text = authState.user.name;
      }
    }
  }

  @override
  void dispose() {
    _workerNameController.dispose();
    super.dispose();
  }

  void _showDetailDialog(TaskTypeModel task) {
    // Parse quantity and unit from existing string if available
    String initialQty = '';
    String initialUnit = 'Hektar';
    if (_filledDetails[task.id]?['quantity'] != null) {
      String fullQty = _filledDetails[task.id]?['quantity'];
      List<String> parts = fullQty.split(' ');
      if (parts.length >= 2) {
        initialQty = parts[0];
        initialUnit = parts.sublist(1).join(' ');
      } else {
        initialQty = fullQty;
      }
    }

    final TextEditingController qController = TextEditingController(
      text: initialQty,
    );
    String selectedUnit = initialUnit;
    final TextEditingController dController = TextEditingController(
      text: _filledDetails[task.id]?['descriptions'] ?? '',
    );
    final TextEditingController lController = TextEditingController(
      text: _filledDetails[task.id]?['locations'] ?? '',
    );
    final TextEditingController nbController = TextEditingController(
      text: _filledDetails[task.id]?['nomor_baris'] ?? '',
    );
    final TextEditingController naController = TextEditingController(
      text: _filledDetails[task.id]?['nama_anggota'] ?? '',
    );
    String selectedCondition = _filledDetails[task.id]?['conditions'] ?? 'BAIK';
    List<Map<String, dynamic>> localPhotos = List<Map<String, dynamic>>.from(
      _filledDetails[task.id]?['photos'] ?? [],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Detail: ${task.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Lokasi / Blok',
                      hintText: 'Scan QR untuk Lokasi',
                      controller: lController,
                      readOnly: true,
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: AppColors.primaryGreen,
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QrScannerPage(),
                            ),
                          );
                          if (result != null && result is String) {
                            setModalState(() {
                              lController.text = result;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Nomor Baris',
                      hintText: 'Contoh: Baris 15',
                      controller: nbController,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Nama Anggota',
                      hintText: 'Contoh: Budi Santoso',
                      controller: naController,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 2,
                          child: CustomTextField(
                            label: 'Kuantitas',
                            hintText: 'Contoh: 20',
                            controller: qController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Satuan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.lightGreen,
                                    width: 1.5,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value:
                                        [
                                          'Hektar',
                                          'Bedeng',
                                          'Tph',
                                          'Pokok',
                                          'Meter',
                                        ].contains(selectedUnit)
                                        ? selectedUnit
                                        : 'Hektar',
                                    isExpanded: true,
                                    items:
                                        [
                                          'Hektar',
                                          'Bedeng',
                                          'Tph',
                                          'Pokok',
                                          'Meter',
                                        ].map((u) {
                                          return DropdownMenuItem(
                                            value: u,
                                            child: Text(u),
                                          );
                                        }).toList(),
                                    onChanged: (val) {
                                      if (val != null)
                                        setModalState(() => selectedUnit = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Kondisi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: selectedCondition,
                      isExpanded: true,
                      items: ['BAIK', 'SEDANG', 'BURUK'].map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null)
                          setModalState(() => selectedCondition = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Deskripsi',
                      hintText: 'Catatan tambahan...',
                      controller: dController,
                    ),
                    const SizedBox(height: 16),
                    // Image Picker Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Dokumentasi (Foto)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.camera,
                              imageQuality: 50,
                              maxWidth: 1024,
                              maxHeight: 1024,
                            );
                            if (image != null) {
                              final file = File(image.path);
                              final size = await file.length();
                              final filename = image.path.split('/').last;
                              setModalState(() {
                                localPhotos.add({
                                  'image': image.path,
                                  'caption': '',
                                  'filename': filename,
                                  'size': size,
                                  'mimetype': 'image/jpeg',
                                });
                              });
                            }
                          },
                          icon: const Icon(Icons.add_a_photo, size: 18),
                          label: const Text('Tambah Foto'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (localPhotos.isEmpty)
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Center(
                          child: Text(
                            'Belum ada foto',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: localPhotos.length,
                        itemBuilder: (context, idx) {
                          final photo = localPhotos[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.lightGreen),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: (photo['image'] ?? photo['photo_path'] ?? '').startsWith('/uploads/') || (photo['image'] ?? photo['photo_path'] ?? '').startsWith('http')
                                      ? Image.network(
                                          (photo['image'] ?? photo['photo_path'] ?? '').startsWith('http')
                                              ? (photo['image'] ?? photo['photo_path'] ?? '')
                                              : 'https://api.crosscheck.my.id${photo['image'] ?? photo['photo_path'] ?? ''}',
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.broken_image, size: 20),
                                          ),
                                        )
                                      : Image.file(
                                          File(photo['image'] ?? photo['photo_path'] ?? ''),
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.broken_image, size: 20),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      hintText: 'Tambah caption...',
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(fontSize: 12),
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                    onChanged: (val) {
                                      photo['caption'] = val;
                                    },
                                    controller:
                                        TextEditingController(
                                            text: photo['caption'],
                                          )
                                          ..selection =
                                              TextSelection.fromPosition(
                                                TextPosition(
                                                  offset:
                                                      (photo['caption']
                                                              as String)
                                                          .length,
                                                ),
                                              ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setModalState(() {
                                      localPhotos.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'SIMPAN DETAIL',
                      onPressed: () {
                        if (qController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kuantitas wajib diisi'),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _filledDetails[task.id] = {
                            'task_type_id': task.id,
                            'task_name': task.name,
                            'quantity': '${qController.text} $selectedUnit',
                            'conditions': selectedCondition,
                            'descriptions': dController.text,
                            'nomor_baris': nbController.text,
                            'nama_anggota': naController.text,
                            'locations': lController.text,
                            'photos': localPhotos,
                            'status_task':
                                'PENDING', // Diubah jadi PENDING karena ada interaksi edit
                          };
                        });

                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onSubmitTotal() {
    if (_workerNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama Pekerja wajib diisi')));
      return;
    }
    if (_filledDetails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal satu tugas harus diisi')),
      );
      return;
    }

    if (widget.initialLog != null &&
        widget.initialLog!.id.startsWith('LOCAL-')) {
      final localId = int.parse(widget.initialLog!.id.split('-').last);
      context.read<MonitoringBloc>().add(
        UpdateMonitoringLocally(
          localId: localId,
          workerName: _workerNameController.text,
          details: _filledDetails.values.map((e) {
            final Map<String, dynamic> detail = Map.from(e);
            detail.remove('task_name');
            return detail;
          }).toList(),
        ),
      );
    } else {
      context.read<MonitoringBloc>().add(
        SaveMonitoringLocally(
          workerName: _workerNameController.text,
          details: _filledDetails.values.map((e) {
            final Map<String, dynamic> detail = Map.from(e);
            detail.remove('task_name');
            return detail;
          }).toList(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        title: Text(
          widget.initialLog != null
              ? 'Edit Verifikasi'
              : 'Buat Verifikasi Baru',
        ),
      ),
      body: BlocConsumer<MonitoringBloc, MonitoringState>(
        listener: (context, state) {
          if (state is TaskTypesLoaded) {
            setState(() {
              _availableTasks = state.taskTypes;
            });
          } else if (state is LogCreatedSuccess) {
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
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  label: 'Nama Verifikator',
                  hintText: 'Masukkan nama karyawan',
                  controller: _workerNameController,
                  prefixIcon: Icons.person_outline,
                  enabled: false, // Nama otomatis dari login
                ),
                const SizedBox(height: 30),
                const Text(
                  'ITEM PEKERJAAN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const Divider(),
                if (state is MonitoringLoading && _availableTasks.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _availableTasks.length,
                    itemBuilder: (context, index) {
                      final task = _availableTasks[index];
                      final isFilled = _filledDetails.containsKey(task.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isFilled
                                ? AppColors.primaryGreen
                                : Colors.grey[300]!,
                            width: isFilled ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          onTap: () => _showDetailDialog(task),
                          title: Text(
                            task.name,
                            style: TextStyle(
                              fontWeight: isFilled
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isFilled
                                  ? AppColors.primaryGreen
                                  : AppColors.black,
                            ),
                          ),
                          subtitle: Text(
                            isFilled
                                ? 'Lokasi: ${_filledDetails[task.id]?['locations']} - Klik untuk Edit'
                                : 'Belum Diisi',
                            style: TextStyle(
                              color: isFilled
                                  ? AppColors.primaryGreen
                                  : Colors.grey,
                            ),
                          ),
                          trailing: isFilled
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primaryGreen,
                                )
                              : const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 40),
                PrimaryButton(
                  text: 'SIMPAN LAPORAN',
                  isLoading:
                      state is MonitoringLoading && _availableTasks.isNotEmpty,
                  onPressed: _onSubmitTotal,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
