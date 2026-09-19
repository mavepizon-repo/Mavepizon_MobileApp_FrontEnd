import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../services/tl_profile_service.dart';
import '../../../services/student_course_service.dart';
import '../../../providers/staff_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/internship_provider.dart';
import '../../../providers/student_provider.dart';
import '../../../providers/permission_provider.dart';
import '../../../providers/certificate_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/task_assignment_board.dart';

class TlDashboardScreen extends ConsumerStatefulWidget {
  const TlDashboardScreen({super.key});
  @override
  ConsumerState<TlDashboardScreen> createState() => _TlDashboardScreenState();
}

class _TlDashboardScreenState extends ConsumerState<TlDashboardScreen> {
  String _name = '';
  String _profilePhoto = '';
  int _courseRegsCount = 0;
  int _intRegsCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _name = await StorageHelper.getUserName() ?? 'Team Lead';
    final res = await TlProfileService.getProfile();
    if (res['success'] == true) {
      final d = res['data'] is Map ? res['data'] as Map<String, dynamic> : {};
      _name = d['name']?.toString() ?? _name;
      _profilePhoto = d['profilePhoto']?.toString() ?? '';
    }

    // -- Course & Internship registrations (frontend only) -----
    try {
      final regs = await StudentCourseService.getAllRegistrations();
      if (regs['success'] == true && regs['data'] is List) {
        _courseRegsCount = (regs['data'] as List).length;
      }
    } catch (e) {
      debugPrint('Course registrations count failed: $e');
    }
    try {
      final cert = ref.read(certificateProvider);
      if (cert.list.isEmpty) await cert.fetch();
      _intRegsCount = cert.list
          .where((c) => c.type.toUpperCase() == 'INTERNSHIP')
          .length;
    } catch (e) {
      debugPrint('Internship registrations count failed: $e');
    }

    if (mounted) setState(() {});
    if (!mounted) return;

    ref.read(staffProvider.notifier).fetch();
    ref.read(taskProvider.notifier).fetch();
    ref.read(courseProvider.notifier).fetch();
    ref.read(internshipProvider.notifier).fetch();
    ref.read(studentProvider.notifier).fetchAll();
    ref.read(permissionProvider.notifier).fetchBranchPermissions();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final sp = ref.watch(staffProvider);
    final tp = ref.watch(taskProvider);
    final cp = ref.watch(courseProvider);
    final ip = ref.watch(internshipProvider);
    final pp = ref.watch(permissionProvider);

    final totalStaff = sp.allStaff.length;
    final totalTasks = tp.allTasks.length;
    final pending = tp.allTasks.where((t) => t.status == 'PENDING').length;
    final completed = tp.allTasks.where((t) => t.status == 'COMPLETED').length;

    return Scaffold(
      
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.accent,
        child: CustomScrollView(slivers: [
          // -- Header ------------------------------------------
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
                                Text(_name,
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
                                  child: const Text('TEAM LEAD',
                                      style: TextStyle(
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
                            child: _profilePhoto.isNotEmpty
                                ? CircleAvatar(
                                    radius: 25,
                                    backgroundImage:
                                        NetworkImage(_profilePhoto))
                                : Center(
                                    child: Text(
                                        _name.isNotEmpty
                                            ? _name[0].toUpperCase()
                                            : 'T',
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
                // -- Stats Grid --------------------------------
                // ? FIX: Document Dashboard has 6 items:
                // Total Staff, Total Tasks, Pending Tasks, Completed Tasks,
                // Course Registrations, Internship Registrations.
                // Since backend returns one combined student list (no split),
                // we show "Total Students" once instead of two duplicate cards.
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _StatCard(
                      title: 'Total Staff',
                      value: '$totalStaff',
                      icon: Icons.people_rounded,
                      color: AppColors.card1,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.tlStaffList),
                    ),
                    _StatCard(
                      title: 'Total Tasks',
                      value: '$totalTasks',
                      icon: Icons.task_alt_rounded,
                      color: AppColors.card2,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.tlTaskList),
                    ),
                    _StatCard(
                      title: 'Pending Tasks',
                      value: '$pending',
                      icon: Icons.hourglass_empty_rounded,
                      color: AppColors.card5,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.tlTaskList),
                    ),
                    _StatCard(
                      title: 'Completed',
                      value: '$completed',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.card3,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.tlTaskList),
                    ),
                    _StatCard(
                      title: 'Course Registrations',
                      value: '$_courseRegsCount',
                      icon: Icons.menu_book_rounded,
                      color: AppColors.card6,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.tlStudentMonitor),
                    ),
                    _StatCard(
                      title: 'Internship Registrations',
                      value: '$_intRegsCount',
                      icon: Icons.work_rounded,
                      color: AppColors.card4,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.tlStudentMonitor),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // -- Task Assignments (filterable board) ---------
                TaskAssignmentBoard(isAdmin: false),
                const SizedBox(height: 28),

                // -- Quick Actions ------------------------------
                Text('Quick Actions',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPri(context))),
                const SizedBox(height: 14),
                Row(children: [
                  _QuickAction(context, 
                      'Add Staff',
                      Icons.person_add_rounded,
                      AppColors.card1,
                      () =>
                          Navigator.pushNamed(context, AppRoutes.tlCreateStaff)
                              .then((_) => sp.fetch())),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'Assign Task',
                      Icons.add_task_rounded,
                      AppColors.card2,
                      () => Navigator.pushNamed(context, AppRoutes.tlAssignTask)
                          .then((_) => tp.fetch())),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'New Course',
                      Icons.add_circle_rounded,
                      AppColors.card3,
                      () =>
                          Navigator.pushNamed(context, AppRoutes.tlCreateCourse)
                              .then((_) => cp.fetch())),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'Internship',
                      Icons.work_rounded,
                      AppColors.card6,
                      () => Navigator.pushNamed(
                              context, AppRoutes.tlCreateInternship)
                          .then((_) => ip.fetch())),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _QuickAction(context, 
                      'Staff Leave',
                      Icons.event_note_rounded,
                      AppColors.warning,
                      () => Navigator.pushNamed(
                          context, AppRoutes.tlLeaveManagement)),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'Permissions',
                      Icons.access_time_rounded,
                      AppColors.card3,
                      () => Navigator.pushNamed(
                          context, AppRoutes.tlPermissionManagement)),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'My Leave',
                      Icons.logout_rounded,
                      AppColors.card6,
                      () => Navigator.pushNamed(
                          context, AppRoutes.tlApplyLeave)),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'My Permission',
                      Icons.timer_rounded,
                      AppColors.card5,
                      () => Navigator.pushNamed(
                          context, AppRoutes.tlApplyPermission)),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'Attendance',
                      Icons.fingerprint_rounded,
                      AppColors.card2,
                      () => Navigator.pushNamed(
                          context, AppRoutes.tlAttendance)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _QuickAction(context, 
                      'Monthly Report',
                      Icons.assessment_rounded,
                      AppColors.card3,
                      () => Navigator.pushNamed(
                          context, AppRoutes.tlMonthlyReport)),
                  _QuickAction(context, 
                      'Task Review',
                      Icons.fact_check_rounded,
                      AppColors.card1,
                      () => Navigator.pushNamed(
                          context, AppRoutes.tlTaskReview)),
                ]),
                const SizedBox(height: 28),

                // -- Recent Tasks -------------------------------
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Tasks',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPri(context))),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.tlTaskList),
                        child: const Text('View all',
                            style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                const SizedBox(height: 12),
                if (tp.isLoading)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent, strokeWidth: 2)))
                else if (tp.allTasks.isEmpty)
                  Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16)),
                      child: Center(
                          child: Text('No tasks yet',
                              style: TextStyle(color: AppColors.textHi(context)))))
                else
                  ...tp.allTasks.take(5).map((t) => _TaskRow(
                      task: t,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.tlTaskDetail,
                          arguments: {'taskId': t.id}))),
                const SizedBox(height: 28),

                // -- Pending Permissions -------------------------
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Text('Pending Permissions',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPri(context))),
                        if (pp.pendingPermissions.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${pp.pendingPermissions.length}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.warning)),
                          ),
                        ],
                      ]),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.tlPermissionManagement),
                        child: const Text('Manage',
                            style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                const SizedBox(height: 12),
                if (pp.isLoading)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent, strokeWidth: 2)))
                else if (pp.pendingPermissions.isEmpty)
                  Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16)),
                      child: Center(
                          child: Text('No pending permission requests',
                              style:
                                  TextStyle(color: AppColors.textHi(context)))))
                else
                  ...pp.pendingPermissions.take(5).map((p) =>
                      _PendingPermissionRow(
                        permission: p,
                        onApprove: () => _approvePermission(p),
                        onReject: () => _rejectPermission(p),
                      )),
                const SizedBox(height: 28),

                // -- Recent Staff -------------------------------
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('My Staff',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPri(context))),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.tlStaffList),
                        child: const Text('View all',
                            style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                const SizedBox(height: 12),
                if (sp.allStaff.isEmpty)
                  Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16)),
                      child: Center(
                          child: Text('No staff yet',
                              style: TextStyle(color: AppColors.textHi(context)))))
                else
                  ...sp.allStaff.take(3).map((s) => _StaffRow(
                      staff: s,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.tlStaffDetail,
                          arguments: {'staffId': s.id}))),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _approvePermission(dynamic p) async {
    final name = _staffName(p);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      final success = await ref
          .read(permissionProvider.notifier)
          .approvePermission(p['id']?.toString() ?? '');
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

  Future<void> _rejectPermission(dynamic p) async {
    final name = _staffName(p);
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      final remarks = controller.text.isNotEmpty
          ? controller.text
          : 'Rejected by Team Lead';
      final success = await ref
          .read(permissionProvider.notifier)
          .rejectPermission(p['id']?.toString() ?? '', remarks);
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
}

// -- Stat Card --------------------------------------------------
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

// -- Quick Action -----------------------------------------------
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

// -- Task Row ---------------------------------------------------
class _TaskRow extends StatelessWidget {
  final dynamic task;
  final VoidCallback onTap;
  const _TaskRow({required this.task, required this.onTap});

  Color get _pColor => task.priority == 'HIGH'
      ? AppColors.error
      : task.priority == 'MEDIUM'
          ? AppColors.warning
          : AppColors.success;

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
                    color: _pColor, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(task.title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPri(context))),
                  const SizedBox(height: 3),
                  Text(
                      'Due: ${task.deadline.toString().length >= 10 ? task.deadline.toString().substring(0, 10) : task.deadline}',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textHi(context))),
                ])),
            StatusBadge(status: task.status),
          ]),
        ),
      );
}

// -- Staff Row --------------------------------------------------
class _StaffRow extends StatelessWidget {
  final dynamic staff;
  final VoidCallback onTap;
  const _StaffRow({required this.staff, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
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
            CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: staff.profilePhoto != null &&
                        staff.profilePhoto!.isNotEmpty
                    ? NetworkImage(staff.profilePhoto!)
                    : null,
                child: staff.profilePhoto == null ||
                        staff.profilePhoto!.isEmpty
                    ? Text(
                        staff.name.isNotEmpty
                            ? staff.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary))
                    : null),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(staff.name,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPri(context))),
                  Text(staff.role,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSec(context))),
                ])),
            StatusBadge(status: staff.status),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textHi(context), size: 20),
          ]),
        ),
      );
}

// -- Pending Permission Row -------------------------------------
class _PendingPermissionRow extends StatelessWidget {
  final dynamic permission;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingPermissionRow({
    required this.permission,
    required this.onApprove,
    required this.onReject,
  });

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

  @override
  Widget build(BuildContext context) {
    final name = _staffName(permission);
    final reason = permission['reason']?.toString() ?? '';
    final date = _formatDate(permission['permissionDate']);
    final hours = permission['durationHours']?.toString() ?? '1';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.warning.withOpacity(0.4), width: 1.2),
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
                  radius: 18,
                  backgroundColor: AppColors.card6.withOpacity(0.15),
                  child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.card6))),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(name,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPri(context))),
                    Text('$date \u2022 $hours hr',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textHi(context))),
                  ])),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('PENDING',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning)),
              ),
            ]),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSec(context))),
              ),
            ],
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: onApprove,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded,
                              size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Approve',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ]),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: onReject,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close_rounded,
                              size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Reject',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ]),
                  ),
                ),
              ),
            ]),
          ]),
    );
  }
}
