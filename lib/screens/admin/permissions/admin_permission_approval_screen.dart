import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/string_utils.dart';
import '../../../providers/admin_permission_provider.dart';
import '../../../widgets/status_badge.dart';

class AdminPermissionApprovalScreen extends ConsumerStatefulWidget {
  const AdminPermissionApprovalScreen({super.key});
  @override
  ConsumerState<AdminPermissionApprovalScreen> createState() =>
      _AdminPermissionApprovalScreenState();
}

class _AdminPermissionApprovalScreenState
    extends ConsumerState<AdminPermissionApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    Future.microtask(
        () => ref.read(adminPermissionProvider.notifier).fetch());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _approve(String id) async {
    final ok = await ref.read(adminPermissionProvider.notifier).approve(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Approved' : 'Failed to approve')));
    }
  }

  Future<void> _reject(String id) async {
    final remarksCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Permission'),
        content: TextField(
          controller: remarksCtrl,
          decoration: const InputDecoration(
            hintText: 'Reason for rejection',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reject')),
        ],
      ),
    );
    if (ok == true) {
      final result = await ref
          .read(adminPermissionProvider.notifier)
          .reject(id, remarksCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result ? 'Rejected' : 'Failed to reject')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(adminPermissionProvider);
    final pending = p.pendingPermissions;
    final all = p.allPermissions;

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Permission Approvals'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Pending (${pending.length})'),
            const Tab(text: 'All'),
          ],
        ),
      ),
      body: p.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : p.error != null
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Text(p.error!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 14)),
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed: () => p.fetch(),
                          child: const Text('Retry'))
                    ]))
              : TabBarView(controller: _tabCtrl, children: [
                  _PermissionList(
                      permissions: pending,
                      onRefresh: () => p.fetch(),
                      onApprove: _approve,
                      onReject: _reject),
                  _PermissionList(
                      permissions: all,
                      onRefresh: () => p.fetch(),
                      onApprove: _approve,
                      onReject: _reject),
                ]),
    );
  }
}

class _PermissionList extends StatelessWidget {
  final List<dynamic> permissions;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String) onApprove;
  final Future<void> Function(String) onReject;

  const _PermissionList({
    required this.permissions,
    required this.onRefresh,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (permissions.isEmpty) {
      return Center(
          child: Text('No permissions found',
              style: TextStyle(color: AppColors.textHi(context))));
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: permissions.length,
        itemBuilder: (_, i) {
          final perm = permissions[i];
          final teamLead = perm['teamLead'];
          final name = teamLead is Map
              ? (teamLead['name']?.toString() ?? '')
              : '';
          final status =
              (perm['status'] ?? '').toString().toUpperCase();
          final date = truncate(perm['permissionDate']?.toString(), 10);
          final hours = perm['durationHours']?.toString() ?? '';
          final remarks = perm['remarks']?.toString() ?? '';

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                          name.isNotEmpty
                              ? name
                              : 'Team Lead',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPri(context))),
                    ),
                    StatusBadge(status: status),
                  ]),
                  const SizedBox(height: 4),
                  if (date.isNotEmpty)
                    Text('Date: $date',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHi(context))),
                  if (hours.isNotEmpty)
                    Text('Duration: $hours hrs',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHi(context))),
                  if (perm['reason'] != null)
                    Text(perm['reason'].toString(),
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                AppColors.textSec(context))),
                  if (remarks.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Remarks: $remarks',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFEF4444))),
                  ],
                  if (status == 'PENDING') ...[
                    const SizedBox(height: 10),
                    Row(
                        mainAxisAlignment:
                            MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 32,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  onReject(
                                      perm['id'].toString()),
                              icon: const Icon(
                                  Icons.close_rounded,
                                  size: 16),
                              label: const Text('Reject',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w600)),
                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppColors.error,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 32,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  onApprove(
                                      perm['id'].toString()),
                              icon: const Icon(
                                  Icons.check_rounded,
                                  size: 16),
                              label: const Text('Approve',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w600)),
                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppColors.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            8)),
                              ),
                            ),
                          ),
                        ]),
                  ],
                ]),
          );
        },
      ),
    );
  }
}
