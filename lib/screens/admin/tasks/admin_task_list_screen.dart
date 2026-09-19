import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/string_utils.dart';
import '../../../widgets/status_badge.dart';
import '../../../models/task_model.dart';
import '../../../services/task_service.dart';
import '../../../routes/app_routes.dart';

class AdminTaskListScreen extends ConsumerStatefulWidget {
  final String? initialStatus;
  const AdminTaskListScreen({super.key, this.initialStatus});
  @override
  ConsumerState<AdminTaskListScreen> createState() =>
      _AdminTaskListScreenState();
}

class _AdminTaskListScreenState extends ConsumerState<AdminTaskListScreen> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = '';
  List<TaskModel> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatus ?? '';
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = _statusFilter.isNotEmpty ? _statusFilter : null;
      final result = await TaskService.getAllTasks();
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          _tasks = data.map((e) => TaskModel.fromJson(e)).toList();
          if (status != null) {
            _tasks = _tasks.where((t) => t.status.toUpperCase() == status).toList();
          }
        } else {
          _tasks = [];
        }
      } else {
        _error = result['message'] ?? 'Failed to load tasks';
      }
    } catch (e) {
      _error = 'Error: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    var filtered = _tasks.where((t) {
      final q = _searchCtrl.text.toLowerCase();
      if (q.isNotEmpty && !t.title.toLowerCase().contains(q)) return false;
      if (_statusFilter.isNotEmpty &&
          !t.status.toUpperCase().contains(_statusFilter.toUpperCase()))
        return false;
      return true;
    }).toList();

    final statuses = ['ASSIGNED', 'IN_PROGRESS', 'WAITING_FOR_REVIEW', 'REWORK_REQUIRED', 'COMPLETED', 'REJECTED', 'PENDING'];

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Tasks'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () => Navigator.pushNamed(context, AppRoutes.adminAssignTask).then((_) => _fetch()),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by title...',
              prefixIcon:
                  Icon(Icons.search_rounded, color: AppColors.textHi(context)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      })
                  : null,
            ),
          ),
        ),
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _FilterChip(context, 'All', '', _statusFilter, (v) {
                setState(() => _statusFilter = v);
                _fetch();
              }),
              ...statuses.map((s) => _FilterChip(context, s, s, _statusFilter, (v) {
                    setState(() => _statusFilter = v);
                    _fetch();
                  })),
            ]),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : _error != null
                  ? Center(child: Text(_error!))
                  : filtered.isEmpty
                      ? Center(
                          child: Text('No tasks found',
                              style: TextStyle(color: AppColors.textHi(context))))
                      : RefreshIndicator(
                          onRefresh: _fetch,
                          color: AppColors.accent,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final t = filtered[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                        color:
                                            Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(
                                          child: Text(t.title,
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      AppColors.textPri(context))),
                                        ),
                                        StatusBadge(status: t.status),
                                      ]),
                                      const SizedBox(height: 6),
                                      if (t.staffName.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 6),
                                          child: Row(children: [
                                            Icon(Icons.person_rounded,
                                                size: 14,
                                                color: AppColors.textHi(context)),
                                            const SizedBox(width: 4),
                                            Text(t.staffName,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.textSec(context))),
                                          ]),
                                        ),
                                      Row(children: [
                                        _InfoChip(Icons.flag_rounded,
                                            t.priority,
                                            _priorityColor(t.priority)),
                                        const SizedBox(width: 8),
                                        if (t.deadline.isNotEmpty)
                                          _InfoChip(
                                              Icons.event_rounded,
                                              t.deadline.length >= 10
                                                  ? truncate(t.deadline, 10)
                                                  : t.deadline,
                                              AppColors.warning),
                                        const SizedBox(width: 8),
                                        _InfoChip(
                                            Icons.percent_rounded,
                                            '${t.progress}%',
                                            AppColors.accent),
                                      ]),
                                    ]),
                              );
                            },
                          ),
                        ),
        ),
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
        return AppColors.textHi(context);
      default:
        return AppColors.accent;
    }
  }
}

Widget _FilterChip(BuildContext context, String label, String value, String current,
    void Function(String) onSelected) {
  final selected = current == value;
  return Padding(
    padding: const EdgeInsets.only(right: 6),
    child: GestureDetector(
      onTap: () => onSelected(selected ? '' : value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSec(context))),
      ),
    ),
  );
}

Widget _InfoChip(IconData icon, String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ]),
  );
}
