import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/task_model.dart';
import '../../../providers/staff_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_widget.dart';
import '../../../widgets/status_badge.dart';

class TlTaskListScreen extends ConsumerStatefulWidget {
  const TlTaskListScreen({super.key});
  @override
  ConsumerState<TlTaskListScreen> createState() => _TlTaskListScreenState();
}

class _TlTaskListScreenState extends ConsumerState<TlTaskListScreen> {
  // ? All real task status values
  final _statuses = [
    'ALL',
    'ASSIGNED',
    'IN_PROGRESS',
    'WAITING_FOR_REVIEW',
    'COMPLETED',
    'PENDING',
    'REWORK_REQUIRED',
    'REJECTED',
  ];

  DateTime? _startDate;
  DateTime? _endDate;
  String? _staffId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null) {
        _staffId = args['staffId'] as String?;
        final statusFilter = args['status'] as String?;
        if (statusFilter != null && statusFilter != 'ALL') {
          ref.read(taskProvider.notifier).setFilter(statusFilter);
        }
      }
      // Load staff list for filter dropdown
      if (ref.read(staffProvider).allStaff.isEmpty) {
        ref.read(staffProvider.notifier).fetch();
      }
      _loadTasks();
    });
  }

  // Load ALL tasks once, then filter client-side.
  Future<void> _loadTasks() async {
    await ref.read(taskProvider.notifier).fetch();
  }

  Future<void> _pickDate(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    if (d != null) {
      setState(() {
        if (isStart) {
          _startDate = d;
        } else {
          _endDate = d;
        }
      });
    }
  }

  void _clearDateFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  String _fmtDate(DateTime? d) => d == null
      ? 'From'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final prov = ref.watch(taskProvider);
    var tasks = prov.list;

    if (_startDate != null || _endDate != null) {
      tasks = tasks.where((t) {
        final d = t.deadline;
        if (d.isEmpty) return false;
        final dd = d.length >= 10 ? d.substring(0, 10) : d;
        if (_startDate != null && dd.compareTo(_startDate!.toIso8601String().substring(0, 10)) < 0) return false;
        if (_endDate != null && dd.compareTo(_endDate!.toIso8601String().substring(0, 10)) > 0) return false;
        return true;
      }).toList();
    }

    if (_staffId != null && _staffId!.isNotEmpty) {
      tasks = tasks.where((t) => t.staffId == _staffId).toList();
    }

    return Scaffold(
      
      body: Column(children: [
        // -- Header --------------------------------------------
        Container(
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 16, 20, 16),
          decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28)),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Tasks',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.tlAssignTask)
                        .then((_) => _loadTasks()),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_task_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ]),
            const SizedBox(height: 14),

            // ? FIX: Status filter pills � switching is instant (client-side)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statuses.map((s) {
                  final sel = prov.filterStatus == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      // ? setFilter() just changes filterStatus and calls
                      // notifyListeners() � no network call needed
                      onTap: () => prov.setFilter(s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel
                              ? Colors.white
                              : Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                            s == 'WAITING_FOR_REVIEW'
                                ? 'REVIEW'
                                : s == 'REWORK_REQUIRED'
                                    ? 'REWORK'
                                    : s,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: sel ? AppColors.primary : Colors.white)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            // Date range filters
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickDate(true),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 16, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(_fmtDate(_startDate),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickDate(false),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.event_rounded,
                          size: 16, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(_fmtDate(_endDate),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ]),
                  ),
                ),
              ),
              if (_startDate != null || _endDate != null)
                GestureDetector(
                  onTap: _clearDateFilters,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white70, size: 16),
                  ),
                ),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Consumer(
                builder: (ctx, ref, _) {
                  final sp = ref.watch(staffProvider);
                  final staffLoaded = sp.allStaff.isNotEmpty;
                  final effectiveValue = (_staffId != null &&
                          staffLoaded &&
                          sp.allStaff.any((s) => s.id == _staffId))
                      ? _staffId
                      : '';
                  return DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: effectiveValue,
                      isExpanded: true,
                      hint: const Text('Filter by Staff',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      icon: const Icon(Icons.arrow_drop_down_rounded,
                          color: Colors.white70),
                      dropdownColor: const Color(0xFF0284C7),
                      items: [
                        const DropdownMenuItem(
                            value: '',
                            child: Text('All Staff',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13))),
                        ...sp.allStaff.map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                            )),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _staffId = val.isEmpty ? null : val;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ]),
        ),

        // Count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            Text('${tasks.length} tasks',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSec(context),
                    fontWeight: FontWeight.w500)),
          ]),
        ),

        Expanded(
          child: ResponsiveCentered(
            child: prov.isLoading
                ? const LoadingWidget(message: 'Loading tasks...')
                : tasks.isEmpty
                    ? EmptyWidget(
                        message: prov.filterStatus == 'ALL'
                            ? 'No tasks found'
                            : 'No ${prov.filterStatus.replaceAll('_', ' ')} tasks',
                        icon: Icons.task_outlined,
                        actionLabel: '+ Assign Task',
                        onAction: () =>
                            Navigator.pushNamed(context, AppRoutes.tlAssignTask))
                    : RefreshIndicator(
                        onRefresh: _loadTasks,
                        color: AppColors.accent,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: tasks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final t = tasks[i];
                            return _TaskCard(
                              task: t,
                              onTap: () => Navigator.pushNamed(
                                      context, AppRoutes.tlTaskDetail,
                                      arguments: {'taskId': t.id})
                                  .then((_) => _loadTasks()),
                            );
                          },
                        ),
                      ),
          ),
        ),
      ]),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  const _TaskCard({required this.task, required this.onTap});

  Color get _pColor => task.priority == 'HIGH' || task.priority == 'CRITICAL'
      ? AppColors.error
      : task.priority == 'MEDIUM'
          ? AppColors.warning
          : AppColors.success;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: _pColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
                child: Text(task.title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPri(context)))),
            StatusBadge(status: task.status),
          ]),

          // ? FIX: Show staff name from 'staffName' field in TaskResponse
          if (task.staffName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                Icon(Icons.person_rounded,
                    size: 14, color: AppColors.textHi(context)),
                const SizedBox(width: 4),
                Text(task.staffName,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textHi(context))),
                if (task.staffRole.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(task.staffRole,
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent))),
                ],
              ]),
            ),

          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSec(context))),
          ],
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.dividerC(context)),
          const SizedBox(height: 12),

          Row(children: [
            // Priority badge
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _pColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: Row(children: [
                  Icon(Icons.flag_rounded, size: 12, color: _pColor),
                  const SizedBox(width: 4),
                  Text(task.priority,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _pColor)),
                ])),

            // Progress indicator
            if (task.progress > 0) ...[
              const SizedBox(width: 8),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('${task.progress}%',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent))),
            ],

            const Spacer(),
            Icon(Icons.calendar_today_rounded,
                size: 13, color: AppColors.textHi(context)),
            const SizedBox(width: 4),
            Text(
                // ? Use 'deadline' field from TaskResponse
                'Due: ${task.deadline.length >= 10 ? task.deadline.substring(0, 10) : task.deadline}',
                style:
                    TextStyle(fontSize: 12, color: AppColors.textHi(context))),
          ]),
        ]),
      ),
    );
  }
}
