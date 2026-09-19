import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../core/utils/string_utils.dart';
import '../../../providers/staff_leave_provider.dart';

class StaffLeaveHistoryScreen extends ConsumerStatefulWidget {
  const StaffLeaveHistoryScreen({super.key});

  @override
  ConsumerState<StaffLeaveHistoryScreen> createState() =>
      _StaffLeaveHistoryScreenState();
}

class _StaffLeaveHistoryScreenState
    extends ConsumerState<StaffLeaveHistoryScreen> {
  String _staffId = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _staffId = await StorageHelper.getStaffId() ?? '';
    if (mounted && _staffId.isNotEmpty) {
      ref.read(staffLeaveProvider.notifier).fetchHistory(_staffId);
    }
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
    final lp = ref.watch(staffLeaveProvider);

    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Leave History',
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
        child: lp.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.accent, strokeWidth: 2))
            : lp.leaves.isEmpty
                ? Center(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy_rounded,
                              size: 60,
                              color: AppColors.textHi(context).withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text('No leave records',
                              style: TextStyle(color: AppColors.textHi(context))),
                        ]))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: lp.leaves.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final l = lp.leaves[i];
                      final status =
                          (l['status'] ?? 'PENDING').toString().toUpperCase();
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
                                      l['leaveType']?.toString() ?? 'Leave',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPri(context))),
                                  const SizedBox(height: 2),
                                  Text(
                                      '${truncate(l['startDate']?.toString(), 10)} - ${truncate(l['endDate']?.toString(), 10)}',
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
