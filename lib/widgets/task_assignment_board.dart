import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/pagination_data.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../services/freelancer_task_service.dart';
import '../services/admin_team_lead_service.dart';
import '../services/admin_staff_service.dart';
import 'status_badge.dart';

/// Reusable filterable "Task Assignments" board.
///
/// - [isAdmin] = true  -> shows Team Lead / Office Staff / Freelancer
/// - [isAdmin] = false -> shows Office Staff only (Team Lead view)
///
/// Supports search by name/title, status filter and category filter.
class TaskAssignmentBoard extends StatefulWidget {
  final bool isAdmin;
  const TaskAssignmentBoard({super.key, required this.isAdmin});

  @override
  State<TaskAssignmentBoard> createState() => _TaskAssignmentBoardState();
}

class _Person {
  final String name;
  final String category;
  final String role;
  final List<_Task> tasks;
  _Person({required this.name, required this.category, this.role = '', List<_Task>? tasks})
      : tasks = tasks ?? [];
}

class _Task {
  final String id;
  final String title;
  final String status;
  final String deadline;
  final String priority;
  _Task({
    required this.id,
    required this.title,
    required this.status,
    this.deadline = '',
    this.priority = 'MEDIUM',
  });
}

class _TaskAssignmentBoardState extends State<TaskAssignmentBoard> {
  bool _loading = true;
  String? _error;
  List<_Person> _people = [];

  final Map<String, _Person> _map = {};
  final Set<String> _statuses = {};
  String _query = '';
  String _status = 'ALL';
  String _category = 'ALL';

  static const _statusOptions = [
    'ASSIGNED',
    'IN_PROGRESS',
    'WAITING_FOR_REVIEW',
    'COMPLETED',
    'PENDING',
    'REWORK_REQUIRED',
    'REJECTED',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _addTask(_Person person, _Task task) {
    final key = person.name.trim().toLowerCase();
    final existing = _map[key];
    if (existing != null) {
      existing.tasks.add(task);
    } else {
      _map[key] = person..tasks.add(task);
    }
    _statuses.add(task.status.toUpperCase());
    if (task.status.toUpperCase() == 'ONGOING') _statuses.add('ONGOING');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    _map.clear();
    _statuses.clear();

    try {
      if (widget.isAdmin) {
        await _loadAdmin();
      } else {
        await _loadTeamLead();
      }

      if (!mounted) return;
      setState(() {
        _people = _map.values.toList()
          ..sort((a, b) {
            const order = {
              'TEAM_LEAD': 0,
              'OFFICE_STAFF': 1,
              'FREELANCER': 2,
            };
            final ca = order[a.category] ?? 9;
            final cb = order[b.category] ?? 9;
            if (ca != cb) return ca.compareTo(cb);
            return a.name.compareTo(b.name);
          });
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load assignments: $e';
      });
    }
  }

  Future<void> _loadAdmin() async {
    // Team leads + office staff name/id maps for categorization.
    final tlNames = <String>{};
    final tlIds = <String>{};
    try {
      final tlRes = await AdminTeamLeadService.getAll(size: 500);
      if (tlRes['success'] == true) {
        for (final e in PaginationData.parse(tlRes['data']).content) {
          final m = Map<String, dynamic>.from(e as Map);
          final id = m['id']?.toString() ?? '';
          final name = m['name']?.toString() ?? m['fullName']?.toString() ?? '';
          if (id.isNotEmpty) tlIds.add(id);
          if (name.isNotEmpty) tlNames.add(name);
        }
      }
    } catch (_) {}

    // Office staff id -> category (role) map.
    final staffRoles = <String, String>{};
    try {
      final stRes = await AdminStaffService.getAll(size: 500);
      if (stRes['success'] == true) {
        for (final e in PaginationData.parse(stRes['data']).content) {
          final m = Map<String, dynamic>.from(e as Map);
          final id = m['id']?.toString() ?? '';
          final role = m['role']?.toString() ?? m['category']?.toString() ?? '';
          if (id.isNotEmpty) staffRoles[id] = role;
        }
      }
    } catch (_) {}

    // Office-staff / team-lead tasks.
    final taskRes = await TaskService.getAllTasks();
    if (taskRes['success'] == true && taskRes['data'] is List) {
      for (final e in taskRes['data'] as List) {
        final t = TaskModel.fromJson(Map<String, dynamic>.from(e as Map));
        final name = t.staffName.isNotEmpty ? t.staffName : t.teamLeadName;
        if (name.isEmpty) continue;
        final isTL = tlIds.contains(t.staffId) || tlNames.contains(name);
        _addTask(
          _Person(
            name: name,
            category: isTL ? 'TEAM_LEAD' : 'OFFICE_STAFF',
            role: isTL
                ? 'Team Lead'
                : (t.staffRole.isNotEmpty ? t.staffRole : 'Office Staff'),
          ),
          _Task(
            id: t.id,
            title: t.title,
            status: t.status,
            deadline: t.deadline.length >= 10 ? t.deadline.substring(0, 10) : t.deadline,
            priority: t.priority,
          ),
        );
      }
    }

    // Freelancer tasks -> one row per freelancer.
    final flRes = await FreelancerTaskService.getAll(size: 500);
    if (flRes['success'] == true) {
      for (final e in PaginationData.parse(flRes['data']).content) {
        final m = Map<String, dynamic>.from(e as Map);
        final names = (m['freelancerNames'] as List? ?? [])
            .map((n) => n.toString())
            .where((n) => n.isNotEmpty)
            .toList();
        if (names.isEmpty) continue;
        final title = m['orgName']?.toString() ?? 'Freelancer Task';
        final status = m['status']?.toString() ?? 'PENDING';
        final endDate = m['endDate']?.toString() ?? '';
        for (final name in names) {
          _addTask(
            _Person(name: name, category: 'FREELANCER', role: 'Freelancer'),
            _Task(
              id: m['id']?.toString() ?? '',
              title: title,
              status: status,
              deadline: endDate.length >= 10 ? endDate.substring(0, 10) : endDate,
              priority: 'MEDIUM',
            ),
          );
        }
      }
    }
  }

  Future<void> _loadTeamLead() async {
    final taskRes = await TaskService.getAll();
    if (taskRes['success'] == true && taskRes['data'] is List) {
      for (final e in taskRes['data'] as List) {
        final t = TaskModel.fromJson(Map<String, dynamic>.from(e as Map));
        final name = t.staffName.isNotEmpty ? t.staffName : 'Unassigned';
        _addTask(
          _Person(
            name: name,
            category: 'OFFICE_STAFF',
            role: t.staffRole.isNotEmpty ? t.staffRole : 'Office Staff',
          ),
          _Task(
            id: t.id,
            title: t.title,
            status: t.status,
            deadline: t.deadline.length >= 10 ? t.deadline.substring(0, 10) : t.deadline,
            priority: t.priority,
          ),
        );
      }
    }
  }

  List<_Person> get _filtered {
    final q = _query.trim().toLowerCase();
    final cats = widget.isAdmin
        ? <String>['TEAM_LEAD', 'OFFICE_STAFF', 'FREELANCER']
        : <String>['OFFICE_STAFF'];

    return _people.where((p) {
      if (!cats.contains(p.category)) return false;
      if (_category != 'ALL' && p.category != _category) return false;
      final nameMatch = q.isEmpty || p.name.toLowerCase().contains(q);
      final taskMatch = q.isEmpty ||
          p.tasks.any((t) => t.title.toLowerCase().contains(q));
      if (!nameMatch && !taskMatch) return false;
      if (_status != 'ALL') {
        if (!p.tasks.any((t) => t.status.toUpperCase() == _status)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.people_alt_rounded,
                color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text('Task Assignments',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPri(context))),
            const Spacer(),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.refresh_rounded,
                    size: 18, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderC(context)),
          ),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search by name or task...',
              hintStyle: TextStyle(
                  fontSize: 13, color: AppColors.textHi(context)),
              prefixIcon: Icon(Icons.search_rounded,
                  size: 20, color: AppColors.textHi(context)),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _query = ''),
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Category chips (admin only)
        if (widget.isAdmin) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _chip(context, 'All', 'ALL', _category, (v) {
                setState(() => _category = v);
              }, icon: Icons.all_inclusive_rounded),
              _chip(context, 'Team Lead', 'TEAM_LEAD', _category, (v) {
                setState(() => _category = v);
              }, icon: Icons.supervisor_account_rounded),
              _chip(context, 'Office Staff', 'OFFICE_STAFF', _category, (v) {
                setState(() => _category = v);
              }, icon: Icons.badge_rounded),
              _chip(context, 'Freelancer', 'FREELANCER', _category, (v) {
                setState(() => _category = v);
              }, icon: Icons.person_pin_rounded),
            ]),
          ),
          const SizedBox(height: 10),
        ],

        // Status chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _chip(context, 'All', 'ALL', _status, (v) {
              setState(() => _status = v);
            }),
            ..._statusOptions
                .map((s) => _chip(context, s, s, _status, (v) {
                      setState(() => _status = v);
                    })),
            if (_statuses.contains('ONGOING'))
              _chip(context, 'ONGOING', 'ONGOING', _status, (v) {
                setState(() => _status = v);
              }),
          ]),
        ),
        const SizedBox(height: 14),

        // Content
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.accent, strokeWidth: 2)),
          )
        else if (_error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 28),
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.error)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _load,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Retry',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ),
              ),
            ]),
          )
        else if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderC(context)),
            ),
            child: Column(children: [
              Icon(Icons.task_alt_rounded,
                  color: AppColors.textHi(context), size: 32),
              const SizedBox(height: 8),
              Text('No assignments found',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSec(context))),
            ]),
          )
        else
          ...filtered.map((p) => _PersonCard(person: p)),
      ],
    );
  }

  Widget _chip(
    BuildContext context,
    String label,
    String value,
    String current,
    void Function(String) onTap, {
    IconData? icon,
  }) {
    final selected = current == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onTap(selected ? 'ALL' : value),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.borderC(context)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: selected ? Colors.white : AppColors.textSec(context)),
              const SizedBox(width: 5),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color:
                        selected ? Colors.white : AppColors.textSec(context))),
          ]),
        ),
      ),
    );
  }
}

class _PersonCard extends StatefulWidget {
  final _Person person;
  const _PersonCard({required this.person});

  @override
  State<_PersonCard> createState() => _PersonCardState();
}

class _PersonCardState extends State<_PersonCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.person;
    final total = p.tasks.length;
    final completed =
        p.tasks.where((t) => t.status.toUpperCase() == 'COMPLETED').length;
    final pending =
        p.tasks.where((t) => t.status.toUpperCase() == 'PENDING').length;
    final inProgress = p.tasks.where((t) =>
        t.status.toUpperCase() == 'IN_PROGRESS' ||
        t.status.toUpperCase() == 'ASSIGNED' ||
        t.status.toUpperCase() == 'ONGOING' ||
        t.status.toUpperCase() == 'WAITING_FOR_REVIEW').length;

    Color catColor() {
      switch (p.category[0]) {
        case 'T':
          return AppColors.card2;
        case 'O':
          return AppColors.card1;
        default:
          return AppColors.card6;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(children: [
        // Header
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: catColor().withOpacity(0.12),
                child: Text(
                  p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: catColor()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPri(context))),
                      const SizedBox(height: 2),
                      Text(
                        p.role.isEmpty ? p.category.replaceAll('_', ' ') : p.role,
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSec(context)),
                      ),
                    ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('$total tasks',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPri(context))),
                const SizedBox(height: 2),
                Text(
                  '$completed done · $inProgress active · $pending pending',
                  style: TextStyle(
                      fontSize: 10, color: AppColors.textHi(context)),
                ),
              ]),
              const SizedBox(width: 6),
              Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.textHi(context)),
            ]),
          ),
        ),
        if (_expanded) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              ...p.tasks.take(10).map((t) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(children: [
                      Container(
                        width: 3,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _priorityColor(t.priority),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPri(context))),
                              if (t.deadline.isNotEmpty)
                                Text('Due: ${t.deadline}',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textHi(context))),
                            ]),
                      ),
                      StatusBadge(status: t.status, fontSize: 9),
                    ]),
                  )),
              if (p.tasks.length > 10)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('+ ${p.tasks.length - 10} more',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
            ]),
          ),
        ],
      ]),
    );
  }

  Color _priorityColor(String p) {
    switch (p.toUpperCase()) {
      case 'CRITICAL':
        return AppColors.error;
      case 'HIGH':
        return AppColors.warning;
      case 'LOW':
        return AppColors.success;
      default:
        return AppColors.accent;
    }
  }
}