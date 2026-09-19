import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/string_utils.dart';
import '../../../services/staff_task_service.dart';

class StaffTaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;
  const StaffTaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<StaffTaskDetailScreen> createState() =>
      _StaffTaskDetailScreenState();
}

class _StaffTaskDetailScreenState
    extends ConsumerState<StaffTaskDetailScreen> {
  Map<String, dynamic>? _task;
  bool _loading = true;
  int _progress = 0;
  bool _updating = false;
  final _workDoneCtrl = TextEditingController();
  final _blockersCtrl = TextEditingController();
  final _commentsCtrl = TextEditingController();
  final _attachmentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _workDoneCtrl.dispose();
    _blockersCtrl.dispose();
    _commentsCtrl.dispose();
    _attachmentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await StaffTaskService.getTaskDetail(widget.taskId);
      if (result['success'] == true) {
        final data = result['data'];
        if (data is Map) {
          _task = Map<String, dynamic>.from(data);
          _progress = _task?['progress'] ?? 0;
          if (mounted) setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load task: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _updateProgress() async {
    setState(() => _updating = true);
    final body = {
      'progressPercentage': _progress,
      if (_workDoneCtrl.text.isNotEmpty) 'workDoneToday': _workDoneCtrl.text,
      if (_blockersCtrl.text.isNotEmpty) 'blockers': _blockersCtrl.text,
      if (_commentsCtrl.text.isNotEmpty) 'comments': _commentsCtrl.text,
      if (_attachmentCtrl.text.isNotEmpty) 'attachmentUrl': _attachmentCtrl.text,
      'status': _progress >= 100 ? 'WAITING_FOR_REVIEW' : 'IN_PROGRESS',
    };
    final result = await StaffTaskService.updateProgress(widget.taskId, body);
    if (mounted) {
      final success = result['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Progress updated' : 'Update failed'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      if (success) _load();
    }
    setState(() => _updating = false);
  }

  Future<void> _submitForReview() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit for Review'),
        content: const Text('Mark this task as ready for review?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit',
                  style: TextStyle(color: AppColors.accent))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _updating = true);
    final result = await StaffTaskService.submitTask(widget.taskId);
    if (mounted) {
      final success = result['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Submitted for review' : 'Submit failed'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      if (success) _load();
    }
    setState(() => _updating = false);
  }

  Color _statusColor(String? s) {
    switch (s?.toUpperCase()) {
      case 'COMPLETED':
        return AppColors.success;
      case 'IN_PROGRESS':
        return AppColors.accent;
      case 'REVIEW':
      case 'WAITING_FOR_REVIEW':
        return AppColors.warning;
      case 'REWORK_REQUIRED':
      case 'REJECTED':
        return AppColors.error;
      default:
        return AppColors.textHi(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Task Detail',
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
          : _task == null
              ? const Center(child: Text('Task not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Container(
                      width: double.infinity,
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
                        Row(children: [
                          Expanded(
                            child: Text(
                                _task!['title']?.toString() ?? 'Untitled',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPri(context))),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                      _task!['status']?.toString())
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                                _task!['status']?.toString().toUpperCase() ??
                                    'PENDING',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _statusColor(
                                        _task!['status']?.toString()))),
                          ),
                        ]),
                        if (_task!['description']?.toString().isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 14),
                          Text(
                              _task!['description']?.toString() ?? '',
                              style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: AppColors.textSec(context))),
                        ],
                        const SizedBox(height: 20),
                        _MetaRow('Priority',
                            _task!['priority']?.toString() ?? 'N/A'),
                        const SizedBox(height: 8),
                        _MetaRow(
                            'Due Date',
                            _task!['deadline'] != null
                                ? truncate(_task!['deadline'].toString(), 10)
                                : 'N/A'),
                        const SizedBox(height: 8),
                        _MetaRow('Assigned By',
                            _task!['teamLeadName']?.toString() ?? 'N/A'),
                        const SizedBox(height: 20),
                        Text('Progress',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPri(context))),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _progress / 100,
                            
                            valueColor: AlwaysStoppedAnimation<Color>(
                                _statusColor(
                                    _task!['status']?.toString())),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(),
                              Text('$_progress%',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSec(context))),
                            ]),
                        if (_task!['status']?.toString().toUpperCase() !=
                            'COMPLETED') ...[
                          const SizedBox(height: 16),
                          Row(children: [
                            Text('Update: ',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSec(context))),
                            Expanded(
                              child: Slider(
                                value: _progress.toDouble(),
                                min: 0,
                                max: 100,
                                divisions: 20,
                                activeColor: AppColors.accent,
                                label: '$_progress%',
                                onChanged: (v) =>
                                    setState(() => _progress = v.round()),
                              ),
                            ),
                            Text('$_progress%',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent)),
                          ]),
                          const SizedBox(height: 12),
                          _InputField(label: 'Work Done Today', controller: _workDoneCtrl, maxLines: 2),
                          const SizedBox(height: 10),
                          _InputField(label: 'Blockers', controller: _blockersCtrl, maxLines: 2),
                          const SizedBox(height: 10),
                          _InputField(label: 'Comments', controller: _commentsCtrl, maxLines: 2),
                          const SizedBox(height: 10),
                          _InputField(label: 'Attachment URL', controller: _attachmentCtrl),
                        ],
                      ]),
                    ),
                    if (_task!['status']?.toString().toUpperCase() !=
                        'COMPLETED') ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _updating ? null : _updateProgress,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _updating
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Save Progress',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                      if (_progress >= 100) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _updating ? null : _submitForReview,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              side: const BorderSide(color: AppColors.accent),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Submit for Review',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ],
                  ]),
                ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label, value;
  const _MetaRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Text(label,
            style: TextStyle(
                fontSize: 13, color: AppColors.textSec(context))),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPri(context))),
      ]),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  const _InputField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.borderC(context))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.borderC(context))),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
