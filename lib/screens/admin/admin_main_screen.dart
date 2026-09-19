import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../routes/app_routes.dart';
import 'dashboard/admin_dashboard_screen.dart';
import 'team_lead/admin_tl_list_screen.dart';
import 'staff/admin_staff_list_screen.dart';
import 'students/admin_student_list_screen.dart';
import 'courses/admin_course_list_screen.dart';
import 'internships/admin_internship_list_screen.dart';
import 'payments/admin_payment_list_screen.dart';
import 'certificates/admin_certificate_list_screen.dart';
import 'leave/admin_leave_approval_screen.dart';
import 'permissions/admin_permission_approval_screen.dart';
import 'calendar/admin_calendar_screen.dart';
import 'holidays/admin_holidays_screen.dart';
import 'profile/admin_profile_screen.dart';
import 'college_staff/admin_college_staff_list_screen.dart';
import 'courses/admin_registration_list_screen.dart';
import 'courses/admin_offered_course_list_screen.dart';
import 'freelancer/admin_freelancer_list_screen.dart';
import 'freelancer/admin_freelancer_task_list_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _index = 0;

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    AdminTlListScreen(),
    AdminStaffListScreen(),
    AdminStudentListScreen(),
    AdminCourseListScreen(),
  ];

  Future<bool> _onWillPop() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Press back again to exit'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final exit = await _onWillPop();
        if (exit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    index: 0,
                    current: _index,
                    onTap: () => setState(() => _index = 0),
                  ),
                  _NavItem(
                    icon: Icons.people_rounded,
                    label: 'TLs',
                    index: 1,
                    current: _index,
                    onTap: () => setState(() => _index = 1),
                  ),
                  _NavItem(
                    icon: Icons.badge_rounded,
                    label: 'Staff',
                    index: 2,
                    current: _index,
                    onTap: () => setState(() => _index = 2),
                  ),
                  _NavItem(
                    icon: Icons.school_rounded,
                    label: 'Students',
                    index: 3,
                    current: _index,
                    onTap: () => setState(() => _index = 3),
                  ),
                  _NavItem(
                    icon: Icons.menu_book_rounded,
                    label: 'Courses',
                    index: 4,
                    current: _index,
                    onTap: () => setState(() => _index = 4),
                  ),
                  _NavItem(
                    icon: Icons.more_horiz_rounded,
                    label: 'More',
                    index: 5,
                    current: _index,
                    onTap: () => _showMoreMenu(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('More Options',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPri(context))),
              const SizedBox(height: 20),
              _MoreTile(Icons.work_rounded, 'Internships', AppColors.card6,
                  () => _navTo(ctx, const AdminInternshipListScreen())),
              _MoreTile(Icons.payments_rounded, 'Payments', AppColors.card4,
                  () => _navTo(ctx, const AdminPaymentListScreen())),
              _MoreTile(Icons.verified_rounded, 'Certificates', AppColors.card1,
                  () => _navTo(ctx, const AdminCertificateListScreen())),
              _MoreTile(Icons.event_note_rounded, 'Leave Approvals', AppColors.warning,
                  () => _navTo(ctx, const AdminLeaveApprovalScreen())),
              _MoreTile(Icons.access_time_rounded, 'Permission Approvals', AppColors.card3,
                  () => _navTo(ctx, const AdminPermissionApprovalScreen())),
              _MoreTile(Icons.calendar_month_rounded, 'Calendar', AppColors.card5,
                  () => _navTo(ctx, const AdminCalendarScreen())),
              _MoreTile(Icons.celebration_rounded, 'Holidays', AppColors.card2,
                  () => _navTo(ctx, const AdminHolidaysScreen())),
              _MoreTile(Icons.assignment_ind_rounded, 'Registrations', AppColors.card3,
                  () => _navTo(ctx, const AdminRegistrationListScreen())),
              _MoreTile(Icons.storefront_rounded, 'Offered Courses', AppColors.card5,
                  () => _navTo(ctx, const AdminOfferedCourseListScreen())),
              _MoreTile(Icons.groups_rounded, 'College Staff', AppColors.card6,
                  () => _navTo(ctx, const AdminCollegeStaffListScreen())),
              _MoreTile(Icons.person_search_rounded, 'Freelancers', AppColors.card3,
                  () => _navTo(ctx, const AdminFreelancerListScreen())),
              _MoreTile(Icons.work_history_rounded, 'Freelancer Tasks', AppColors.card5,
                  () => _navTo(ctx, const AdminFreelancerTaskListScreen())),
              _MoreTile(Icons.person_rounded, 'Profile', AppColors.primary,
                  () => _navTo(ctx, const AdminProfileScreen())),
              const SizedBox(height: 12),
            ],
          ),
        ),
        ),
      ),
    );
  }

  void _navTo(BuildContext ctx, Widget screen) {
    Navigator.pop(ctx);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index, current;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.primary : AppColors.textHi(context),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textHi(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MoreTile(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.textPri(context))),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textHi(context)),
      onTap: onTap,
    );
  }
}
