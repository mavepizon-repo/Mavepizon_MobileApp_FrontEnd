import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../core/utils/string_utils.dart';
import '../../../providers/staff_task_provider.dart';
import '../../../routes/app_routes.dart';

class StaffTaskListScreen extends ConsumerStatefulWidget {
  const StaffTaskListScreen({super.key});

  @override
  ConsumerState<StaffTaskListScreen> createState() =>
      _StaffTaskListScreenState();
}

class _StaffTaskListScreenState extends ConsumerState<StaffTaskListScreen> {
  String _staffId = '';
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _staffId = await StorageHelper.getStaffId() ?? '';
    if (mounted && _staffId.isNotEmpty) {
      ref.read(staffTaskProvider.notifier).fetch(_staffId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = ref.watch(staffTaskProvider);
    final tasks = _tabIndex == 0 ? tp.pendingTasks : tp.completedTasks;

    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('My Tasks',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
      ),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            _TabBtn(context, 'Active', 0, tp.pendingTasks.length),
            _TabBtn(context, 'Completed', 1, tp.completedTasks.length),
          ]),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _init,
            color: AppColors.accent,
            child: tp.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accent, strokeWidth: 2))
                : tasks.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.3,
                            child: Center(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.task_alt_rounded,
                                        size: 60,
                                        color: AppColors.textHi(context)
                                            .withOpacity(0.4)),
                                    const SizedBox(height: 16),
                                    Text(
                                        _tabIndex == 0
                                            ? 'No active tasks'
                                            : 'No completed tasks',
                                        style: TextStyle(
                                            color: AppColors.textHi(context))),
                                  ]),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: tasks.length,
                        itemBuilder: (ctx, i) {
                          final t = tasks[i];
                          return _TaskCard(
                            task: t,
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.staffTaskDetail,
                                arguments: {
                                  'taskId': t['taskId']?.toString() ?? t['id']?.toString() ?? ''
                                }),
                          );
                        },
                      ),
          ),
        ),
      ]),
    );
  }

  Widget _TabBtn(BuildContext context, String label, int index, int count) {
    final selected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : AppColors.textSec(context))),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withOpacity(0.2)
                        : AppColors.textHi(context).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$count',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : AppColors.textHi(context))),
                ),
              ]),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final dynamic task;
  final VoidCallback onTap;
  const _TaskCard({required this.task, required this.onTap});

  String get _title => task['title']?.toString() ?? 'Untitled';
  String get _status => task['status']?.toString().toUpperCase() ?? 'PENDING';
  String get _deadline =>
      truncate(task['deadline']?.toString() ?? task['dueDate']?.toString(), 10);
  int get _progress => task['progress'] ?? 0;

  Color get _statusColor {
    switch (_status) {
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
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ]),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(children: [
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(_title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPri(context))),
                  if (_deadline.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('Due: $_deadline',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textHi(context))),
                  ]
                ])),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_status.replaceAll('_', ' '),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor)),
            ),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress / 100,
              
              valueColor:
                  AlwaysStoppedAnimation<Color>(_statusColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Align(
              alignment: Alignment.centerRight,
              child: Text('$_progress%',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSec(context)))),
        ]),
      ),
    );
  }
}
