import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../services/trainer_service.dart';
import '../../../routes/app_routes.dart';

class StaffTrainerBatchDetailScreen extends ConsumerStatefulWidget {
  final String batchId;
  final String batchName;
  final String zoomLink;
  const StaffTrainerBatchDetailScreen(
      {super.key, required this.batchId, this.batchName = '', this.zoomLink = ''});

  @override
  ConsumerState<StaffTrainerBatchDetailScreen> createState() =>
      _StaffTrainerBatchDetailScreenState();
}

class _StaffTrainerBatchDetailScreenState
    extends ConsumerState<StaffTrainerBatchDetailScreen> {
  String _staffId = '';
  List<dynamic> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _staffId = await StorageHelper.getStaffId() ?? '';
    if (mounted && _staffId.isNotEmpty) await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await TrainerService.getBatchStudents(
          _staffId, widget.batchId);
      if (result['success'] == true) {
        final data = result['data'];
        _students = data is Map && data['students'] is List
            ? data['students'] as List
            : data is List
                ? data
                : [];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load batch details: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
            widget.batchName.isNotEmpty ? widget.batchName : 'Batch Detail',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPri(context)),
        actions: [
          IconButton(
            icon: Icon(Icons.videocam_rounded,
                color: AppColors.textSec(context)),
            onPressed: _showZoomLink,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.accent, strokeWidth: 2))
          : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ]),
                      child: Column(children: [
                        Row(children: [
                          Expanded(
                            child: _ActionBtn(
                              icon: Icons.check_circle_rounded,
                              label: 'Mark\nAttendance',
                              onTap: () =>
                                  _markAttendance(context),
                            ),
                          ),
                          Expanded(
                            child: _ActionBtn(
                              icon: Icons.upload_file_rounded,
                              label: 'Upload\nMaterial',
                              onTap: () =>
                                  Navigator.pushNamed(context,
                                      AppRoutes.trainerMaterials,
                                      arguments: {
                                        'batchId': widget.batchId
                                      }),
                            ),
                          ),
                          Expanded(
                            child: _ActionBtn(
                              icon: Icons.videocam_rounded,
                              label: 'Zoom\nLink',
                              onTap: _showZoomLink,
                            ),
                          ),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    Text('Students',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPri(context))),
                    const SizedBox(height: 12),
                    if (_students.isNotEmpty)
                      ..._students.map((s) =>
                          Container(
                            margin:
                                const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius:
                                    BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black
                                          .withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2))
                                ]),
                            child: Row(children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.accent
                                      .withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Center(
                                    child: Text(
                                        s['studentName']
                                                ?.toString()
                                                .substring(0, 1)
                                                .toUpperCase() ??
                                            '?',
                                        style: const TextStyle(
                                            color:
                                                AppColors.accent,
                                            fontWeight:
                                                FontWeight.w700))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                    s['studentName']
                                            ?.toString() ??
                                        'Unknown',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            AppColors.textPri(context))),
                              ),
                              Icon(Icons.check_circle_rounded,
                                  size: 20,
                                  color: s['present'] == true
                                      ? AppColors.success
                                      : AppColors.textHi(context)
                                          .withOpacity(0.3)),
                            ]),
                          ))
                    else
                      Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius:
                                  BorderRadius.circular(16)),
                          child: Center(
                              child: Text('No students in this batch',
                                  style: TextStyle(
                                      color:
                                          AppColors.textHi(context))))),
                  ]),
                ),
    );
  }

  void _showZoomLink() {
    final link = widget.zoomLink.isNotEmpty ? widget.zoomLink : '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zoom Link'),
        content: Text(
            link.isNotEmpty ? link : 'No zoom link set'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
        ],
      ),
    );
  }

  void _markAttendance(BuildContext context) async {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No students to mark attendance')),
      );
      return;
    }

    final attendance = <int, bool>{};
    final now = DateTime.now();
    for (final s in _students) {
      final id = s['studentId'] is int
          ? s['studentId'] as int
          : int.tryParse(s['studentId']?.toString() ?? '') ?? 0;
      attendance[id] = false;
    }

    final result = await showDialog<Map<int, bool>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Mark Attendance'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: _students.map<Widget>((s) {
                final name =
                    s['studentName']?.toString() ?? 'Unknown';
                final id = s['studentId'] is int
                    ? s['studentId'] as int
                    : int.tryParse(s['studentId']?.toString() ?? '') ?? 0;
                return CheckboxListTile(
                  title: Text(name),
                  value: attendance[id] ?? false,
                  onChanged: (v) {
                    setDialogState(
                        () => attendance[id] = v ?? false);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, attendance),
              child: const Text('Save',
                  style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final response = await TrainerService.markAttendance(
          _staffId, {
        'batchId': int.tryParse(widget.batchId) ?? 0,
        'date': dateStr,
        'students': result.entries
            .map((e) =>
                {'studentId': e.key, 'present': e.value})
            .toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                response['success'] == true
                    ? 'Attendance marked'
                    : 'Failed to mark'),
            backgroundColor: response['success'] == true
                ? AppColors.success
                : AppColors.error,
          ),
        );
        if (response['success'] == true) _load();
      }
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Icon(icon, size: 22, color: AppColors.accent),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSec(context))),
        ]),
      ),
    );
  }
}
