import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../core/utils/string_utils.dart';
import '../../../providers/staff_task_provider.dart';
import '../../../providers/staff_attendance_provider.dart';
import '../../../providers/staff_profile_provider.dart';
import '../../../providers/trainer_provider.dart';
import '../../../services/trainer_service.dart';
import '../../../services/telecaller_service.dart';
import '../../../services/certificate_service.dart';
import '../../../routes/app_routes.dart';

class StaffDashboardScreen extends ConsumerStatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  ConsumerState<StaffDashboardScreen> createState() =>
      _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends ConsumerState<StaffDashboardScreen> {
  String _name = '';
  String _role = '';
  String _category = '';
  String _staffId = '';
  int _totalStudents = 0;
  int _enquiryCount = 0;
  int _todayFollowups = 0;
  int _newContacts = 0;
  int _certEligible = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _staffRoleFromTasks(List<dynamic> tasks) {
    for (final t in tasks) {
      final r = t['staffRole']?.toString() ?? '';
      if (r.isNotEmpty) return r;
    }
    return '';
  }

  String _staffNameFromTasks(List<dynamic> tasks) {
    for (final t in tasks) {
      final n = t['staffName']?.toString() ?? '';
      if (n.isNotEmpty) return n;
    }
    final name = ref.read(staffAttendanceProvider).history;
    for (final r in name) {
      final n = r['staffName']?.toString() ?? '';
      if (n.isNotEmpty) return n;
    }
    return '';
  }

  String _resolveDesignation(StaffProfileProvider profP, List<dynamic> tasks) {
    if (profP.role.isNotEmpty) return profP.role;
    if (profP.category.isNotEmpty) return profP.category;
    final fromTasks = _staffRoleFromTasks(tasks);
    if (fromTasks.isNotEmpty) return fromTasks;
    if (_category.isNotEmpty) return _category;
    return _role;
  }

  /// Best-effort role/category key used to route to the correct dashboard.
  /// The backend exposes the staff category via the task's `staffRole`
  /// (populated from `staff.getCategory()`), so that is the most reliable
  /// source; login/profile return only the generic "OFFICE_STAFF" role.
  String _staffRoleKey(StaffProfileProvider profP, List<dynamic> tasks) {
    final fromTasks = _staffRoleFromTasks(tasks).trim().toUpperCase();
    if (fromTasks == 'TELECOM_SERVICE' ||
        fromTasks == 'DEVELOPER_TRAINER' ||
        fromTasks == 'DEVELOPER' ||
        fromTasks == 'DESIGNER' ||
        fromTasks == 'FREELANCER') {
      return fromTasks;
    }
    if (profP.category.trim().isNotEmpty) return profP.category;
    if (_category.trim().isNotEmpty) return _category;
    final r = profP.role.trim().toUpperCase();
    if (r == 'TELECOM_SERVICE' ||
        r == 'DEVELOPER_TRAINER' ||
        r == 'DEVELOPER' ||
        r == 'DESIGNER' ||
        r == 'FREELANCER') {
      return r;
    }
    if (fromTasks.isNotEmpty) return fromTasks;
    return _role;
  }

  Future<void> _load() async {
    _name = await StorageHelper.getUserName() ?? 'Office Staff';
    _role = await StorageHelper.getRole() ?? '';
    _category = await StorageHelper.getStaffCategory() ?? '';
    _staffId = await StorageHelper.getStaffId() ?? '';

    if (mounted) setState(() {});

    if (_staffId.isNotEmpty) {
      ref.read(staffAttendanceProvider.notifier).fetchHistory();
      ref.read(staffProfileProvider.notifier).fetch(_staffId);
      await ref.read(staffTaskProvider.notifier).fetch(_staffId);
      final realName = _staffNameFromTasks(ref.read(staffTaskProvider).tasks);
      if (realName.isNotEmpty && mounted) {
        setState(() => _name = realName);
      }
      try {
        final enquiries = await TelecallerService.getEnquiries(_staffId);
        if (enquiries['success'] == true && enquiries['data'] is List) {
          final list = enquiries['data'] as List;
          _enquiryCount = list.length;
          _newContacts = list
              .where((e) =>
                  (e['status']?.toString().toUpperCase() ?? '') == 'NEW')
              .length;
        }
        final followups = await TelecallerService.getTodayFollowups(_staffId);
        if (followups['success'] == true && followups['data'] is List) {
          _todayFollowups = (followups['data'] as List).length;
        }
      } catch (e) {
        debugPrint('Telecaller dashboard counts failed: $e');
      }
      final roleFromTasks =
          _staffRoleFromTasks(ref.read(staffTaskProvider).tasks);
      if (roleFromTasks == 'DEVELOPER_TRAINER') {
        ref.read(trainerProvider.notifier).fetchDashboard(_staffId);
        try {
          final result = await TrainerService.getBatches(_staffId);
          if (result['success'] == true && result['data'] is List) {
            _totalStudents = (result['data'] as List)
                .fold<int>(0, (sum, b) => sum + ((b['studentCount'] as num?)?.toInt() ?? 0));
          }
        } catch (e) {
          debugPrint('Trainer dashboard counts failed: $e');
        }
        if (mounted) setState(() {});
      }
      if (_category.toUpperCase() == 'DESIGNER') {
        try {
          final allResult = await CertificateService.getAllRegistrations();
          if (allResult['success'] == true && allResult['data'] is List) {
            final list = (allResult['data'] as List).where((e) {
              if (e is! Map) return false;
              final status =
                  (e['paymentStatus']?.toString().toUpperCase() ?? '');
              return status == 'PAID' ||
                  status == 'SUCCESS' ||
                  status == 'COMPLETED';
            });
            _certEligible = list.length;
          }
        } catch (e) {
          debugPrint('Designer certificate count failed: $e');
        }
        if (mounted) setState(() {});
      }
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final taskP = ref.watch(staffTaskProvider);
    final profP = ref.watch(staffProfileProvider);
    final trainerP = ref.watch(trainerProvider);
    final attP = ref.watch(staffAttendanceProvider);

    final designation = _resolveDesignation(profP, taskP.tasks);
    final roleKey = _staffRoleKey(profP, taskP.tasks).toUpperCase();
    final isTrainer = roleKey == 'DEVELOPER_TRAINER' ||
        _category.toUpperCase() == 'DEVELOPER_TRAINER';
    final isTelecaller = roleKey == 'TELECOM_SERVICE' ||
        _category.toUpperCase() == 'TELECOM_SERVICE' ||
        _role.toUpperCase() == 'TELECOM_SERVICE';
    final isDesigner = roleKey == 'DESIGNER' ||
        _category.toUpperCase() == 'DESIGNER' ||
        _role.toUpperCase() == 'DESIGNER';
    final isCheckedIn = attP.isCheckedIn;

    return Scaffold(
      
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.accent,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 20, 20, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_greeting(),
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.65),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(profP.name.isNotEmpty ? profP.name : _name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Text(designation,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.5)),
                                ),
                              ]),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2)),
                            child: profP.profilePhoto.isNotEmpty
                                ? CircleAvatar(
                                    radius: 25,
                                    backgroundImage:
                                        NetworkImage(profP.profilePhoto))
                                : Center(
                                    child: Text(
                                        (profP.name.isNotEmpty
                                                ? profP.name
                                                : _name)
                                            .isNotEmpty
                                            ? (profP.name.isNotEmpty
                                                    ? profP.name
                                                    : _name)[0]
                                                .toUpperCase()
                                            : 'S',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800))),
                          ),
                        ]),
                  ]),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: isTrainer
                      ? [
                          _StatCard(
                            title: 'Batches',
                            value: '${trainerP.dashboard?['assignedBatches'] ?? 0}',
                            icon: Icons.groups_rounded,
                            color: AppColors.accent,
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.trainerBatches),
                          ),
                          _StatCard(
                            title: 'Online',
                            value: '${trainerP.dashboard?['onlineBatches'] ?? 0}',
                            icon: Icons.wifi_rounded,
                            color: AppColors.card3,
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.trainerBatches),
                          ),
                          _StatCard(
                            title: 'Offline',
                            value: '${trainerP.dashboard?['offlineBatches'] ?? 0}',
                            icon: Icons.school_rounded,
                            color: AppColors.card5,
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.trainerBatches),
                          ),
                          _StatCard(
                            title: "Today's Att.",
                            value: '${trainerP.dashboard?['attendanceToday'] ?? 0}',
                            icon: Icons.check_circle_rounded,
                            color: AppColors.success,
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.trainerBatches),
                          ),
                          _StatCard(
                            title: 'Students',
                            value: '$_totalStudents',
                            icon: Icons.people_rounded,
                            color: AppColors.card4,
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.trainerBatches),
                          ),
                        ]
                      : [],
                ),
                if (isTelecaller && !isTrainer) ...[
                  const SizedBox(height: 28),
                  Row(children: [
                    Expanded(
                      child: _SummaryTile(
                          '$_newContacts',
                          'New Contact',
                          Icons.person_add_alt_1_rounded,
                          AppColors.card1,
                          onTap: () async {
                            await Navigator.pushNamed(context,
                                AppRoutes.telecallerEnquiryDetail,
                                arguments: {'mode': 'create'});
                            _load();
                          }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryTile(
                          '$_enquiryCount',
                          'Enquiries',
                          Icons.contact_phone_rounded,
                          AppColors.card4,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.telecallerEnquiries)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryTile(
                          '$_todayFollowups',
                          'Today Follow-up',
                          Icons.pending_actions_rounded,
                          AppColors.card6,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.telecallerFollowups)),
                    ),
                  ]),
                ],
                if (!isTrainer && !isTelecaller) ...[
                  const SizedBox(height: 28),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _StatCard(
                        title: 'Attendance',
                        value:
                            isCheckedIn ? 'Checked In' : 'Not Checked In',
                        icon: Icons.fingerprint_rounded,
                        color:
                            isCheckedIn ? AppColors.success : AppColors.card5,
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.staffAttendance),
                      ),
                      _StatCard(
                        title: 'Pending Tasks',
                        value: '${taskP.pendingTasks.length}',
                        icon: Icons.hourglass_empty_rounded,
                        color: AppColors.card5,
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.staffTaskList),
                      ),
                      _StatCard(
                        title: 'Completed',
                        value: '${taskP.completedTasks.length}',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.card3,
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.staffTaskList),
                      ),
                      _StatCard(
                        title: 'Performance',
                        value: '${profP.score}%',
                        icon: Icons.trending_up_rounded,
                        color: AppColors.card6,
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.staffProfile),
                      ),
                    ],
                  ),
                ],
                if (isDesigner) ...[
                  const SizedBox(height: 16),
                  _DesignerCertificateBanner(
                      eligibleCount: _certEligible,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.staffCertificates)),
                ],
                const SizedBox(height: 28),

                Text('Quick Actions',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPri(context))),
                const SizedBox(height: 14),
                Row(children: [
                  _QuickAction(context, 
                      'Check In',
                      Icons.login_rounded,
                      AppColors.card3,
                      () => Navigator.pushNamed(
                          context, AppRoutes.staffAttendance)),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'Apply Leave',
                      Icons.event_note_rounded,
                      AppColors.warning,
                      () => Navigator.pushNamed(
                          context, AppRoutes.staffApplyLeave)),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'Permission',
                      Icons.access_time_rounded,
                      AppColors.card5,
                      () => Navigator.pushNamed(
                          context, AppRoutes.staffApplyPermission)),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'My Tasks',
                      Icons.task_alt_rounded,
                      AppColors.card2,
                      () => Navigator.pushNamed(
                          context, AppRoutes.staffTaskList)),
                ]),
                const SizedBox(height: 10),
                if (isTelecaller && !isTrainer) ...[
                  Row(children: [
                    _QuickAction(context, 
                        'Enquiries',
                        Icons.contact_phone_rounded,
                        AppColors.card4,
                        () => Navigator.pushNamed(
                            context, AppRoutes.telecallerEnquiries)),
                    const SizedBox(width: 10),
                    _QuickAction(context, 
                        'Follow Ups',
                        Icons.repeat_rounded,
                        AppColors.card1,
                        () => Navigator.pushNamed(
                            context, AppRoutes.telecallerFollowups)),
                    const SizedBox(width: 10),
                    _QuickAction(context, 
                        'New Contact',
                        Icons.person_add_alt_1_rounded,
                        AppColors.card6,
                        () => Navigator.pushNamed(
                            context, AppRoutes.telecallerEnquiryDetail,
                            arguments: {'mode': 'create'})),
                  ]),
                ] else if (isTrainer) ...[
                  Row(children: [
                    _QuickAction(context, 
                        'Batches',
                        Icons.groups_rounded,
                        AppColors.card6,
                        () => Navigator.pushNamed(
                            context, AppRoutes.trainerBatches)),
                    const SizedBox(width: 10),
                    _QuickAction(context, 
                        'Materials',
                        Icons.folder_rounded,
                        AppColors.card3,
                        () => Navigator.pushNamed(
                            context, AppRoutes.trainerMaterials)),
                  ]),
                ],
                const SizedBox(height: 28),

                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('My Tasks',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPri(context))),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.staffTaskList),
                        child: const Text('View all',
                            style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                const SizedBox(height: 12),
                if (taskP.isLoading)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent, strokeWidth: 2)))
                else if (taskP.tasks.isEmpty)
                  Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16)),
                      child: Center(
                          child: Text('No tasks assigned yet',
                              style: TextStyle(color: AppColors.textHi(context)))))
                else
                  ...taskP.tasks.take(5).map((t) => _TaskRow(
                      task: t,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.staffTaskDetail,
                           arguments: {'taskId': t['taskId']?.toString() ?? t['id']?.toString() ?? ''}))),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _SummaryTile(this.value, this.label, this.icon, this.color,
      {this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.85)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 8),
        Text(label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ]),
    ));
  }
}

Widget _QuickAction(context, 
    String label, IconData icon, Color color, VoidCallback onTap) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(children: [
          Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSec(context))),
        ]),
      ),
    ),
  );
}

class _DesignerCertificateBanner extends StatelessWidget {
  final int eligibleCount;
  final VoidCallback onTap;
  const _DesignerCertificateBanner(
      {required this.eligibleCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD4AF37), Color(0xFFB8860B), Color(0xFF8B5E00)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFB8860B).withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Certificate Studio',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(
                    '$eligibleCount paid student(s) eligible for certificates',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white, size: 16),
        ]),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final dynamic task;
  final VoidCallback onTap;
  const _TaskRow({required this.task, required this.onTap});

  String get _title => task['title']?.toString() ?? 'Untitled';
  String get _status => task['status']?.toString().toUpperCase() ?? 'PENDING';
  String get _deadline {
    final d = truncate(task['deadline']?.toString() ?? task['dueDate']?.toString(), 10);
    return d.isEmpty ? 'No deadline' : d;
  }
  int get _progress => task['progress'] ?? 0;

  Color get _statusColor {
    switch (_status) {
      case 'COMPLETED':
        return AppColors.success;
      case 'IN_PROGRESS':
        return AppColors.accent;
      case 'REVIEW':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
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
                height: 40,
                decoration: BoxDecoration(
                    color: _statusColor,
                    borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPri(context))),
                      const SizedBox(height: 4),
                      Row(children: [
                        Text(_status,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _statusColor)),
                        const SizedBox(width: 8),
                        Text(_deadline,
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textHi(context))),
                      ]),
                    ])),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('$_progress%',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ),
          ]),
        ),
      );
}
