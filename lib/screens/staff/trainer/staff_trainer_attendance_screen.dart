import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../services/trainer_service.dart';

class StaffTrainerAttendanceScreen extends ConsumerStatefulWidget {
  final String batchId;
  const StaffTrainerAttendanceScreen({super.key, required this.batchId});

  @override
  ConsumerState<StaffTrainerAttendanceScreen> createState() =>
      _StaffTrainerAttendanceScreenState();
}

class _StaffTrainerAttendanceScreenState
    extends ConsumerState<StaffTrainerAttendanceScreen> {
  String _staffId = '';
  List<dynamic> _students = [];
  Map<String, bool> _attendance = {};
  bool _loading = true;
  bool _submitting = false;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _staffId = await StorageHelper.getStaffId() ?? '';
    if (mounted && _staffId.isNotEmpty) await _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    try {
      final result = await TrainerService.getBatchStudents(
          _staffId, widget.batchId);
      if (result['success'] == true) {
        final data = result['data'];
        final students = data is Map && data['students'] is List
            ? data['students'] as List
            : data is List
                ? data
                : [];
        _students = students;
        _attendance = {};
        for (final s in students) {
          final id = s['studentId']?.toString() ?? s['id']?.toString() ?? '';
          _attendance[id] = false;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load students: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final attendanceList = _attendance.entries
        .map((e) => {
              'studentId': int.tryParse(e.key) ?? 0,
              'present': e.value,
            })
        .toList();
    final data = {
      'courseId': int.tryParse(widget.batchId) ?? 0,
      'date':
          '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
      'students': attendanceList,
    };
    final result = await TrainerService.markAttendance(_staffId, data);
    setState(() => _submitting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] == true
              ? 'Attendance marked'
              : 'Failed to mark attendance'),
          backgroundColor: result['success'] == true
              ? AppColors.success
              : AppColors.error,
        ),
      );
      if (result['success'] == true) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Mark Attendance',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPri(context)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.accent, strokeWidth: 2))
          : _students.isEmpty
              ? const Center(child: Text('No students in this batch'))
              : Column(children: [
                  Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 16, color: AppColors.textSec(context)),
                  const SizedBox(width: 10),
                  Text('Date: ',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSec(context))),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Text(
                        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent)),
                  ),
                ]),
              ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: _students.length,
                      itemBuilder: (ctx, i) {
                        final s = _students[i];
                        final id = s['studentId']?.toString() ??
                            s['id']?.toString() ??
                            '';
                        final name = s['studentName']?.toString() ?? 'Unknown';
                        final present = _attendance[id] ?? false;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: Row(children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: present
                                    ? AppColors.success.withOpacity(0.1)
                                    : Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                  child: Icon(
                                      present
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked_rounded,
                                      size: 20,
                                      color: present
                                          ? AppColors.success
                                          : AppColors.textHi(context))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(name,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPri(context))),
                            ),
                            GestureDetector(
                              onTap: () => setState(
                                  () => _attendance[id] = !present),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: present
                                      ? AppColors.success.withOpacity(0.1)
                                      : AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                    present ? 'PRESENT' : 'ABSENT',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: present
                                            ? AppColors.success
                                            : AppColors.error)),
                              ),
                            ),
                          ]),
                        );
                      },
                    ),
                  ),
                ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitting ? null : _submit,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.check_rounded),
        label: Text(_submitting ? 'Submitting...' : 'Submit Attendance'),
      ),
    );
  }
}