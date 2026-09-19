import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/string_utils.dart';
import '../../../providers/staff_attendance_provider.dart';

class StaffAttendanceHistoryScreen extends ConsumerStatefulWidget {
  const StaffAttendanceHistoryScreen({super.key});

  @override
  ConsumerState<StaffAttendanceHistoryScreen> createState() =>
      _StaffAttendanceHistoryScreenState();
}

class _StaffAttendanceHistoryScreenState
    extends ConsumerState<StaffAttendanceHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    ref.read(staffAttendanceProvider.notifier).fetchHistory();
  }

  String _fmt(String? raw) {
    if (raw == null) return '--:--';
    try {
      return raw.length >= 16 ? raw.substring(11, 16) : raw;
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final attP = ref.watch(staffAttendanceProvider);

    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Attendance History',
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
        child: attP.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.accent, strokeWidth: 2))
            : attP.history.isEmpty
                ? Center(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_rounded,
                              size: 60,
                              color: AppColors.textHi(context).withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text('No records found',
                              style: TextStyle(color: AppColors.textHi(context))),
                        ]))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: attP.history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final r = attP.history[i];
                      final checkedOut = r['checkOutTime'] != null;
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
                                color: checkedOut
                                    ? AppColors.success
                                    : AppColors.warning,
                                borderRadius: BorderRadius.circular(3)),
                          ),
                          const SizedBox(width: 14),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    truncate(
                                        (r['attendanceDate']?.toString() ?? r['createdAt']?.toString() ?? ''), 10),
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPri(context))),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Icon(Icons.login_rounded,
                                      size: 13, color: AppColors.textHi(context)),
                                  const SizedBox(width: 4),
                                  Text(_fmt(r['checkInTime']?.toString()),
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSec(context))),
                                  const SizedBox(width: 12),
                                  Icon(Icons.logout_rounded,
                                      size: 13, color: AppColors.textHi(context)),
                                  const SizedBox(width: 4),
                                  Text(_fmt(r['checkOutTime']?.toString()),
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSec(context))),
                                ]),
                              ]),
                          const Spacer(),
                          if (r['status'] != null)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: r['status'] == 'PRESENT'
                                    ? AppColors.success.withOpacity(0.1)
                                    : r['status'] == 'LATE'
                                        ? AppColors.warning.withOpacity(0.1)
                                        : AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(r['status'].toString(),
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: r['status'] == 'PRESENT'
                                          ? AppColors.success
                                          : r['status'] == 'LATE'
                                              ? AppColors.warning
                                              : AppColors.error)),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (checkedOut
                                      ? AppColors.success
                                      : AppColors.warning)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              checkedOut ? 'Completed' : 'Active',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: checkedOut
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ),
                        ]),
                      );
                    },
                  ),
      ),
    );
  }
}
