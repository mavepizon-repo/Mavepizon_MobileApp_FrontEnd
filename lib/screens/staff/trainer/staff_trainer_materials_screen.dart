import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../services/trainer_service.dart';

class StaffTrainerMaterialsScreen extends ConsumerStatefulWidget {
  const StaffTrainerMaterialsScreen({super.key});

  @override
  ConsumerState<StaffTrainerMaterialsScreen> createState() =>
      _StaffTrainerMaterialsScreenState();
}

class _StaffTrainerMaterialsScreenState
    extends ConsumerState<StaffTrainerMaterialsScreen> {
  String _staffId = '';
  final _titleCtrl = TextEditingController();
  File? _selectedFile;
  String? _selectedBatchId;
  List<dynamic> _batches = [];
  bool _submitting = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _staffId = await StorageHelper.getStaffId() ?? '';
    final batchResult = await TrainerService.getBatches(_staffId);
    if (mounted) {
      setState(() {
        if (batchResult['success'] == true && batchResult['data'] is List) {
          _batches = batchResult['data'] as List;
          if (_batches.isNotEmpty) {
            _selectedBatchId = _batches.first['batchId']?.toString();
          }
        }
        _loading = false;
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _showSnack('Title is required', AppColors.error);
      return;
    }
    if (_selectedBatchId == null) {
      _showSnack('Please select a batch', AppColors.error);
      return;
    }
    if (_selectedFile == null) {
      _showSnack('Please select a file', AppColors.error);
      return;
    }

    setState(() => _submitting = true);
    final result = await TrainerService.uploadMaterial(
      _staffId,
      _selectedBatchId!,
      _titleCtrl.text.trim(),
      _selectedFile!,
    );
    setState(() => _submitting = false);

    if (mounted) {
      _showSnack(
        result['success'] == true ? 'Material uploaded' : 'Upload failed',
        result['success'] == true ? AppColors.success : AppColors.error,
      );
      if (result['success'] == true) {
        _titleCtrl.clear();
        setState(() => _selectedFile = null);
      }
    }
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Upload Material',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPri(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ]),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select Batch',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPri(context))),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedBatchId,
                        decoration: InputDecoration(
                          hintText: 'Choose batch',
                          hintStyle:
                              TextStyle(color: AppColors.textHi(context)),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _batches.map((b) {
                          final id = b['batchId']?.toString() ?? '';
                                          final name = b['batchName']?.toString() ?? b['batchCode']?.toString() ?? 'Batch $id';
                          return DropdownMenuItem(
                            value: id,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => _selectedBatchId = v),
                      ),
                      const SizedBox(height: 18),
                      Text('Material Title',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPri(context))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Week 1 - Introduction',
                          hintStyle:
                              TextStyle(color: AppColors.textHi(context)),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.accent, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text('File',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPri(context))),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.textHi(context).withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.attach_file,
                                color: AppColors.accent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedFile != null
                                    ? _selectedFile!.path
                                        .split('\\')
                                        .last
                                        .split('/')
                                        .last
                                    : 'Tap to select file',
                                style: TextStyle(
                                  color: _selectedFile != null
                                      ? AppColors.textPri(context)
                                      : AppColors.textHi(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Upload Material',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ]),
              ),
            ),
    );
  }
}