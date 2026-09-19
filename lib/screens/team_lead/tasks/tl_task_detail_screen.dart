import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/task_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/status_badge.dart';

class TlTaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;
  const TlTaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TlTaskDetailScreen> createState() => _TlTaskDetailScreenState();
}

class _TlTaskDetailScreenState extends ConsumerState<TlTaskDetailScreen> {
  dynamic _task;
  bool _fetchingFromNetwork = false;

  @override
  void initState() {
    super.initState();
    _refreshTask();
  }

  // ? Uses getById() which searches _allList � never crashes on filter
  Future<void> _refreshTask() async {
    if (!mounted) return;

    final prov = ref.read(taskProvider.notifier);

    // First try local cache
    final found = prov.getById(widget.taskId);
    if (found != null) {
      setState(() => _task = found);
      return;
    }

    // Not found locally � fetch from network
    if (_fetchingFromNetwork) return;
    _fetchingFromNetwork = true;

    await prov.fetch();

    if (!mounted) return;
    _fetchingFromNetwork = false;

    final updated = prov.getById(widget.taskId);
    if (updated != null) {
      setState(() => _task = updated);
    }
  }

  Color get _pColor =>
      _task?.priority == 'HIGH' || _task?.priority == 'CRITICAL'
          ? AppColors.error
          : _task?.priority == 'MEDIUM'
              ? AppColors.warning
              : AppColors.success;

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Task'),
        content: const Text('Delete this task permanently?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(taskProvider.notifier).delete(widget.taskId);
      if (mounted) Navigator.pop(context);
    }
  }

  void _edit() {
    Navigator.pushNamed(
      context,
      AppRoutes.tlEditTask,
      arguments: {'taskId': widget.taskId},
    ).then((_) => _refreshTask());
  }

  // --- Review Task ---------------------------------------------
  Future<void> _review() async {
    String verificationStatus = 'APPROVED';
    final commentCtrl = TextEditingController();
    final reworkCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Review Task',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            // Status selector
            Row(children: [
              _reviewBtn('APPROVED', verificationStatus, AppColors.success,
                  () => setS(() => verificationStatus = 'APPROVED')),
              const SizedBox(width: 8),
              _reviewBtn('REJECTED', verificationStatus, AppColors.error,
                  () => setS(() => verificationStatus = 'REJECTED')),
              const SizedBox(width: 8),
              _reviewBtn(
                  'REWORK',
                  verificationStatus == 'REJECTED' ? 'REWORK' : verificationStatus,
                  AppColors.warning,
                  () => setS(() => verificationStatus = 'REJECTED')),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: commentCtrl,
              decoration: InputDecoration(
                hintText: 'Review comment',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            if (verificationStatus == 'REJECTED') ...[
              const SizedBox(height: 8),
              TextField(
                controller: reworkCtrl,
                decoration: InputDecoration(
                  hintText: 'Rework notes',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text('Submit',
                    style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );

    if (ok == true && mounted) {
      await ref.read(taskProvider.notifier).reviewTask(widget.taskId, {
        'verificationStatus': verificationStatus,
        'reviewComment': commentCtrl.text.trim(),
        'pointsDeduction': 0,
        'reworkNotes': reworkCtrl.text.trim(),
      });
      _refreshTask();
    }
  }

  Widget _reviewBtn(
      String label, String current, Color color, VoidCallback onTap) {
    final sel = current == label;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: sel ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : color)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_task == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)])),
          child: SafeArea(
            child: Column(children: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white)),
              const Expanded(
                  child: Center(
                      child: CircularProgressIndicator(color: Colors.white))),
            ]),
          ),
        ),
      );
    }

    final canReview = _task.status == 'WAITING_FOR_REVIEW';

    return Scaffold(
      
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 8, 20, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 20))),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.more_vert_rounded,
                          color: Colors.white, size: 20)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) {
                    if (v == 'edit') _edit();
                    if (v == 'delete') _delete();
                    if (v == 'review') _review();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_rounded,
                            color: AppColors.accent, size: 18),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ]),
                    ),
                    if (canReview)
                      const PopupMenuItem(
                        value: 'review',
                        child: Row(children: [
                          Icon(Icons.rate_review_rounded,
                              color: AppColors.success, size: 18),
                          SizedBox(width: 10),
                          Text('Review',
                              style: TextStyle(color: AppColors.success)),
                        ]),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline_rounded,
                            color: AppColors.error, size: 18),
                        SizedBox(width: 10),
                        Text('Delete',
                            style: TextStyle(color: AppColors.error)),
                      ]),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 20),
              StatusBadge(status: _task.status),
              const SizedBox(height: 10),
              Text(_task.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Row(children: [
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                        color: _pColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      Icon(Icons.flag_rounded, size: 14, color: _pColor),
                      const SizedBox(width: 4),
                      Text('${_task.priority} Priority',
                          style: TextStyle(
                              color: _pColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ])),
              ]),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _card([
                if (_task.staffName.isNotEmpty)
                  _row(Icons.person_rounded, 'Assigned To', _task.staffName),
                _row(
                    Icons.description_rounded,
                    'Description',
                    _task.description.isNotEmpty
                        ? _task.description
                        : 'No description'),
                _row(
                    Icons.calendar_today_rounded,
                    'Start Date',
                    _task.startDate.toString().length >= 10
                        ? _task.startDate.toString().substring(0, 10)
                        : _task.startDate.toString()),
                _row(
                    Icons.event_rounded,
                    'Due Date',
                    _task.deadline.toString().length >= 10
                        ? _task.deadline.toString().substring(0, 10)
                        : _task.deadline.toString()),
                _row(Icons.bar_chart_rounded, 'Progress', '${_task.progress}%'),
                if (_task.completionDate != null &&
                    _task.completionDate!.isNotEmpty)
                  _row(Icons.check_circle_rounded, 'Completed On',
                      _task.completionDate!.substring(0, 10)),
                if (_task.remarks != null && _task.remarks!.isNotEmpty)
                  _row(Icons.note_rounded, 'Remarks', _task.remarks!),
              ]),
              const SizedBox(height: 16),

              // ? Review button shown when task is waiting for review
              if (canReview)
                GestureDetector(
                  onTap: _review,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rate_review_rounded,
                            color: AppColors.success, size: 20),
                        SizedBox(width: 10),
                        Text('Review This Task',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _card(List<Widget> children) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ]),
      child: Column(children: children));

  Widget _row(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.accent, size: 18)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textHi(context),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPri(context))),
        ])),
      ]));
}
