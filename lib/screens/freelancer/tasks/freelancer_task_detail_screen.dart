import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/file_opener.dart';
import '../../../providers/freelancer_provider.dart';
import '../../../services/task_submission_service.dart';
import '../../../widgets/status_badge.dart';

class FreelancerTaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;
  const FreelancerTaskDetailScreen({super.key, required this.taskId});
  @override
  ConsumerState<FreelancerTaskDetailScreen> createState() =>
      _FreelancerTaskDetailScreenState();
}

class _FreelancerTaskDetailScreenState
    extends ConsumerState<FreelancerTaskDetailScreen> {
  dynamic _task;
  bool _loading = true;
  String? _error;

  // Submission
  dynamic _submission;
  String _selectedStatus = 'ONGOING';
  final _notesCtrl = TextEditingController();
  final _feedbackCtrl = TextEditingController();
  File? _notesFile;
  String? _existingNotesUrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    // The freelancer's task data comes from /api/freelancer/mytasks
    // (the backend has no freelancer-side single-task endpoint).
    final p = ref.read(freelancerTasksProvider);
    if (p.tasks.isEmpty) {
      await p.fetchMyTasks();
    }
    final task = p.tasks.where((t) => t.id == widget.taskId).firstOrNull;
    if (task != null) {
      _task = task.toJson();
    } else {
      _error = 'Task not found';
    }
    // load existing submission
    final subResult =
        await TaskSubmissionService.getByFreelancerTaskId(widget.taskId);
    if (subResult['success'] == true && subResult['data'] is Map) {
      _submission = subResult['data'];
      _selectedStatus = _submission['status']?.toString() ?? 'ONGOING';
      _notesCtrl.text = _submission['notes']?.toString() ?? '';
      _feedbackCtrl.text = _submission['feedback']?.toString() ?? '';
      if (_submission['notes'] != null &&
          _submission['notes'].toString().isNotEmpty) {
        _existingNotesUrl = _submission['notes'].toString();
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickNotes() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) setState(() => _notesFile = File(path));
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final body = {
      'freelancerTaskId': widget.taskId,
      'status': _selectedStatus,
      'feedback': _feedbackCtrl.text.trim(),
      if (_notesFile != null) 'notesFile': _notesFile,
    };

    Map<String, dynamic> result;
    if (_submission != null && (_submission['id']?.toString() ?? '') != '') {
      result = await TaskSubmissionService.update(
          _submission['id'].toString(), body);
    } else {
      result = await TaskSubmissionService.create(body);
    }
    setState(() => _submitting = false);

    if (!mounted) return;
    if (result['success'] == true) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Task submission saved successfully')));
      await ref.read(freelancerTasksProvider.notifier).fetchMyTasks();
      _fetch();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? 'Failed to submit')));
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
                          _SubmissionCard(
                            selectedStatus: _selectedStatus,
                            onStatusChange: (s) =>
                                setState(() => _selectedStatus = s),
                            feedbackCtrl: _feedbackCtrl,
                            submitting: _submitting,
                            onSubmit: _submit,
                            existing: _submission != null,
                            notesFile: _notesFile,
                            existingNotesUrl: _existingNotesUrl,
                            onPickNotes: _pickNotes,
                          ),
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
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
          _row(context, Icons.calendar_today_rounded, 'Start Date',
              _fmt(task['startDate']), AppColors.card5),
          _row(context, Icons.event_rounded, 'End Date', _fmt(task['endDate']),
              AppColors.error),
          _row(context, Icons.timelapse_rounded, 'No of Days',
              task['noOfDays']?.toString() ?? '', AppColors.warning),
          _row(context, Icons.category_rounded, 'Domain',
              task['domain']?.toString() ?? '', AppColors.accent),
          _row(context, Icons.apartment_rounded, 'Department',
              task['department']?.toString() ?? '', AppColors.card2),
          _row(context, Icons.groups_rounded, 'No of Students',
              task['noOfStudents']?.toString() ?? '', AppColors.card6),
          if ((task['meetingLink']?.toString() ?? '').isNotEmpty)
            _row(context, Icons.video_call_rounded, 'Meeting Link',
                task['meetingLink']?.toString() ?? '', AppColors.accent),
          if ((task['meetingEmail']?.toString() ?? '').isNotEmpty)
            _row(context, Icons.email_rounded, 'Meeting Email',
                task['meetingEmail']?.toString() ?? '', AppColors.card3),
          if ((task['syllabus']?.toString() ?? '').isNotEmpty)
            _fileRow(context, Icons.menu_book_rounded, 'Syllabus',
                task['syllabus']?.toString() ?? ''),
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

class _SubmissionCard extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onStatusChange;
  final TextEditingController feedbackCtrl;
  final bool submitting;
  final VoidCallback onSubmit;
  final bool existing;
  final File? notesFile;
  final String? existingNotesUrl;
  final VoidCallback onPickNotes;

  const _SubmissionCard({
    required this.selectedStatus,
    required this.onStatusChange,
    required this.feedbackCtrl,
    required this.submitting,
    required this.onSubmit,
    required this.existing,
    this.notesFile,
    this.existingNotesUrl,
    required this.onPickNotes,
  });

  @override
  Widget build(BuildContext context) {
    const statuses = ['PENDING', 'ONGOING', 'COMPLETED', 'CANCELLED'];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(existing ? 'Update Submission' : 'Submit Work',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPri(context))),
          const SizedBox(height: 14),
          Text('Status',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSec(context))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: statuses
                .map((s) => ChoiceChip(
                      label: Text(s,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selectedStatus == s
                                  ? Colors.white
                                  : AppColors.textSec(context))),
                      selected: selectedStatus == s,
                      selectedColor: AppColors.primary,
                      
                      onSelected: (_) => onStatusChange(s),
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),
          Text('Notes File',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSec(context))),
          const SizedBox(height: 8),
          InkWell(
            onTap: onPickNotes,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: notesFile != null
                      ? AppColors.accent.withOpacity(0.5)
                      : AppColors.textHi(context).withOpacity(0.2),
                ),
              ),
              child: Row(children: [
                Icon(Icons.upload_file_rounded,
                    color: AppColors.textHi(context), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(
                            notesFile != null
                                ? notesFile!.path
                                    .split(Platform.pathSeparator)
                                    .last
                                : existingNotesUrl != null &&
                                        existingNotesUrl!.isNotEmpty
                                    ? fileNameFromUrl(existingNotesUrl)
                                    : 'Tap to select notes file',
                            style: TextStyle(
                              fontSize: 13,
                              color: notesFile != null
                                  ? AppColors.accent
                                  : AppColors.textHi(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (existingNotesUrl != null &&
                            existingNotesUrl!.isNotEmpty &&
                            notesFile == null)
                          GestureDetector(
                            onTap: () => openFileUrl(context, existingNotesUrl),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.download_rounded,
                                  color: AppColors.accent, size: 16),
                            ),
                          ),
                      ]),
                    ],
                  ),
                ),
                Icon(
                  notesFile != null
                      ? Icons.check_circle_rounded
                      : Icons.file_upload_rounded,
                  color: notesFile != null
                      ? AppColors.success
                      : AppColors.textHi(context),
                  size: 18,
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: feedbackCtrl,
            maxLines: 3,
            decoration:
                _inputDec(context, 'Feedback / Remarks', Icons.feedback_rounded),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: submitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(existing ? 'Update Submission' : 'Submit',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDec(BuildContext context, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textHi(context), size: 20),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
