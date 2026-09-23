import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../core/utils/string_utils.dart';
import '../../../core/utils/attendance_location.dart';
import '../../../providers/tl_attendance_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/permission_service.dart';

class TlAttendanceScreen extends ConsumerStatefulWidget {
  const TlAttendanceScreen({super.key});

  @override
  ConsumerState<TlAttendanceScreen> createState() =>
      _TlAttendanceScreenState();
}

class _TlAttendanceScreenState extends ConsumerState<TlAttendanceScreen> {
  String _tlId = '';
  bool _locating = false;
  bool _busy = false;
  String _officeName = '';
  int _approvedHoursNow = 0;
  (int, int)? _shiftStart;
  int? _shiftEnd;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _tlId = await StorageHelper.getUserId() ?? '';
    if (mounted && _tlId.isNotEmpty) {
      await ref.read(tlAttendanceProvider.notifier).fetchHistory(_tlId);
      await _loadShiftFromStorage();
    }
    if (mounted && _shiftStart == null) {
      setState(() {
        _shiftStart = _shiftStartFromHistory();
        final h = _shiftEndFromHistory();
        if (h != null) _shiftEnd = h;
      });
    }
    _refreshPermission();
  }

  Future<void> _loadShiftFromStorage() async {
    final s = await StorageHelper.getStaffShiftStartTime(_tlId);
    final e = await StorageHelper.getStaffShiftEndTime(_tlId);
    if (!mounted) return;
    setState(() {
      if (s != null && s.isNotEmpty) {
        final parts = s.split(':');
        final h = int.tryParse(parts[0]);
        final m = parts.length > 1 ? int.tryParse(parts[1]) : 0;
        if (h != null) _shiftStart = (h, m ?? 0);
      }
      if (e != null && e.isNotEmpty) {
        final h = int.tryParse(e.split(':')[0]);
        if (h != null) _shiftEnd = h;
      }
    });
  }

  Future<void> _refreshPermission() async {
    final extra = await _approvedPermissionHoursToday();
    if (mounted && extra != _approvedHoursNow) {
      setState(() => _approvedHoursNow = extra);
    }
  }

  (int, int)? _shiftStartFromHistory() {
    for (final r in ref.read(tlAttendanceProvider).history) {
      final lead = r['teamLead'];
      if (lead is Map) {
        final s = lead['shiftStart']?.toString();
        if (s != null && s.isNotEmpty) {
          final parts = s.split(':');
          final h = int.tryParse(parts[0]);
          final m = parts.length > 1 ? int.tryParse(parts[1]) : 0;
          if (h != null) return (h, m ?? 0);
        }
      }
    }
    return null;
  }

  int? _shiftEndFromHistory() {
    for (final r in ref.read(tlAttendanceProvider).history) {
      final lead = r['teamLead'];
      if (lead is Map) {
        final s = lead['shiftEnd']?.toString();
        if (s != null && s.isNotEmpty) {
          final h = int.tryParse(s.split(':')[0]);
          if (h != null) return h;
        }
      }
    }
    return null;
  }

  String _windowText(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    final hh = h % 12 == 0 ? 12 : h % 12;
    return '$hh:${m.toString().padLeft(2, '0')} $period';
  }

  Future<int> _approvedPermissionHoursToday() async {
    final res = await PermissionService.getMyPermissionHistory();
    if (!mounted || res['success'] != true) return 0;
    dynamic d = res['data'];
    Iterable list;
    if (d is List) {
      list = d;
    } else if (d is Map && d['data'] is List) {
      list = d['data'] as List;
    } else {
      return 0;
    }
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    for (final p in list) {
      if (p is Map &&
          (p['status']?.toString().toUpperCase() == 'APPROVED') &&
          (p['permissionDate']?.toString() ?? '').startsWith(today)) {
        final hours = p['durationHours'];
        return hours is num ? hours.toInt() : 1;
      }
    }
    return 0;
  }

  Future<void> _handleCheckIn() async {
    if (_busy) return;
    _busy = true;
    try {
      final start = _shiftStart;
      final shiftHour = start?.$1 ?? 9;
      final shiftMinute = (start?.$2 ?? 0) + 3;
      final extraHours = _approvedHoursNow;
      if (!AttendanceLocationService.isCheckInTimeAllowed(DateTime.now(),
          extraHours: extraHours,
          hour: shiftHour,
          minute: shiftMinute)) {
        final cutoff =
            _windowText(shiftHour * 60 + shiftMinute + extraHours * 60);
        _showError(
            'Check-in closes at $cutoff. You can not check in now.');
        return;
      }
      setState(() => _locating = true);
      final (lat, lng, office) =
          await AttendanceLocationService.verifiedPosition();
      if (!mounted) return;

      final ok = await ref
          .read(tlAttendanceProvider.notifier)
          .checkIn(lat, lng);

      if (mounted) {
        setState(() => _officeName = ok ? office : _officeName);
        final msg = ok
            ? 'Check-in successful ($office)'
            : (ref.read(tlAttendanceProvider).error ?? 'Check-in failed');
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
      _busy = false;
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _handleCheckOut() async {
    if (_busy) return;
    _busy = true;
    setState(() => _locating = true);
    try {
      final ok = await ref
          .read(tlAttendanceProvider.notifier)
          .checkOut();

      if (mounted) {
        final msg = ok
            ? 'Check-out successful'
            : (ref.read(tlAttendanceProvider).error ?? 'Check-out failed');
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
      _busy = false;
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
    if (raw == null) return '--:--';
    try {
      return raw.length >= 16 ? raw.substring(11, 16) : raw;
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final attP = ref.watch(tlAttendanceProvider);
    final last = attP.lastCheck;

    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Attendance',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
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
                Builder(builder: (context) {
                  final extra = _approvedHoursNow;
                  final start = _shiftStart;
                  final end = _shiftEnd;
                  final parts = <String>[];
                  if (start != null) {
                    parts.add(
                        'Check-in: before ${_windowText(start.$1 * 60 + start.$2 + 3 + extra * 60)}');
                  }
                  if (end != null) {
                    parts.add(
                        'Check-out: after ${_windowText(end * 60)}');
                  }
                  var label = parts.join('  �  ');
                  if (extra > 0) {
                    label = 'Permission applied (+$extra hr${extra > 1 ? 's' : ''})${label.isNotEmpty ? ': $label' : ''}';
                  }
                  if (label.isEmpty) return const SizedBox.shrink();
                  return Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 10,
                        height: 1.5),
                  );
                }),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (last != null) ...[
                        _InfoChip(
                            label: 'In',
                            value: _formatTime(
                                last['checkInTime']?.toString())),
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
                    onPressed: attP.isLoading || _locating || _busy
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
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                        context, AppRoutes.tlAttendanceHistory),
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
                                truncate(
                                    (r['attendanceDate']?.toString() ?? r['createdAt']?.toString() ?? ''), 10),
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
