import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/permission_provider.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_widget.dart';

class TlPermissionManagementScreen extends ConsumerStatefulWidget {
  const TlPermissionManagementScreen({super.key});
  @override
  ConsumerState<TlPermissionManagementScreen> createState() =>
      _TlPermissionManagementScreenState();
}

class _TlPermissionManagementScreenState
    extends ConsumerState<TlPermissionManagementScreen> {
  String _statusFilter = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = ref.read(permissionProvider);
      if (p.permissions.isEmpty && !p.isLoading) {
        p.fetchBranchPermissions();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _staffName(dynamic p) {
    try {
      final flat = p['staffName']?.toString();
      if (flat != null && flat.isNotEmpty) return flat;
      final staff = p['staff'];
      if (staff is Map) {
        final nested = staff['name']?.toString();
        if (nested != null && nested.isNotEmpty) return nested;
      }
      return 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  String _formatDate(dynamic d) {
    final s = d?.toString() ?? '';
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  Future<void> _approvePermission(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Approve Permission'),
        content: Text('Approve permission request from $name?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Approve',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (!mounted) return;
      final success =
          await ref.read(permissionProvider.notifier).approvePermission(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? 'Permission approved'
            : 'Failed to approve permission'),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _rejectPermission(String id, String name) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Permission'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Reject permission request from $name?'),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Reason for rejection (optional)',
              hintStyle: const TextStyle(fontSize: 13),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.borderC(context))),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            maxLines: 2,
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reject',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (!mounted) return;
      final remarks = controller.text.isNotEmpty ? controller.text : 'Rejected by Team Lead';
      final success = await ref
          .read(permissionProvider.notifier)
          .rejectPermission(id, remarks);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? 'Permission rejected'
            : 'Failed to reject permission'),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = ref.watch(permissionProvider);
    final perms = prov.permissions;
    final q = _searchCtrl.text.toLowerCase();
    final filteredPerms = perms.where((p) {
      if (q.isNotEmpty && !_staffName(p).toLowerCase().contains(q))
        return false;
      if (_statusFilter.isNotEmpty &&
          !(p['status'] ?? 'PENDING').toString().toUpperCase().contains(_statusFilter))
        return false;
      return true;
    }).toList();
    final pending = perms
        .where((p) => (p['status'] ?? 'PENDING').toString().toUpperCase() == 'PENDING')
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
                    Text('Permissions',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    Text('Staff permission requests',
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
              ? const LoadingWidget(message: 'Loading permissions...')
              : prov.error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off_rounded,
                                size: 48, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text(
                              prov.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => ref
                                  .read(permissionProvider.notifier)
                                  .fetchBranchPermissions(),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : filteredPerms.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const EmptyWidget(
                                message: 'No permission requests yet',
                                icon: Icons.access_time_outlined),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () => ref
                                    .read(permissionProvider.notifier)
                                    .fetchBranchPermissions(),
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Refresh'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                      onRefresh: () => ref
                          .read(permissionProvider.notifier)
                          .fetchBranchPermissions(),
                      color: AppColors.accent,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredPerms.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final p = filteredPerms[i];
                          final status =
                              (p['status'] ?? 'PENDING').toString().toUpperCase();
                          final isPending = status == 'PENDING';
                          final name = _staffName(p);
                          final reason = p['reason']?.toString() ?? '';
                          final date = _formatDate(p['permissionDate']);
                          final hours = p['durationHours']?.toString() ?? '1';

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
                                        AppColors.card6.withOpacity(0.15),
                                    child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.card6))),
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
                                      Text('$date \u2022 $hours hr',
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
                                      onTap: () => _approvePermission(
                                          p['id']?.toString() ?? '', name),
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
                                      onTap: () => _rejectPermission(
                                          p['id']?.toString() ?? '', name),
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
