import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/task_service.dart';
import '../../../widgets/loading_widget.dart';

class TlTaskReviewScreen extends ConsumerStatefulWidget {
  final String taskId;
  const TlTaskReviewScreen({super.key, required this.taskId});

  @override
  ConsumerState<TlTaskReviewScreen> createState() =>
      _TlTaskReviewScreenState();
}

class _TlTaskReviewScreenState extends ConsumerState<TlTaskReviewScreen> {
  Map<String, dynamic>? _task;
  bool _loading = true;
  bool _submitting = false;
  final _remarksCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await TaskService.getById(widget.taskId);
    if (!mounted) return;
    if (res['success'] == true) {
      final d = res['data'];
      if (d is Map) {
        _task = Map<String, dynamic>.from(
            d['data'] is Map ? d['data'] as Map : d);
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _review(String status) async {
    if (_remarksCtrl.text.trim().isEmpty && status != 'APPROVED') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please provide remarks'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _submitting = true);
    try {
    final data = {
      'verificationStatus': status,
      'reviewComment': _remarksCtrl.text.trim(),
      'reworkNotes': status == 'REJECTED' || status == 'REWORK_REQUIRED'
          ? _remarksCtrl.text.trim()
          : '',
    };
    final res = await TaskService.reviewTask(widget.taskId, data);
    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Task reviewed successfully'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message']?.toString() ?? 'Failed'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: _loading
          ? const LoadingWidget(message: 'Loading task...')
          : _task == null
              ? const Center(child: Text('Task not found'))
              : SingleChildScrollView(
                  child: Column(children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(20,
                          MediaQuery.of(context).padding.top + 8, 20, 24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(28),
                            bottomRight: Radius.circular(28)),
                      ),
                      child: Row(children: [
                        GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.arrow_back_rounded,
                                    color: Colors.white, size: 20))),
                        const SizedBox(width: 14),
                        const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Review Task',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800)),
                              Text('Approve, reject, or request rework',
                                  style: TextStyle(
                                      color: Colors.white60, fontSize: 12)),
                            ]),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Task Details',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPri(context))),
                                const SizedBox(height: 14),
                                _detail('Title',
                                    _task!['title']?.toString() ?? ''),
                                _detail('Description',
                                    _task!['description']?.toString() ?? ''),
                                _detail('Assigned To',
                                    _task!['assignedTo']?.toString() ?? ''),
                                _detail('Priority',
                                    _task!['priority']?.toString() ?? 'NORMAL'),
                                _detail('Status',
                                    _task!['status']?.toString() ?? ''),
                                _detail('Progress',
                                    '${_task!['progressPercentage'] ?? 0}%'),
                              ]),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Review Decision',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPri(context))),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _remarksCtrl,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: 'Add remarks (required for reject/rework)',
                                    hintStyle: const TextStyle(fontSize: 13),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface,
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: AppColors.borderC(context))),
                                    contentPadding: const EdgeInsets.all(14),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _submitting
                                          ? null
                                          : () => _review('APPROVED'),
                                      child: Container(
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 14),
                                        decoration: BoxDecoration(
                                          color: AppColors.success,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: _submitting
                                            ? const Center(
                                                child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2)))
                                            : const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.check_circle_rounded,
                                                      color: Colors.white,
                                                      size: 18),
                                                  SizedBox(width: 6),
                                                  Text('Approve',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w700)),
                                                ]),
                                      ),
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 12),
                                Row(children: [
                                  Expanded(
                                    child: GestureDetector(
 onTap: _submitting
                                          ? null
                                          : () => _review('REWORK_REQUIRED'),
                                      child: Container(
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 14),
                                        decoration: BoxDecoration(
                                          color: AppColors.error,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: _submitting
                                            ? const Center(
                                                child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2)))
                                            : const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.cancel_rounded,
                                                      color: Colors.white,
                                                      size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Reject',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w700)),
                                                ]),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
onTap: _submitting
                                          ? null
                                          : () => _review('REJECTED'),
                                      child: Container(
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 14),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: _submitting
                                            ? const Center(
                                                child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2)))
                                            : const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.replay_rounded,
                                                      color: Colors.white,
                                                      size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Rework',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w700)),
                                                ]),
                                      ),
                                    ),
                                  ),
                                ]),
                              ]),
                        ),
                        const SizedBox(height: 24),
                      ]),
                    ),
                  ]),
                ),
    );
  }

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textHi(context),
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPri(context))),
          ),
        ]),
      );
}
