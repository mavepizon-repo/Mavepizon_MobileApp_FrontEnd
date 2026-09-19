import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../providers/admin_dashboard_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/telecalling_call_service.dart';
import '../../../widgets/task_assignment_board.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with RouteAware {
  String _name = '';
  String _profilePhoto = '';
  int _todayCalls = 0;
  bool _routeSubscribed = false;

  @override
  void initState() {
    super.initState();
    _load();
    Future.microtask(() => ref.read(adminDashboardProvider.notifier).fetch());
    Future.microtask(_fetchTodayCalls);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_routeSubscribed) {
      final route = ModalRoute.of(context);
      if (route is PageRoute<dynamic>) {
        _routeSubscribed = true;
        appRouteObserver.subscribe(this, route);
      }
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _refresh();
  }

  void _refresh() {
    Future.microtask(() => ref.read(adminDashboardProvider.notifier).fetch());
    _fetchTodayCalls();
  }

  @override
  void dispose() {
    if (_routeSubscribed) {
      appRouteObserver.unsubscribe(this);
    }
    super.dispose();
  }

  Future<void> _load() async {
    _name = await StorageHelper.getUserName() ?? 'Admin';
    _profilePhoto = await StorageHelper.getUserProfile() ?? '';
    if (mounted) setState(() {});
  }

  Future<void> _fetchTodayCalls() async {
    try {
      final calls = await TelecallingCallService.getLocalCalls();
      if (!mounted) return;
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final count = calls.where((c) {
        if ((c['callStatus']?.toString().toUpperCase() ?? '') != 'COMPLETED') {
          return false;
        }
        final t = DateTime.tryParse(c['startTime']?.toString() ?? '');
        if (t == null) return false;
        final d = '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
        return d == today;
      }).length;
      setState(() => _todayCalls = count);
    } catch (_) {
      // Non-fatal.
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
    final dash = ref.watch(adminDashboardProvider);
    final s = dash.stats;

    String val(String key) => s[key]?.toString() ?? '0';
    String taskVal(String key) {
      final t = s['taskBreakdown'];
      if (t is Map) return t[key]?.toString() ?? '0';
      return '0';
    }

    String anal(String key) {
      final t = s['performanceAnalytics'];
      if (t is Map) return t[key]?.toString() ?? '0';
      return '0';
    }

    return Scaffold(
      
      body: RefreshIndicator(
        onRefresh: () async {
          await _load();
          await ref.read(adminDashboardProvider.notifier).fetch();
        },
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
                                  child: const Text('ADMIN',
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
                                            : 'A',
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
                // -- Dashboard Summary --------------------------
                Text('Dashboard Summary',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPri(context))),
                const SizedBox(height: 12),

                if (dash.error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 18, color: AppColors.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          dash.error ?? '',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                if (dash.isLoading)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )),

                // -- Stats Grid --------------------------------
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _StatCard(
                      title: 'Team Leads',
                      value: val('totalTeamLeads'),
                      icon: Icons.people_rounded,
                      color: AppColors.card1,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.adminTlList),
                    ),
                    _StatCard(
                      title: 'Total Staff',
                      value: val('totalStaff'),
                      icon: Icons.badge_rounded,
                      color: AppColors.card2,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.adminStaffList),
                    ),
                    _StatCard(
                      title: 'Students',
                      value: val('totalStudents'),
                      icon: Icons.school_rounded,
                      color: AppColors.card5,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.adminStudentList),
                    ),
                    _StatCard(
                      title: 'College Staff',
                      value: val('totalCollegeStaff'),
                      icon: Icons.groups_rounded,
                      color: AppColors.card6,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.adminCollegeStaffList),
                    ),
                    _StatCard(
                      title: 'Courses',
                      value: val('totalCourses'),
                      icon: Icons.menu_book_rounded,
                      color: AppColors.card3,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.adminCourseList),
                    ),
                    _StatCard(
                      title: 'Freelancers',
                      value: dash.freelancerCount.toString(),
                      icon: Icons.person_rounded,
                      color: AppColors.card1,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.adminFreelancerList),
                    ),
                    _StatCard(
                      title: 'Freelancer Tasks',
                      value: dash.freelancerTaskCount.toString(),
                      icon: Icons.work_history_rounded,
                      color: AppColors.card5,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.adminFreelancerTaskList),
                    ),
                    _StatCard(
                      title: 'Internships',
                      value: val('totalInternships'),
                      icon: Icons.work_rounded,
                      color: AppColors.card6,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.adminInternshipList),
                    ),
                    _StatCard(
                      title: 'Payments',
                      value: val('totalPayments'),
                      icon: Icons.payments_rounded,
                      color: AppColors.card4,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.adminPaymentList),
                    ),
                    _StatCard(
                      title: 'Certificates',
                      value: val('totalCertificates'),
                      icon: Icons.verified_rounded,
                      color: AppColors.card1,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.adminCertificateList),
                    ),
                    _StatCard(
                      title: 'Assigned Tasks',
                      value: taskVal('assigned'),
                      icon: Icons.assignment_rounded,
                      color: AppColors.card2,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.adminTaskList,
                          arguments: {'status': 'ASSIGNED'}),
                    ),
                    _StatCard(
                      title: 'Completed',
                      value: taskVal('completed'),
                      icon: Icons.task_alt_rounded,
                      color: AppColors.success,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.adminTaskList,
                          arguments: {'status': 'COMPLETED'}),
                    ),
                    _StatCard(
                      title: 'Pending',
                      value: taskVal('totalActivePending'),
                      icon: Icons.hourglass_empty_rounded,
                      color: AppColors.warning,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.adminTaskList,
                          arguments: {'status': 'PENDING'}),
                    ),
                    _StatCard(
                      title: 'Pending Leaves',
                      value: val('totalPendingLeaves'),
                      icon: Icons.event_note_rounded,
                      color: AppColors.warning,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.adminLeaveApproval),
                    ),
                    _StatCard(
                      title: 'Talked Calls',
                      value: '$_todayCalls',
                      icon: Icons.call_rounded,
                      color: AppColors.card6,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.adminTelecallingCalls),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // -- Task Assignments (filterable board) ---------
                TaskAssignmentBoard(isAdmin: true),
                const SizedBox(height: 28),

                // -- Performance Analytics ---------------------
                if (s['performanceAnalytics'] is Map)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
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
                          Text('Performance Analytics',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPri(context))),
                          const SizedBox(height: 16),
                          Row(children: [
                            _AnalyticTile(
                                'Task Completion',
                                '${anal('taskCompletionRatePct')}%',
                                Icons.trending_up_rounded,
                                AppColors.success),
                            const SizedBox(width: 12),
                            _AnalyticTile(
                                'Avg TL Score',
                                anal('averageTeamLeadPerformanceScore'),
                                Icons.star_rounded,
                                AppColors.accent),
                          ]),
                        ]),
                  ),
                const SizedBox(height: 20),

                // -- Quick Actions ------------------------------
                Text('Quick Actions',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPri(context))),
                const SizedBox(height: 14),
                Row(children: [
                  _QuickAction(context, 
                      'Add TL',
                      Icons.person_add_rounded,
                      AppColors.card1,
                      () => Navigator.pushNamed(
                          context, AppRoutes.adminCreateTl)),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'Courses',
                      Icons.menu_book_rounded,
                      AppColors.card2,
                      () => Navigator.pushNamed(
                          context, AppRoutes.adminCourseList)),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'Internships',
                      Icons.work_rounded,
                      AppColors.card3,
                      () => Navigator.pushNamed(
                          context, AppRoutes.adminInternshipList)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _QuickAction(context, 
                      'Payments',
                      Icons.payments_rounded,
                      AppColors.card6,
                      () => Navigator.pushNamed(
                          context, AppRoutes.adminPaymentList)),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'Leave Approvals',
                      Icons.event_note_rounded,
                      AppColors.warning,
                      () => Navigator.pushNamed(
                          context, AppRoutes.adminLeaveApproval)),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'Permissions',
                      Icons.access_time_rounded,
                      AppColors.card3,
                      () => Navigator.pushNamed(
                          context, AppRoutes.adminPermissionApproval)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _QuickAction(context, 
                      'Pending Approval',
                      Icons.pending_actions_rounded,
                      AppColors.card5,
                      () => Navigator.pushNamed(
                          context, AppRoutes.adminStaffList)),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'Calendar',
                      Icons.calendar_month_rounded,
                      AppColors.card5,
                      () => Navigator.pushNamed(
                          context, AppRoutes.adminCalendar)),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'Certificates',
                      Icons.verified_rounded,
                      AppColors.card4,
                      () => Navigator.pushNamed(
                          context, AppRoutes.adminCertificateList)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _QuickAction(context, 
                      'Telecalling Calls',
                      Icons.call_rounded,
                      AppColors.success,
                      () => Navigator.pushNamed(
                          context, AppRoutes.adminTelecallingCalls)),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'Monthly Report',
                      Icons.assessment_rounded,
                      AppColors.card3,
                      () => Navigator.pushNamed(
                          context, AppRoutes.adminMonthlyReport)),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'Pending Approval',
                      Icons.pending_actions_rounded,
                      AppColors.card5,
                      () => Navigator.pushNamed(
                          context, AppRoutes.adminStaffList)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _QuickAction(context, 
                      'Calendar',
                      Icons.calendar_month_rounded,
                      AppColors.card5,
                      () => Navigator.pushNamed(
                          context, AppRoutes.adminCalendar)),
                  _QuickAction(context, 
                      'Freelancers',
                      Icons.person_rounded,
                      AppColors.card1,
                      () => Navigator.pushNamed(
                          context, AppRoutes.adminFreelancerList)),
                ]),
                const SizedBox(height: 28),

                // -- System Status ------------------------------
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('System Status',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPri(context))),
                    ]),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('System Online',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPri(context))),
                    const Spacer(),
                    Text(
                      DateTime.now().toString().substring(0, 19),
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textHi(context)),
                    ),
                  ]),
                ),
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

class _AnalyticTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _AnalyticTile(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSec(context))),
              ]),
        ]),
      ),
    );
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
