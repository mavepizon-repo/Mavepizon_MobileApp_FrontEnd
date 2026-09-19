import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/course_model.dart';
import '../../../providers/course_provider.dart';
import '../../../services/course_service.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/status_badge.dart';

class AdminCourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;
  const AdminCourseDetailScreen({super.key, required this.courseId});
  @override
  ConsumerState<AdminCourseDetailScreen> createState() =>
      _AdminCourseDetailScreenState();
}

class _AdminCourseDetailScreenState
    extends ConsumerState<AdminCourseDetailScreen> {
  CourseModel? _course;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await CourseService.getById(widget.courseId);
      if (result['success'] == true) {
        setState(() => _course = CourseModel.fromJson(result['data']));
      } else {
        setState(() => _error = result['message'] ?? 'Failed to load');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleStatus() async {
    if (_course == null) return;
    final newStatus =
        _course!.status.toUpperCase() == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    final ok = await ref
        .read(courseProvider.notifier)
        .toggleStatus(_course!.id.toString(), newStatus);
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Course Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: _course == null
                ? null
                : () => Navigator.pushNamed(
                      context, AppRoutes.adminCourseEdit,
                      arguments: {'courseId': _course!.id}),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _error != null
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Text(_error!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 14)),
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed: _load,
                          child: const Text('Retry'))
                    ]))
              : _course == null
                  ? const Center(child: Text('Not found'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                      _DetailSection(title: 'Basic Info', children: [
                        _DetailRow(
                            label: 'Name', value: _course!.courseName),
                        _DetailRow(
                            label: 'Code', value: _course!.courseCode),
                        _DetailRow(
                            label: 'Batch ID', value: _course!.batchId),
                        _DetailRow(
                            label: 'Status',
                            valueWidget:
                                StatusBadge(status: _course!.status)),
                        _DetailRow(
                            label: 'Duration',
                            value: _course!.duration),
                      ]),
                      const SizedBox(height: 12),
                      _DetailSection(
                          title: 'Schedule & Fees', children: [
                        _DetailRow(
                            label: 'Start Date',
                            value: _course!.startDate),
                        _DetailRow(
                            label: 'End Date',
                            value: _course!.endDate),
                        _DetailRow(
                            label: 'Registration Start',
                            value: _course!.registrationStartDate),
                        _DetailRow(
                            label: 'Registration End',
                            value: _course!.registrationEndDate),
                        _DetailRow(
                            label: 'Total Fees',
                            value:
                                '₹${_course!.totalFees.toStringAsFixed(0)}'),
                        _DetailRow(
                            label: 'Registration Fees',
                            value:
                                '₹${_course!.registrationFees.toStringAsFixed(0)}'),
                      ]),
                      const SizedBox(height: 12),
                      _DetailSection(
                          title: 'Seats', children: [
                        _DetailRow(
                            label: 'Online',
                            value:
                                '${_course!.availableSeatsOnline} / ${_course!.totalSeatsOnline}'),
                        _DetailRow(
                            label: 'Offline',
                            value:
                                '${_course!.availableSeatsOffline} / ${_course!.totalSeatsOffline}'),
                        _DetailRow(
                            label: 'Tirunelveli',
                            value:
                                '${_course!.availableSeatsTirunelveli} / ${_course!.totalSeatsTirunelveli}'),
                        _DetailRow(
                            label: 'Tisaiyanvilai',
                            value:
                                '${_course!.availableSeatsTisaiyanvilai} / ${_course!.totalSeatsTisaiyanvilai}'),
                      ]),
                      const SizedBox(height: 12),
                      _DetailSection(
                          title: 'Additional', children: [
                        _DetailRow(
                            label: 'Created By',
                            value: _course!.createdBy),
                        _DetailRow(
                            label: 'Zoom Link',
                            value: _course!.zoomLink ?? '-'),
                      ]),
                      const SizedBox(height: 12),
                      _DetailSection(
                          title: 'Description', children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                              _course!.description.isNotEmpty
                                  ? _course!.description
                                  : '-',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSec(context))),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _toggleStatus,
                          icon: Icon(
                              _course!.status.toUpperCase() == 'ACTIVE'
                                  ? Icons.close_rounded
                                  : Icons.check_circle_rounded,
                              size: 20),
                          label: Text(
                              _course!.status.toUpperCase() == 'ACTIVE'
                                  ? 'Deactivate Course'
                                  : 'Activate Course',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _course!.status.toUpperCase() == 'ACTIVE'
                                    ? AppColors.error
                                    : AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ])),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _DetailSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPri(context))),
            const SizedBox(height: 12),
            ...children,
          ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final Widget? valueWidget;
  const _DetailRow(
      {required this.label, this.value = '', this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textHi(context))),
            ),
            Expanded(
              child: valueWidget ??
                  Text(value.isNotEmpty ? value : '-',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPri(context))),
            ),
          ]),
    );
  }
}
