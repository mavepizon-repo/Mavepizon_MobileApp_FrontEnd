import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/admin_freelancer_provider.dart';
import '../../../providers/freelancer_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/task_submission_service.dart';
import '../../../widgets/pagination_bar.dart';
import '../../../widgets/status_badge.dart';

class AdminFreelancerTaskListScreen extends ConsumerStatefulWidget {
  const AdminFreelancerTaskListScreen({super.key});
  @override
  ConsumerState<AdminFreelancerTaskListScreen> createState() =>
      _AdminFreelancerTaskListScreenState();
}

class _AdminFreelancerTaskListScreenState
    extends ConsumerState<AdminFreelancerTaskListScreen> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = '';
  final Set<String> _submittedTaskIds = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminFreelancerTasksProvider.notifier).fetchAll();
      final fp = ref.read(adminFreelancerProvider);
      if (fp.list.isEmpty) ref.read(adminFreelancerProvider.notifier).fetch();
      _loadSubmissions();
    });
  }

  Future<void> _loadSubmissions() async {
    try {
      final result = await TaskSubmissionService.getAll();
      if (result['success'] == true) {
        final raw = result['data'];
        final list = raw is List
            ? raw
            : (raw is Map && raw['content'] is List
                ? (raw['content'] as List)
                : const <dynamic>[]);
        final ids = list
            .map((s) => (s is Map ? s['freelancerTaskId'] : null)?.toString())
            .whereType<String>()
            .toSet();
        if (mounted) setState(() => _submittedTaskIds.addAll(ids));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(adminFreelancerTasksProvider);
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
        title: const Text('Freelancer Tasks'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.adminFreelancerTaskCreate)
                    .then((_) => p.refresh()),
          ),
        ],
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
                              ref.read(adminFreelancerTasksProvider.notifier).refresh(),
                          color: AppColors.accent,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final t = filtered[i];
                              return GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.adminFreelancerTaskDetail,
                                    arguments: {'id': t.id}).then((_) {
                                  p.refresh();
                                  _loadSubmissions();
                                }),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Expanded(
                                            child: Text(t.orgName,
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color:
                                                        AppColors.textPri(context))),
                                          ),
                                          StatusBadge(status: t.status),
                                          if (_submittedTaskIds.contains(t.id)) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppColors.success
                                                    .withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                        Icons
                                                            .check_circle_rounded,
                                                        size: 11,
                                                        color: AppColors.success),
                                                    SizedBox(width: 3),
                                                    Text('Submitted',
                                                        style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: AppColors
                                                                .success)),
                                                  ]),
                                            ),
                                          ],
                                        ]),
                                        const SizedBox(height: 6),
                                        Row(children: [
                                          _InfoChip(Icons.category_rounded,
                                              t.domain, AppColors.accent),
                                          const SizedBox(width: 8),
                                          _InfoChip(
                                              Icons.apartment_rounded,
                                              t.department,
                                              AppColors.card2),
                                          const SizedBox(width: 8),
                                          _InfoChip(
                                              Icons.groups_rounded,
                                              '${t.noOfStudents} Students',
                                              AppColors.card6),
                                        ]),
                                        const SizedBox(height: 8),
                                        if (t.freelancerNames.isNotEmpty)
                                          Text(
                                            t.freelancerNames.join(' • '),
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSec(context)),
                                          ),
                                      ]),
                                ),
                              );
                            },
                          ),
                        ),
        ),
        PaginationBar(
          data: p.pagination,
          isLoading: p.isLoading,
          onPageChanged: (page) =>
              ref.read(adminFreelancerTasksProvider.notifier).fetchAll(page: page),
        ),
      ]),
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
