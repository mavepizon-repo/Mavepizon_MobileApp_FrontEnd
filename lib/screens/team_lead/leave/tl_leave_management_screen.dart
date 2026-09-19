import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/leave_provider.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_widget.dart';

class TlLeaveManagementScreen extends ConsumerStatefulWidget {
  const TlLeaveManagementScreen({super.key});
  @override
  ConsumerState<TlLeaveManagementScreen> createState() =>
      _TlLeaveManagementScreenState();
}

class _TlLeaveManagementScreenState
    extends ConsumerState<TlLeaveManagementScreen> {
  String _statusFilter = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(leaveProvider.notifier).fetchStaffLeaves());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _staffName(dynamic leave) {
    try {
      return leave['staff']['name']?.toString() ?? 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  String _dateRange(dynamic leave) {
    final start = leave['startDate']?.toString() ?? '';
    final end = leave['endDate']?.toString() ?? '';
    final s = start.length >= 10 ? start.substring(0, 10) : start;
    final e = end.length >= 10 ? end.substring(0, 10) : end;
    return s == e ? s : '$s to $e';
  }

  Future<void> _confirmAction(
      String leaveId, String staffName, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(action == 'APPROVED' ? 'Approve Leave' : 'Reject Leave'),
        content: Text('$action leave request from $staffName?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'APPROVED'
                  ? AppColors.success
                  : AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(action == 'APPROVED' ? 'Approve' : 'Reject',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (!mounted) return;
      final provider = ref.read(leaveProvider.notifier);
      final success = action == 'APPROVED'
          ? await provider.approveLeave(leaveId)
          : await provider.rejectLeave(leaveId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? 'Leave $action successfully'
            : 'Failed to $action leave'),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = ref.watch(leaveProvider);
    final leaves = prov.staffLeaves;
    final q = _searchCtrl.text.toLowerCase();
    final filteredLeaves = leaves.where((l) {
      if (q.isNotEmpty && !_staffName(l).toLowerCase().contains(q))
        return false;
      if (_statusFilter.isNotEmpty &&
          !(l['status'] ?? 'PENDING').toString().toUpperCase().contains(_statusFilter))
        return false;
      return true;
    }).toList();
    final pending = leaves
        .where((l) => (l['status'] ?? 'PENDING').toString().toUpperCase() == 'PENDING')
        .toList();

    return Scaffold(
      
      body: Column(children: [
        Container(
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 8, 20, 20),
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28))),
          child: Column(children: [
            Row(children: [
              GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 20))),
              const SizedBox(width: 14),
              const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Leave Management',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    Text('Staff leave requests',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ]),
              const Spacer(),
              if (pending.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${pending.length} pending',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
            ]),
          ]),
        ),
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by staff name...',
              prefixIcon:
                  Icon(Icons.search_rounded, color: AppColors.textHi(context)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
              _FChip(context, 'All', '', _statusFilter, (v) {
                setState(() => _statusFilter = v);
              }),
              _FChip(context, 'Pending', 'PENDING', _statusFilter, (v) {
                setState(() => _statusFilter = v);
              }),
              _FChip(context, 'Approved', 'APPROVED', _statusFilter, (v) {
                setState(() => _statusFilter = v);
              }),
              _FChip(context, 'Rejected', 'REJECTED', _statusFilter, (v) {
                setState(() => _statusFilter = v);
              }),
            ]),
          ),
        ),
        Expanded(
          child: prov.isLoading
              ? const LoadingWidget(message: 'Loading leaves...')
              : filteredLeaves.isEmpty
                  ? const EmptyWidget(
                      message: 'No leave requests yet',
                      icon: Icons.event_busy_outlined)
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(leaveProvider.notifier).fetchStaffLeaves(),
                      color: AppColors.accent,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredLeaves.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final l = filteredLeaves[i];
                          final status =
                              (l['status'] ?? 'PENDING').toString().toUpperCase();
                          final isPending = status == 'PENDING';
                          final name = _staffName(l);
                          final reason = l['reason']?.toString() ?? '';

                          Color statusColor;
                          if (status == 'APPROVED') {
                            statusColor = AppColors.success;
                          } else if (status == 'REJECTED') {
                            statusColor = AppColors.error;
                          } else {
                            statusColor = AppColors.warning;
                          }

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: isPending
                                  ? Border.all(
                                      color: AppColors.warning.withOpacity(0.4),
                                      width: 1.5)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Row(children: [
                                CircleAvatar(
                                    radius: 20,
                                    backgroundColor:
                                        AppColors.primary.withOpacity(0.1),
                                    child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary))),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(name,
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPri(context))),
                                      Text(_dateRange(l),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textHi(context))),
                                    ])),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(status,
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor)),
                                ),
                              ]),
                              if (reason.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(reason,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSec(context))),
                                ),
                              ],
                              if (isPending) ...[
                                const SizedBox(height: 12),
                                Row(children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _confirmAction(
                                          l['id']?.toString() ?? '', name, 'APPROVED'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        decoration: BoxDecoration(
                                          color: AppColors.success,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.check_rounded,
                                                  size: 16,
                                                  color: Colors.white),
                                              SizedBox(width: 4),
                                              Text('Approve',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 13)),
                                            ]),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _confirmAction(
                                          l['id']?.toString() ?? '', name, 'REJECTED'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        decoration: BoxDecoration(
                                          color: AppColors.error,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.close_rounded,
                                                  size: 16,
                                                  color: Colors.white),
                                              SizedBox(width: 4),
                                              Text('Reject',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 13)),
                                            ]),
                                      ),
                                    ),
                                  ),
                                ]),
                              ],
                            ]),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}

Widget _FChip(BuildContext context, String label, String value, String current, void Function(String) onSelected) {
  final selected = current == value;
  return Padding(
    padding: const EdgeInsets.only(right: 6),
    child: GestureDetector(
      onTap: () => onSelected(selected ? '' : value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSec(context))),
      ),
    ),
  );
}
