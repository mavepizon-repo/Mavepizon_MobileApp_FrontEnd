import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../core/utils/string_utils.dart';
import '../../../providers/admin_leave_provider.dart';
import '../../../widgets/pagination_bar.dart';
import '../../../widgets/status_badge.dart';

class AdminLeaveApprovalScreen extends ConsumerStatefulWidget {
  const AdminLeaveApprovalScreen({super.key});
  @override
  ConsumerState<AdminLeaveApprovalScreen> createState() =>
      _AdminLeaveApprovalScreenState();
}

class _AdminLeaveApprovalScreenState
    extends ConsumerState<AdminLeaveApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    Future.microtask(() => ref.read(adminLeaveProvider.notifier).fetch());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(adminLeaveProvider);
    final all = p.leaves;
    final pending = p.pendingLeaves;

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Leave Approvals'),
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
              ? Center(child: Text(p.error!))
              : Column(children: [
                  Expanded(
                    child: TabBarView(controller: _tabCtrl, children: [
                      _LeaveList(
                          leaves: pending,
                          onRefresh: () => p.refresh(),
                          onApprove: (id) => _handleApprove(p, id),
                          onReject: (id) => _handleReject(p, id)),
                      _LeaveList(
                          leaves: all,
                          onRefresh: () => p.refresh(),
                          onApprove: (id) => _handleApprove(p, id),
                          onReject: (id) => _handleReject(p, id)),
                    ]),
                  ),
                  PaginationBar(
                    data: p.pagination,
                    isLoading: p.isLoading,
                    onPageChanged: (page) =>
                        ref.read(adminLeaveProvider.notifier).fetch(page: page),
                  ),
                ]),
    );
  }

  Future<void> _handleApprove(AdminLeaveProvider p, String leaveId) async {
    final adminId = await StorageHelper.getUserId() ?? '';
    final ok = await p.approveLeave(adminId, leaveId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Approved' : 'Failed to approve')));
    }
  }

  Future<void> _handleReject(AdminLeaveProvider p, String leaveId) async {
    final adminId = await StorageHelper.getUserId() ?? '';
    final ok = await p.rejectLeave(adminId, leaveId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Rejected' : 'Failed to reject')));
    }
  }
}

class _LeaveList extends StatelessWidget {
  final List<dynamic> leaves;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String) onApprove;
  final Future<void> Function(String) onReject;
  const _LeaveList({
    required this.leaves,
    required this.onRefresh,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (leaves.isEmpty) {
      return Center(
          child: Text('No leave requests',
              style: TextStyle(color: AppColors.textHi(context))));
    }
    return RefreshIndicator(
      onRefresh: () => onRefresh(),
      color: AppColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leaves.length,
        itemBuilder: (_, i) {
          final l = leaves[i];
          final teamLead = l['teamLead'];
          final name = teamLead is Map
              ? (teamLead['name']?.toString() ?? '')
              : '';
          final status = (l['status'] ?? '').toString().toUpperCase();
          final startDate = truncate(l['startDate']?.toString(), 10);
          final endDate = truncate(l['endDate']?.toString(), 10);

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
                      child: Text(name.isNotEmpty ? name : 'Team Lead',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPri(context))),
                    ),
                    StatusBadge(status: status),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                      '$startDate → $endDate',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textHi(context))),
                  if (l['reason'] != null)
                    Text(l['reason'].toString(),
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSec(context))),
                  if (status == 'PENDING') ...[
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: () => onReject(l['id'].toString()),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Reject',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: () => onApprove(l['id'].toString()),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Approve',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
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
