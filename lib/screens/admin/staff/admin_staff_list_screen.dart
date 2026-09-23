import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/staff_model.dart';
import '../../../providers/admin_staff_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/pagination_bar.dart';
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
  String _branchFilter = '';
  bool _showInactive = false;

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
      if (_branchFilter.isNotEmpty &&
          !s.branch.toUpperCase().contains(_branchFilter))
        return false;
      if (!_showInactive && s.status.toUpperCase() == 'INACTIVE') return false;
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
                    .then((_) => p.refresh()),
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
              _FilterChip(context, 'Show inactive', 'show',
                  _showInactive ? 'show' : '', (v) {
                setState(() => _showInactive = v == 'show');
              }),
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
                          onRefresh: () => p.refresh(),
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
                                                      .then((_) => p.refresh()),
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
                                                  final prov = ref
                                                      .read(adminStaffProvider.notifier);
                                                  final deleted =
                                                      await prov.delete(s.id);
                                                  if (!mounted) return;
                                                  if (deleted) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(SnackBar(
                                                      content:
                                                          const Text('Staff deleted'),
                                                      backgroundColor:
                                                          AppColors.success,
                                                    ));
                                                    return;
                                                  }
                                                  final err = ref
                                                          .read(adminStaffProvider)
                                                          .error ??
                                                      'Failed to delete staff';
                                                  final deactivated =
                                                      await _offerDeactivate(s, err);
                                                  if (!mounted) return;
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(SnackBar(
                                                    content: Text(deactivated
                                                        ? 'Staff deactivated — removed from the active list'
                                                        : err),
                                                    backgroundColor: deactivated
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
        PaginationBar(
          data: p.pagination,
          isLoading: p.isLoading,
          onPageChanged: (page) =>
              ref.read(adminStaffProvider.notifier).fetch(page: page),
        ),
      ]),
    );
  }

  /// Fallback when the hard delete fails with the backend FK constraint
  /// ("An unexpected system anomaly occurred: ..."). The server has no way to
  /// purge the staff's attendance / telecalling / other dependent records, so
  /// offer to deactivate instead, which hides them from the active list.
  Future<bool> _offerDeactivate(StaffModel s, String err) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Could not delete'),
        content: Text(
          '"${s.name}" has saved records (attendance, calls, tasks, etc.) that '
          'the server cannot auto-delete, so a permanent delete failed.\n\n'
          'Deactivate them instead? They will be hidden from the Staff '
          'Monitoring list.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    return ref.read(adminStaffProvider.notifier).deactivate(s.id);
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
