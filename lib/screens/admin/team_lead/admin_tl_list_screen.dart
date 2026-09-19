import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/admin_team_lead_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/status_badge.dart';

class AdminTlListScreen extends ConsumerStatefulWidget {
  const AdminTlListScreen({super.key});
  @override
  ConsumerState<AdminTlListScreen> createState() => _AdminTlListScreenState();
}

class _AdminTlListScreenState extends ConsumerState<AdminTlListScreen> {
  final _searchCtrl = TextEditingController();
  String _roleFilter = '';
  String _monthFilter = '';
  String _branchFilter = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminTeamLeadProvider.notifier).fetch());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _branches =>
      ['TIRUNELVELI', 'THISAYANVILAI', 'NAGERCOIL'];

  List<String> get _roles {
    final all = ref.read(adminTeamLeadProvider).list;
    return all.map((t) => t.role).where((r) => r.isNotEmpty).toSet().toList()
      ..sort();
  }

  List<String> get _months {
    final all = ref.read(adminTeamLeadProvider).list;
    final months = all
        .map((t) => t.joiningDate.length >= 7 ? t.joiningDate.substring(0, 7) : '')
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return months;
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(adminTeamLeadProvider);
    final list = p.list;

    var filtered = list.where((t) {
      final q = _searchCtrl.text.toLowerCase();
      if (q.isNotEmpty && !t.fullName.toLowerCase().contains(q)) return false;
      if (_roleFilter.isNotEmpty && !t.role.toUpperCase().contains(_roleFilter)) return false;
      if (_monthFilter.isNotEmpty) {
        final jd = t.joiningDate;
        if (jd.length >= 7 && jd.substring(0, 7) != _monthFilter) return false;
      }
      if (_branchFilter.isNotEmpty && !t.branchName.toUpperCase().contains(_branchFilter)) return false;
      return true;
    }).toList();

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Team Leads'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.adminCreateTl)
                    .then((_) => p.fetch()),
          ),
        ],
      ),
      body: Column(children: [
        // Search
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by name...',
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
        // Filters
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _FilterChip(context, 'All Roles', '', _roleFilter, (v) {
                setState(() => _roleFilter = v);
              }),
              ..._roles.map((r) => _FilterChip(context, r, r, _roleFilter, (v) {
                    setState(() => _roleFilter = v);
                  })),
              const SizedBox(width: 8),
              _FilterChip(context, 'All Branches', '', _branchFilter, (v) {
                setState(() => _branchFilter = v);
              }),
              ..._branches.map((b) => _FilterChip(context, b, b, _branchFilter, (v) {
                    setState(() => _branchFilter = v);
                  })),
              const SizedBox(width: 8),
              _FilterChip(context, 'Any Month', '', _monthFilter, (v) {
                setState(() => _monthFilter = v);
              }),
              ..._months.map((m) => _FilterChip(context, m, m, _monthFilter, (v) {
                    setState(() => _monthFilter = v);
                  })),
            ]),
          ),
        ),
        // List
        Expanded(
          child: p.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : p.error != null
                  ? Center(child: Text(p.error!))
                  : filtered.isEmpty
                      ? Center(
                          child: Text('No team leads found',
                              style:
                                  TextStyle(color: AppColors.textHi(context))))
                      : RefreshIndicator(
                          onRefresh: () => p.fetch(),
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
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundImage: (t.profilePhoto !=
                                                      null &&
                                                  t.profilePhoto!.isNotEmpty)
                                              ? NetworkImage(t.profilePhoto!)
                                              : null,
                                          backgroundColor: AppColors.primary
                                              .withOpacity(0.1),
                                          child: (t.profilePhoto == null ||
                                                  t.profilePhoto!.isEmpty)
                                              ? Text(
                                                  t.fullName.isNotEmpty
                                                      ? t.fullName[0]
                                                          .toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          AppColors.primary),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(t.fullName,
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            AppColors.textPri(context))),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${t.employeeId} | ${t.branchName}${t.createdByAdmin.isNotEmpty ? ' | by ${t.createdByAdmin}' : ''}',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          AppColors.textHi(context)),
                                                ),
                                              ]),
                                        ),
                                        StatusBadge(status: t.status),
                                      ]),
                                      const SizedBox(height: 8),
                                      Row(children: [
                                        _InfoChip(
                                            Icons.star_rounded,
                                            '${t.performanceScore}',
                                            AppColors.accent),
                                        const SizedBox(width: 8),
                                        _InfoChip(
                                            Icons.assignment_rounded,
                                            'A:${t.totalAssignedTasks}',
                                            AppColors.card2),
                                        const SizedBox(width: 8),
                                        _InfoChip(
                                            Icons.task_alt_rounded,
                                            'C:${t.totalCompletedTasks}',
                                            AppColors.success),
                                        const SizedBox(width: 8),
                                        _InfoChip(
                                            Icons.hourglass_empty_rounded,
                                            'P:${t.totalPendingTasks}',
                                            AppColors.warning),
                                      ]),
                                      const SizedBox(height: 8),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            if (t.status == 'ACTIVE')
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.toggle_off_rounded,
                                                    color: AppColors.error),
                                                tooltip: 'Deactivate',
                                                onPressed: () =>
                                                    _toggleStatus(t, false),
                                                visualDensity:
                                                    VisualDensity.compact,
                                              )
                                            else
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.toggle_on_rounded,
                                                    color: AppColors.success),
                                                tooltip: 'Activate',
                                                onPressed: () =>
                                                    _toggleStatus(t, true),
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                            IconButton(
                                              icon: Icon(
                                                  Icons.visibility_rounded,
                                                  color: AppColors.textHi(context)),
                                              onPressed: () => Navigator
                                                      .pushNamed(
                                                    context,
                                                    AppRoutes.adminTlDetail,
                                                    arguments: {'id': t.id},
                                                  )
                                                      .then((_) => p.fetch()),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                  Icons.edit_rounded,
                                                  color: AppColors.textHi(context)),
                                              onPressed: () => Navigator
                                                      .pushNamed(
                                                    context,
                                                    AppRoutes.adminEditTl,
                                                    arguments: {'id': t.id},
                                                  )
                                                      .then((_) => p.fetch()),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.delete_rounded,
                                                  color: AppColors.error),
                                              tooltip: 'Delete',
                                              onPressed: () async {
                                                final ok = await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text('Delete Team Lead'),
                                                    content: Text('Delete "${t.fullName}"?'),
                                                    actions: [
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(ctx, false),
                                                          child: const Text('Cancel')),
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(ctx, true),
                                                          child: const Text('Delete',
                                                              style: TextStyle(
                                                                  color:
                                                                      AppColors.error))),
                                                    ],
                                                  ),
                                                );
                                                if (ok == true) {
                                                  await ref
                                                      .read(adminTeamLeadProvider.notifier)
                                                      .delete(t.id);
                                                }
                                              },
                                              visualDensity: VisualDensity.compact,
                                            ),
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

  Future<void> _toggleStatus(dynamic t, bool active) async {
    final ok = await ref
        .read(adminTeamLeadProvider.notifier)
        .toggleStatus(t.id, active);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              ok ? 'Status updated' : 'Failed to update status')));
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
