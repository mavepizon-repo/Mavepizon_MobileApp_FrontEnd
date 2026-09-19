import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/file_opener.dart';
import '../../../providers/freelancer_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/freelancer_task_service.dart';
import '../../../services/task_submission_service.dart';
import '../../../widgets/status_badge.dart';

class AdminFreelancerTaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;
  const AdminFreelancerTaskDetailScreen({super.key, required this.taskId});
  @override
  ConsumerState<AdminFreelancerTaskDetailScreen> createState() =>
      _AdminFreelancerTaskDetailScreenState();
}

class _AdminFreelancerTaskDetailScreenState
    extends ConsumerState<AdminFreelancerTaskDetailScreen> {
  dynamic _task;
  dynamic _submission;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await FreelancerTaskService.getById(widget.taskId);
    if (result['success'] == true && result['data'] is Map) {
      _task = result['data'];
    } else {
      _error = result['message'] ?? 'Failed to load task';
    }
    final subResult =
        await TaskSubmissionService.getByFreelancerTaskId(widget.taskId);
    if (subResult['success'] == true &&
        subResult['data'] is Map &&
        subResult['data']['id'] != null) {
      _submission = subResult['data'];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Delete this task?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(adminFreelancerTasksProvider.notifier)
          .delete(widget.taskId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Task Detail'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.adminFreelancerTaskEdit,
              arguments: {'id': widget.taskId},
            ).then((_) => _fetch()),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: _delete,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _error != null
              ? Center(child: Text(_error!))
              : _task == null
                  ? const Center(child: Text('Task not found'))
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color: AppColors.accent,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _DetailCard(task: _task!),
                          const SizedBox(height: 16),
                          _SubmissionView(
                              submission: _submission, loading: _loading),
                        ],
                      ),
                    ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final dynamic task;
  const _DetailCard({required this.task});

  Widget _row(BuildContext context, IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSec(context))),
          ),
          Expanded(
            child: Text(value.isEmpty ? '-' : value,
                style: TextStyle(
                    fontSize: 13, color: AppColors.textPri(context))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(task['orgName']?.toString() ?? '',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPri(context))),
            ),
            StatusBadge(status: task['status']?.toString() ?? ''),
          ]),
          const Divider(height: 24),
          _row(context, Icons.calendar_today_rounded, 'Start Date', _fmt(task['startDate']),
              AppColors.card5),
          _row(context, Icons.event_rounded, 'End Date', _fmt(task['endDate']),
              AppColors.error),
          _row(context, Icons.timelapse_rounded, 'No of Days',
              task['noOfDays']?.toString() ?? '', AppColors.warning),
          _row(context, Icons.category_rounded, 'Domain', task['domain']?.toString() ?? '',
              AppColors.accent),
          _row(context, Icons.apartment_rounded, 'Department',
              task['department']?.toString() ?? '', AppColors.card2),
          _row(context, Icons.groups_rounded, 'No of Students',
              task['noOfStudents']?.toString() ?? '', AppColors.card6),
          if ((task['freelancerNames'] as List? ?? []).isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Assigned Freelancers',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSec(context))),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (task['freelancerNames'] as List)
                  .map((n) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(n.toString(),
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent)),
                      ))
                  .toList(),
            ),
          ],
          if ((task['meetingLink']?.toString() ?? '').isNotEmpty) ...[
            const Divider(height: 24),
            _row(context, Icons.videocam_rounded, 'Meeting Link',
                task['meetingLink']?.toString() ?? '', AppColors.card3),
            _row(context, Icons.email_rounded, 'Meeting Email',
                task['meetingEmail']?.toString() ?? '', AppColors.card2),
            _row(context, Icons.password_rounded, 'Meeting Password',
                task['meetingPassword']?.toString() ?? '', AppColors.warning),
          ],
          if ((task['syllabus']?.toString() ?? '').isNotEmpty) ...[
            const Divider(height: 24),
            _fileRow(context, Icons.menu_book_rounded, 'Syllabus',
                task['syllabus']?.toString() ?? ''),
          ],
        ],
      ),
    );
  }

  Widget _fileRow(BuildContext context, IconData icon, String label,
      String value) {
    final name = fileNameFromUrl(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.card5),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSec(context))),
          ),
          Expanded(
            child: Row(children: [
              Expanded(
                child: Text(name.isEmpty ? '-' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textPri(context))),
              ),
              GestureDetector(
                onTap: () => openFileUrl(context, value),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.download_rounded,
                      color: AppColors.accent, size: 18),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  String _fmt(dynamic d) {
    if (d == null) return '';
    final s = d.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }
}

class _SubmissionView extends StatelessWidget {
  final dynamic submission;
  final bool loading;
  const _SubmissionView({required this.submission, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.assignment_turned_in_rounded,
                size: 18, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Freelancer Submission',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPri(context))),
          ]),
          const Divider(height: 20),
          if (submission == null)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('No submission yet from the freelancer.',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textHi(context),
                      fontWeight: FontWeight.w500)),
            )
          else ...[
            Row(children: [
              Text('Status',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSec(context))),
              const Spacer(),
              StatusBadge(status: submission['status']?.toString() ?? ''),
            ]),
            const SizedBox(height: 12),
            if ((submission['notes']?.toString() ?? '').isNotEmpty) ...[
              Text('Notes',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSec(context))),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.description_rounded,
                      color: AppColors.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        fileNameFromUrl(submission['notes']?.toString()),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textPri(context))),
                  ),
                  GestureDetector(
                    onTap: () =>
                        openFileUrl(context, submission['notes']?.toString()),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.download_rounded,
                          color: AppColors.accent, size: 18),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
            ],
            if ((submission['feedback']?.toString() ?? '').isNotEmpty) ...[
              Text('Feedback',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSec(context))),
              const SizedBox(height: 4),
              Text(submission['feedback'].toString(),
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textPri(context))),
            ],
          ],
        ],
      ),
    );
  }
}
