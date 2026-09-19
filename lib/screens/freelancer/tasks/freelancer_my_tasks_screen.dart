import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/freelancer_provider.dart';
import '../../../widgets/status_badge.dart';
import '../../../models/freelancer_task_model.dart';

class FreelancerMyTasksScreen extends ConsumerStatefulWidget {
  const FreelancerMyTasksScreen({super.key});
  @override
  ConsumerState<FreelancerMyTasksScreen> createState() =>
      _FreelancerMyTasksScreenState();
}

class _FreelancerMyTasksScreenState
    extends ConsumerState<FreelancerMyTasksScreen> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = '';
  bool _statusFromArgs = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(freelancerTasksProvider.notifier).fetchMyTasks());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_statusFromArgs) {
      _statusFromArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['status'] != null) {
        final s = args['status'].toString();
        if (s.isNotEmpty) _statusFilter = s;
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(freelancerTasksProvider);
    final all = p.tasks;

    var filtered = all.where((t) {
      final q = _searchCtrl.text.toLowerCase();
      if (q.isNotEmpty && !t.orgName.toLowerCase().contains(q)) return false;
      if (_statusFilter.isNotEmpty &&
          !t.status.toUpperCase().contains(_statusFilter.toUpperCase()))
        return false;
      return true;
    }).toList();

    const statuses = ['PENDING', 'ONGOING', 'COMPLETED', 'CANCELLED'];

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('My Tasks'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by org name...',
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
              }),
              ...statuses.map((s) => _FilterChip(context, s, s, _statusFilter, (v) {
                    setState(() => _statusFilter = v);
                  })),
            ]),
          ),
        ),
        Expanded(
          child: p.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : p.error != null
                  ? Center(child: Text(p.error!))
                  : filtered.isEmpty
                      ? Center(
                          child: Text('No tasks found',
                              style: TextStyle(color: AppColors.textHi(context))))
                      : RefreshIndicator(
                          onRefresh: () =>
                              ref.read(freelancerTasksProvider.notifier).fetchMyTasks(),
                          color: AppColors.accent,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) =>
                                _TaskCard(task: filtered[i]),
                          ),
                        ),
        ),
      ]),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final FreelancerTaskModel task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/freelancer/task-detail',
          arguments: {'id': task.id}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
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
            Row(children: [
              Expanded(
                child: Text(task.orgName,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPri(context))),
              ),
              StatusBadge(status: task.status),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              _InfoChip(Icons.category_rounded, task.domain, AppColors.accent),
              const SizedBox(width: 8),
              _InfoChip(Icons.apartment_rounded, task.department, AppColors.card2),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              if (task.startDate.isNotEmpty)
                _InfoChip(Icons.event_rounded,
                    task.startDate.length >= 10
                        ? task.startDate.substring(0, 10)
                        : task.startDate,
                    AppColors.card5),
              const SizedBox(width: 8),
              if (task.noOfStudents.isNotEmpty)
                _InfoChip(Icons.groups_rounded,
                    '${task.noOfStudents} Students', AppColors.card6),
            ]),
          ],
        ),
      ),
    );
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
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ]),
  );
}
