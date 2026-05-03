import 'dart:io';
import 'package:crosscheck/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:crosscheck/features/auth/presentation/widgets/primary_button.dart';
import 'package:crosscheck/features/monitoring/presentation/pages/qr_scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/task_type_model.dart';
import '../bloc/monitoring_bloc.dart';
import '../bloc/monitoring_event.dart';
import '../bloc/monitoring_state.dart';

class CreateMonitoringPage extends StatefulWidget {
  const CreateMonitoringPage({super.key});

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
  }

  @override
  void dispose() {
    _workerNameController.dispose();
    super.dispose();
  }

  void _showDetailDialog(TaskTypeModel task) {
    final TextEditingController qController = TextEditingController(
      text: _filledDetails[task.id]?['quantity'] ?? '',
    );
    final TextEditingController dController = TextEditingController(
      text: _filledDetails[task.id]?['descriptions'] ?? '',
    );
    final TextEditingController lController = TextEditingController(
      text: _filledDetails[task.id]?['locations'] ?? '',
    );
    String selectedCondition = _filledDetails[task.id]?['conditions'] ?? 'BAIK';
    String? localImagePath = _filledDetails[task.id]?['local_image_path'];

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
                      hintText: 'Contoh: Blok A-12',
                      controller: lController,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: AppColors.primaryGreen),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const QrScannerPage()),
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
                      label: 'Kuantitas & Satuan',
                      hintText: 'Contoh: 20 Tandan',
                      controller: qController,
                    ),
                    const SizedBox(height: 16),
                    const Text('Kondisi', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: selectedCondition,
                      isExpanded: true,
                      items: ['BAIK', 'SEDANG', 'BURUK'].map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCondition = val);
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
                    const Text('Foto Bukti', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 50,
                          maxWidth: 1024,
                          maxHeight: 1024,
                        );
                        if (image != null) {
                          setModalState(() {
                            localImagePath = image.path;
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightGreen),
                        ),
                        child: localImagePath != null
                            ? Image.file(File(localImagePath!), fit: BoxFit.cover)
                            : const Icon(Icons.camera_alt, size: 40, color: AppColors.grey),
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'SIMPAN DETAIL',
                      onPressed: () {
                        if (qController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kuantitas wajib diisi')),
                          );
                          return;
                        }

                        setState(() {
                          _filledDetails[task.id] = {
                            'task_type_id': task.id,
                            'task_name': task.name,
                            'quantity': qController.text,
                            'conditions': selectedCondition,
                            'descriptions': dController.text,
                            'locations': lController.text,
                            'photo_path': null, // Will be filled during sync
                            'local_image_path': localImagePath,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama Pekerja wajib diisi')),
      );
      return;
    }
    if (_filledDetails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal satu tugas harus diisi')),
      );
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        title: const Text('Buat Laporan Baru'),
      ),
      body: BlocConsumer<MonitoringBloc, MonitoringState>(
        listener: (context, state) {
          if (state is TaskTypesLoaded) {
            setState(() {
              _availableTasks = state.taskTypes;
            });
          } else if (state is LogCreatedSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.primaryGreen),
            );
            Navigator.pop(context);
          } else if (state is MonitoringError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
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
                  label: 'Nama Pekerja',
                  hintText: 'Masukkan nama pekerja',
                  controller: _workerNameController,
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 30),
                const Text(
                  'DAFTAR TUGAS',
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
                            color: isFilled ? AppColors.primaryGreen : Colors.grey[300]!,
                            width: isFilled ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          onTap: () => _showDetailDialog(task),
                          title: Text(
                            task.name,
                            style: TextStyle(
                              fontWeight: isFilled ? FontWeight.bold : FontWeight.normal,
                              color: isFilled ? AppColors.primaryGreen : AppColors.black,
                            ),
                          ),
                          subtitle: Text(
                            isFilled 
                              ? 'Lokasi: ${_filledDetails[task.id]?['locations']} - Klik untuk Edit' 
                              : 'Belum Diisi',
                            style: TextStyle(color: isFilled ? AppColors.primaryGreen : Colors.grey),
                          ),
                          trailing: isFilled
                              ? const Icon(Icons.check_circle, color: AppColors.primaryGreen)
                              : const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 40),
                PrimaryButton(
                  text: 'SIMPAN LAPORAN',
                  isLoading: state is MonitoringLoading && _availableTasks.isNotEmpty,
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
