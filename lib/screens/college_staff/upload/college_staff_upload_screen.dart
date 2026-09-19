import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_pkg;
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../services/college_staff_service.dart';

class CollegeStaffUploadScreen extends ConsumerStatefulWidget {
  const CollegeStaffUploadScreen({super.key});

  @override
  ConsumerState<CollegeStaffUploadScreen> createState() =>
      _CollegeStaffUploadScreenState();
}

class _CollegeStaffUploadScreenState
    extends ConsumerState<CollegeStaffUploadScreen> {
  Uint8List? _selectedBytes;
  String? _fileName;
  bool _uploading = false;
  String? _resultMessage;
  bool _success = false;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final picked = result.files.single;
      final bytes = picked.bytes;

      if (bytes == null) {
        setState(() {
          _resultMessage =
              'Could not read the selected file. Please try again.';
          _success = false;
        });
        return;
      }

      setState(() {
        _selectedBytes = bytes;
        _fileName = picked.name;
        _resultMessage = null;
      });
    } catch (_) {
      setState(() {
        _resultMessage =
            'Could not read the selected file. Please try again.';
        _success = false;
      });
    }
  }

  Future<void> _upload() async {
    if (_selectedBytes == null || _fileName == null) {
      setState(() => _resultMessage = 'Please select an Excel file first');
      return;
    }

    setState(() {
      _uploading = true;
      _resultMessage = null;
    });

    final id = await StorageHelper.getCollegeStaffId() ?? '';
    if (id.isEmpty) {
      setState(() {
        _uploading = false;
        _resultMessage = 'Session expired. Please login again.';
        _success = false;
      });
      return;
    }

    final cleaned = _removeDuplicateEmails(_selectedBytes!, _fileName!);
    if (cleaned == null) {
      setState(() {
        _uploading = false;
        _resultMessage =
            'Could not process the Excel file. Please check the file and try again.';
        _success = false;
      });
      return;
    }

    final skippedRows = cleaned.removedRows;
    final result = await CollegeStaffService.uploadStudents(
        cleaned.name, cleaned.bytes);

    if (mounted) {
      setState(() {
        _uploading = false;
        if (result['success'] == true) {
          final data = result['data'];
          if (data is Map) {
            final added = data['studentsAdded']?.toString() ?? '0';
            final college = data['collegeName']?.toString() ?? '';
            _resultMessage = skippedRows > 0
                ? 'Upload successful!\nStudents Added: $added\nCollege: $college\n'
                    '($skippedRows duplicate Email row(s) removed automatically)'
                : 'Upload successful!\nStudents Added: $added\nCollege: $college';
            _success = true;
            _selectedBytes = null;
            _fileName = null;
          } else {
            _resultMessage = skippedRows > 0
                ? 'Upload successful!\n'
                    '($skippedRows duplicate Email row(s) removed automatically)'
                : 'Upload successful!';
            _success = true;
            _selectedBytes = null;
            _fileName = null;
          }
        } else {
          final raw = (result['message']?.toString() ?? '').toLowerCase();
          if (raw.contains('duplicate') ||
              raw.contains('already exists') ||
              raw.contains('constraint')) {
            _resultMessage =
                'Upload failed: this Email is already registered (duplicate).\n'
                'Remove the duplicate Email row(s) from the Excel and try again.';
          } else {
            _resultMessage = result['message']?.toString() ??
                result['error']?.toString() ??
                'Upload failed';
          }
          _success = false;
        }
      });
    }
  }

  ({Uint8List bytes, String name, int removedRows})? _removeDuplicateEmails(
      Uint8List bytes, String originalName) {
    try {
      final excel = excel_pkg.Excel.decodeBytes(bytes);
      final originalSheet = excel.tables.values.isNotEmpty
          ? excel.tables.values.first
          : null;
      if (originalSheet == null) return null;

      final seen = <String>{};
      var removed = 0;
      final newWorkbook = excel_pkg.Excel.createExcel();
      final newSheetName = newWorkbook.getDefaultSheet() ?? 'Sheet1';
      final newSheet = newWorkbook[newSheetName];

      for (var r = 0; r < originalSheet.maxRows; r++) {
        final row = originalSheet.rows[r];
        if (r == 0) {
          _copyRowTo(newSheet, row, r);
          continue;
        }
        if (row.length < 2) {
          _copyRowTo(newSheet, row, r);
          continue;
        }
        final email =
            row[1]?.value?.toString().trim().toLowerCase() ?? '';
        if (email.isNotEmpty && !seen.add(email)) {
          removed++;
          continue;
        }
        _copyRowTo(newSheet, row, r);
      }

      final newBytes = newWorkbook.save();
      if (newBytes == null || newBytes.isEmpty) return null;
      return (
        bytes: Uint8List.fromList(newBytes),
        name: originalName,
        removedRows: removed,
      );
    } catch (_) {
      return null;
    }
  }

  void _copyRowTo(excel_pkg.Sheet sheet, dynamic row, int rowIndex) {
    for (var c = 0; c < row.length; c++) {
      final cell = row[c];
      final value = cell?.value;
      if (value != null) {
        sheet.updateCell(
            excel_pkg.CellIndex.indexByColumnRow(
                columnIndex: c, rowIndex: rowIndex),
            value);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Upload Students'),
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Instructions',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPri(context))),
                  const SizedBox(height: 12),
                  _instruction('Upload an Excel file (.xlsx or .xls)'),
                  _instruction('Columns: Name, Email, Mobile, Department, Gender, Password'),
                  _instruction('First row must be headers (will be skipped)'),
                  _instruction('Student IDs are auto-generated'),
                  _instruction('College name is auto-filled from your profile'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(children: [
                InkWell(
                  onTap: _uploading ? null : _pickFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedBytes != null
                            ? AppColors.success
                            : AppColors.primary.withOpacity(0.3),
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: (_selectedBytes != null
                              ? AppColors.success
                              : AppColors.primary)
                          .withOpacity(0.04),
                    ),
                    child: Column(children: [
                      Icon(
                        _selectedBytes != null
                            ? Icons.check_circle_rounded
                            : Icons.cloud_upload_rounded,
                        size: 48,
                        color: _selectedBytes != null
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _fileName ?? 'Tap to select Excel file',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedBytes != null
                              ? AppColors.success
                              : AppColors.textSec(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_selectedBytes != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tap to change file',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textHi(context)),
                        ),
                      ],
                    ]),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _uploading || _selectedBytes == null
                        ? null
                        : _upload,
                    icon: _uploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.upload_rounded),
                    label: Text(_uploading
                        ? 'Uploading...'
                        : 'Upload Students'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ]),
            ),
            if (_resultMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _success
                      ? AppColors.success.withOpacity(0.08)
                      : Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _success
                        ? AppColors.success.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _resultMessage!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _success ? AppColors.success : Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _instruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('� ',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w800)),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSec(context))),
          ),
        ],
      ),
    );
  }
}
