import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/string_utils.dart';
import '../../../providers/staff_permission_provider.dart';

class StaffPermissionHistoryScreen extends ConsumerStatefulWidget {
  const StaffPermissionHistoryScreen({super.key});

  @override
  ConsumerState<StaffPermissionHistoryScreen> createState() =>
      _StaffPermissionHistoryScreenState();
}

class _StaffPermissionHistoryScreenState
    extends ConsumerState<StaffPermissionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    ref.read(staffPermissionProvider.notifier).fetchHistory();
  }

  Color _statusColor(String? s) {
    switch (s?.toUpperCase()) {
      case 'APPROVED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.error;
      case 'PENDING':
        return AppColors.warning;
      default:
        return AppColors.textHi(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pp = ref.watch(staffPermissionProvider);

    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Permission History',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPri(context)),
      ),
      body: RefreshIndicator(
        onRefresh: _init,
        color: AppColors.accent,
        child: pp.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.accent, strokeWidth: 2))
            : pp.permissions.isEmpty
                ? Center(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 60,
                              color: AppColors.textHi(context).withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text('No permission records',
                              style: TextStyle(color: AppColors.textHi(context))),
                        ]))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: pp.permissions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final p = pp.permissions[i];
                      final status =
                          (p['status'] ?? 'PENDING').toString().toUpperCase();
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ]),
                        child: Row(children: [
                          Container(
                            width: 3,
                            height: 36,
                            decoration: BoxDecoration(
                                color: _statusColor(status),
                                borderRadius: BorderRadius.circular(3)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      p['reason']?.toString() ?? 'Permission',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPri(context))),
                                  const SizedBox(height: 2),
                                  Text(
                                      '${truncate(p['permissionDate']?.toString(), 10)} | ${p['durationHours'] ?? 1}h',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSec(context))),
                                ]),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(status,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _statusColor(status))),
                          ),
                        ]),
                      );
                    },
                  ),
      ),
    );
  }
}