import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/string_utils.dart';
import '../../../core/utils/attendance_location.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../providers/staff_attendance_provider.dart';
import '../../../providers/staff_permission_provider.dart';
import '../../../routes/app_routes.dart';

class StaffAttendanceScreen extends ConsumerStatefulWidget {
  const StaffAttendanceScreen({super.key});

  @override
  ConsumerState<StaffAttendanceScreen> createState() =>
      _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState
    extends ConsumerState<StaffAttendanceScreen> {
  bool _locating = false;
  String _officeName = '';
  (String, String)? _shiftTimes; // (shiftStartTime, shiftEndTime) "HH:mm"
  bool _shiftLoaded = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (mounted) {
      ref.read(staffAttendanceProvider.notifier).fetchHistory();
      ref.read(staffPermissionProvider.notifier).fetchHistory();
      _loadShift();
    }
  }

  Future<void> _loadShift() async {
    final staffId = await StorageHelper.getStaffId();
    String start = '', end = '';
    if (staffId != null && staffId.isNotEmpty) {
      start = (await StorageHelper.getStaffShiftStartTime(staffId)) ?? '';
      end = (await StorageHelper.getStaffShiftEndTime(staffId)) ?? '';
    }
    if (mounted) {
      setState(() {
        _shiftTimes = (start, end);
        _shiftLoaded = true;
      });
    }
  }

  /// Returns the staff's shift start hour/minute, or null when unknown.
  (int, int)? _shiftStart() {
    final t = _shiftTimes;
    if (t == null || t.$1.isEmpty) return null;
    final parts = t.$1.split(':');
    if (parts.isEmpty) return null;
    final hour = int.tryParse(parts[0]);
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
    if (hour == null) return null;
    return (hour, minute ?? 0);
  }

  /// Check-in deadline = shift start + 3 minutes, matching the backend's
  /// `shiftStartTime.plusMinutes(3)`.
  (int, int)? _shiftDeadline() {
    final s = _shiftStart();
    if (s == null) return null;
    final totalMin = s.$2 + 3;
    return (s.$1 + totalMin ~/ 60, totalMin % 60);
  }

  /// Formats a 24-hour (hour, minute) pair as a 12-hour "h:mm AM/PM" label.
  String _to12h(int hour, int minute) {
    final ampm = hour < 12 ? 'AM' : 'PM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final mm = minute.toString().padLeft(2, '0');
    return '$h12:$mm $ampm';
  }

  String _shiftDeadlineLabel() {
    final d = _shiftDeadline();
    if (d == null) return '--:--';
    return _to12h(d.$1, d.$2);
  }

  /// Shift end (check-out) time "HH:mm", matching backend `shiftEndTime`.
  /// Falls back to "18:00" when the staff has no configured shift end.
  String _shiftEndLabel() {
    final t = _shiftTimes;
    final raw = (t == null || t.$2.trim().isEmpty) ? '18:00' : t.$2.trim();
    final parts = raw.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 18 : 18;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return _to12h(hour, minute);
  }

  /// Permission-extended check-in deadline. When an approved
  /// permission exists for today the backend adds `durationHours` to the
  /// `shiftStartTime + 3 minutes` check-in deadline, so the window is shown
  /// accordingly.
  String _extendedDeadlineLabel() {
    final extra = _approvedPermissionHoursToday();
    if (extra <= 0) {
      return _shiftDeadlineLabel();
    }
    final d = _shiftDeadline();
    if (d == null) return _shiftDeadlineLabel();
    final totalMin = d.$2 + extra * 60;
    final h = d.$1 + totalMin ~/ 60;
    final m = totalMin % 60;
    return _to12h(h, m);
  }

  Future<void> _handleCheckIn() async {
    final extraHours = _approvedPermissionHoursToday();
    final deadline = _shiftDeadline();
    final allowed = deadline == null
        ? AttendanceLocationService.isCheckInTimeAllowed(DateTime.now(),
            extraHours: extraHours)
        : AttendanceLocationService.isCheckInTimeAllowed(DateTime.now(),
            extraHours: extraHours,
            hour: deadline.$1,
            minute: deadline.$2);
    if (!allowed) {
      final base = _shiftDeadlineLabel();
      _showError(extraHours > 0
          ? 'Check-in window (extended by $extraHours hour(s) permission) has closed.'
          : 'Check-in closes at $base. You can not check in now.');
      return;
    }
    setState(() => _locating = true);
    try {
      final (lat, lng, office) =
          await AttendanceLocationService.verifiedPosition();
      if (!mounted) return;

      final assigned =
          _assignedBranch(ref.read(staffAttendanceProvider).history);
      if (assigned != null && office != assigned) {
        _showError(
            'Check-in allowed only from your assigned $assigned branch.');
        return;
      }

      final ok = await ref
          .read(staffAttendanceProvider.notifier)
          .checkIn(lat, lng);

      if (mounted) {
        setState(() => _officeName = ok ? office : _officeName);
        final msg = ok
            ? 'Check-in successful ($office)'
            : (ref.read(staffAttendanceProvider).error ?? 'Check-in failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: ok ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  String? _assignedBranch(List<dynamic> history) {
    for (final r in history) {
      final branch = r['branch']?.toString().trim().toUpperCase();
      if (branch != null && branch.isNotEmpty) return branch;
    }
    return null;
  }

  int _approvedPermissionHoursToday() {
    final permissions = ref.read(staffPermissionProvider).permissions;
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    int hours = 0;
    for (final p in permissions) {
      final status = (p['status'] ?? '').toString().toUpperCase();
      final rawDate = p['permissionDate']?.toString() ?? '';
      final date = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
      if (status == 'APPROVED' && date == today) {
        final h = p['durationHours'];
        if (h is num) {
          hours = h.toInt();
        } else if (h != null) {
          hours = int.tryParse(h.toString()) ?? 0;
        }
      }
    }
    return hours;
  }

  Future<void> _handleCheckOut() async {
    setState(() => _locating = true);
    try {
      final ok = await ref
          .read(staffAttendanceProvider.notifier)
          .checkOut();

      if (mounted) {
        final msg = ok
            ? 'Check-out successful'
            : (ref.read(staffAttendanceProvider).error ?? 'Check-out failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: ok ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '--:--';
    final hm = raw.length >= 16 ? raw.substring(11, 16) : raw;
    final parts = hm.split(':');
    if (parts.length < 2) return raw;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return raw;
    return _to12h(h, m);
  }

  @override
  Widget build(BuildContext context) {
    final attP = ref.watch(staffAttendanceProvider);
    final last = attP.lastCheck;

    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Attendance',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: AppColors.textSec(context)),
            onPressed: () => Navigator.pushNamed(
                context, AppRoutes.staffAttendanceHistory),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _init,
        color: AppColors.accent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: Column(children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: attP.isCheckedIn
                        ? AppColors.success.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                    border: Border.all(
                        color: attP.isCheckedIn
                            ? AppColors.success
                            : Colors.white.withOpacity(0.3),
                        width: 3),
                  ),
                  child: Icon(
                    attP.isCheckedIn
                        ? Icons.check_circle_rounded
                        : Icons.fingerprint_rounded,
                    size: 36,
                    color: attP.isCheckedIn
                        ? AppColors.success
                        : Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  attP.isCheckedIn ? 'Checked In' : 'Not Checked In',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _officeName.isNotEmpty
                        ? 'Office: $_officeName'
                        : 'Supported offices: TIRUNELVELI / THISAYANVILAI',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _approvedPermissionHoursToday() > 0
                      ? 'Check-in: before ${_extendedDeadlineLabel()} (permission ${_approvedPermissionHoursToday()}h)  �  Check-out: after ${_shiftEndLabel()}'
                      : 'Check-in: before ${_shiftDeadlineLabel()}  �  Check-out: after ${_shiftEndLabel()}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 10),
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (last != null) ...[
                        _InfoChip(
                            label: 'In',
                            value: _formatTime(last['checkInTime']?.toString())),
                        const SizedBox(width: 16),
                        _InfoChip(
                            label: 'Out',
                            value: _formatTime(
                                last['checkOutTime']?.toString())),
                      ],
                    ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: attP.isLoading || _locating
                        ? null
                        : attP.isCheckedIn
                            ? _handleCheckOut
                            : _handleCheckIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: attP.isCheckedIn
                          ? AppColors.error
                          : AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _locating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            attP.isCheckedIn ? 'Check Out' : 'Check In',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent History',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPri(context))),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.staffAttendanceHistory),
                    child: const Text('View all',
                        style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
            const SizedBox(height: 12),
            if (attP.isLoading)
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accent, strokeWidth: 2)))
            else if (attP.history.isEmpty)
              Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16)),
                  child: Center(
                      child: Text('No records yet',
                          style: TextStyle(color: AppColors.textHi(context)))))
            else
              ...attP.history.take(10).map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
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
                            color: r['checkOutTime'] != null
                                ? AppColors.success
                                : AppColors.warning,
                            borderRadius: BorderRadius.circular(3)),
                      ),
                      const SizedBox(width: 14),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                Text(
                                    truncate((r['attendanceDate']?.toString() ?? r['createdAt']?.toString() ?? ''), 10),
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPri(context))),
                            const SizedBox(height: 2),
                            Row(children: [
                              Icon(Icons.login_rounded,
                                  size: 12, color: AppColors.textHi(context)),
                              const SizedBox(width: 4),
                              Text(
                                  _formatTime(
                                      r['checkInTime']?.toString()),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSec(context))),
                              const SizedBox(width: 12),
                              Icon(Icons.logout_rounded,
                                  size: 12, color: AppColors.textHi(context)),
                              const SizedBox(width: 4),
                              Text(
                                  _formatTime(
                                      r['checkOutTime']?.toString()),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSec(context))),
                            ]),
                          ]),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: r['checkOutTime'] != null
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          r['checkOutTime'] != null ? 'Done' : 'Active',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: r['checkOutTime'] != null
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ),
                    ]),
                  )),
          ]),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label, value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label,
          style: TextStyle(
              color: Colors.white.withOpacity(0.65), fontSize: 11)),
    ]);
  }
}
