import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/admin_staff_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/status_badge.dart';

class AdminStaffListScreen extends ConsumerStatefulWidget {
  const AdminStaffListScreen({super.key});
  @override
  ConsumerState<AdminStaffListScreen> createState() =>
      _AdminStaffListScreenState();
}

class _AdminStaffListScreenState extends ConsumerState<AdminStaffListScreen> {
  final _searchCtrl = TextEditingController();
  String _roleFilter = '';
  String _monthFilter = '';
  String _branchFilter = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminStaffProvider.notifier).fetch());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _branches =>
      ['TIRUNELVELI', 'THISAYANVILAI', 'NAGERCOIL'];

  List<String> get _roles =>
      ['DEVELOPER', 'DEVELOPER_TRAINER', 'TELECOM_SERVICE', 'DESIGNER', 'FREELANCER'];

  List<String> get _months {
    final all = ref.read(adminStaffProvider).list;
    final months = all
        .map((s) =>
            s.joiningDate.length >= 7 ? s.joiningDate.substring(0, 7) : '')
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return months;
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(adminStaffProvider);
    final list = p.list;

    var filtered = list.where((s) {
      final q = _searchCtrl.text.toLowerCase();
      if (q.isNotEmpty && !s.name.toLowerCase().contains(q)) return false;
      if (_roleFilter.isNotEmpty &&
          !s.role.toLowerCase().contains(_roleFilter.toLowerCase()) &&
          !s.category.toLowerCase().contains(_roleFilter.toLowerCase()))
        return false;
      if (_monthFilter.isNotEmpty) {
        final jd = s.joiningDate;
        if (jd.length >= 7 && jd.substring(0, 7) != _monthFilter) return false;
      }
      if (_branchFilter.isNotEmpty &&
          !s.branch.toUpperCase().contains(_branchFilter))
        return false;
      return true;
    }).toList();

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Staff Monitoring'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.adminStaffCreate)
                    .then((_) => p.fetch()),
          ),
          IconButton(
            icon: const Icon(Icons.pending_actions_rounded),
            tooltip: 'Pending Approvals',
            onPressed: _showPendingApprovals,
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
                          child: Text('No staff found',
                              style:
                                  TextStyle(color: AppColors.textHi(context))))
                      : RefreshIndicator(
                          onRefresh: () => p.fetch(),
                          color: AppColors.accent,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final s = filtered[i];
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
                                          backgroundImage: (s.profilePhoto !=
                                                      null &&
                                                  s.profilePhoto!.isNotEmpty)
                                              ? NetworkImage(s.profilePhoto!)
                                              : null,
                                          backgroundColor: AppColors.card2
                                              .withOpacity(0.1),
                                          child: (s.profilePhoto == null ||
                                                  s.profilePhoto!.isEmpty)
                                              ? Text(
                                                  s.name.isNotEmpty
                                                      ? s.name[0].toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppColors.card2),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(s.name,
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            AppColors.textPri(context))),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${s.employeeId} | ${s.branch}${s.createdByAdmin != null && s.createdByAdmin!.isNotEmpty ? ' | by ${s.createdByAdmin}' : ''}',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          AppColors.textHi(context)),
                                                ),
                                              ]),
                                        ),
                                        StatusBadge(status: s.status),
                                      ]),
                                      const SizedBox(height: 6),
                                      Row(children: [
                                        _InfoChip(
                                            Icons.star_rounded,
                                            '${s.performanceScore}',
                                            AppColors.accent),
                                        const SizedBox(width: 8),
                                        _InfoChip(
                                            Icons.assignment_rounded,
                                            'A:${s.totalAssignedTasks}',
                                            AppColors.card2),
                                        const SizedBox(width: 8),
                                        _InfoChip(
                                            Icons.task_alt_rounded,
                                            'C:${s.totalCompletedTasks}',
                                            AppColors.success),
                                        const SizedBox(width: 8),
                                        _InfoChip(
                                            Icons.hourglass_empty_rounded,
                                            'P:${s.totalPendingTasks}',
                                            AppColors.warning),
                                      ]),
                                      const SizedBox(height: 6),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(s.role.isNotEmpty
                                                ? s.role
                                                : s.category,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        AppColors.textHi(context))),
                                            const Spacer(),
                                            IconButton(
                                              icon: Icon(
                                                  Icons.visibility_rounded,
                                                  color: AppColors.textHi(context)),
                                              onPressed: () {
                                                Navigator.pushNamed(
                                                  context,
                                                  AppRoutes.adminStaffDetail,
                                                  arguments: {'id': s.id},
                                                );
                                              },
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                  Icons.edit_rounded,
                                                  color: AppColors.textHi(context)),
                                              onPressed: () => Navigator
                                                      .pushNamed(
                                                    context,
                                                    AppRoutes.adminStaffEdit,
                                                    arguments: {'staffId': s.id},
                                                  )
                                                      .then((_) => p.fetch()),
                                              visualDensity:
                                                  VisualDensity.compact,
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
                                                    title: const Text('Delete Staff'),
                                                    content: Text('Delete "${s.name}"?'),
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
                                                  final deleted = await ref
                                                      .read(adminStaffProvider.notifier)
                                                      .delete(s.id);
                                                  final err = ref
                                                      .read(adminStaffProvider)
                                                      .error;
                                                  if (!mounted) return;
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(SnackBar(
                                                    content: Text(deleted
                                                        ? 'Staff deleted'
                                                        : (err ??
                                                            'Failed to delete staff')),
                                                    backgroundColor: deleted
                                                        ? AppColors.success
                                                        : AppColors.error,
                                                  ));
                                                }
                                              },
                                              visualDensity:
                                                  VisualDensity.compact,
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

  void _showPendingApprovals() async {
    final prov = ref.read(adminStaffProvider.notifier);
    await prov.fetchPendingApprovals();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final pending = prov.pendingApprovals;
            final loadError = prov.error;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pending Approvals',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPri(context))),
                        IconButton(
                          icon: Icon(Icons.refresh_rounded,
                              color: AppColors.textHi(context)),
                          tooltip: 'Refresh',
                          onPressed: () async {
                            prov.clearError();
                            await prov.fetchPendingApprovals();
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // ✅ FIX: previously any fetch failure (network/auth
                    // error) was silently shown as "No pending approvals",
                    // hiding real errors from the admin. Now the error is
                    // surfaced explicitly instead of looking like an
                    // empty list.
                    if (loadError != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(children: [
                            Text('Could not load pending approvals',
                                style: TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text(loadError,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppColors.textHi(context), fontSize: 12)),
                          ]),
                        ),
                      )
                    else if (pending.isEmpty)
                      Center(
                          child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No pending approvals',
                            style: TextStyle(color: AppColors.textHi(context))),
                      ))
                    else
                      ...pending.map((s) => ListTile(
                            title: Text(s.name),
                            subtitle: Text(s.email),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                final ok = await prov.approveStaff(s.id);
                                if (!ok && ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            prov.error ?? 'Failed to approve')),
                                  );
                                }
                                setModalState(() {});
                                if (mounted) setState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Approve'),
                            ),
                          )),
                  ],
                ),
              ),
            );
          },
        );
      },
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
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ]),
  );
}
