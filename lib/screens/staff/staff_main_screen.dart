import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import 'dashboard/staff_dashboard_screen.dart';
import 'attendance/staff_attendance_screen.dart';
import 'tasks/staff_task_list_screen.dart';
import 'profile/staff_profile_screen.dart';
import 'permissions/staff_apply_permission_screen.dart';
import 'permissions/staff_permission_history_screen.dart';
import 'leave/staff_apply_leave_screen.dart';
import 'leave/staff_leave_history_screen.dart';

class StaffMainScreen extends StatefulWidget {
  const StaffMainScreen({super.key});

  @override
  State<StaffMainScreen> createState() => _StaffMainScreenState();
}

class _StaffMainScreenState extends State<StaffMainScreen> {
  int _index = 0;

  final List<Widget> _screens = const [
    StaffDashboardScreen(),
    StaffAttendanceScreen(),
    StaffTaskListScreen(),
    StaffProfileScreen(),
  ];

  final List<Widget> _permissionScreens = const [
    StaffApplyPermissionScreen(),
    StaffPermissionHistoryScreen(),
  ];

  final List<Widget> _leaveScreens = const [
    StaffApplyLeaveScreen(),
    StaffLeaveHistoryScreen(),
  ];

  int _permissionTabIndex = 0;
  int _leaveTabIndex = 0;

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
        body: IndexedStack(
          index: _index,
          children: [
            _screens[0],
            _screens[1],
            _screens[2],
            _permissionScreens[_permissionTabIndex],
            _leaveScreens[_leaveTabIndex],
            _screens[3],
          ],
        ),
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
                  Expanded(
                    child: _NavItem(
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      index: 0,
                      current: _index,
                      onTap: () => setState(() => _index = 0),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.fingerprint_rounded,
                      label: 'Attendance',
                      index: 1,
                      current: _index,
                      onTap: () => setState(() => _index = 1),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.task_alt_rounded,
                      label: 'Tasks',
                      index: 2,
                      current: _index,
                      onTap: () => setState(() => _index = 2),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.access_time_rounded,
                      label: 'Permission',
                      index: 3,
                      current: _index,
                      onTap: () => setState(() => _index = 3),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.event_busy_rounded,
                      label: 'Leave',
                      index: 4,
                      current: _index,
                      onTap: () => setState(() => _index = 4),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      index: 5,
                      current: _index,
                      onTap: () => setState(() => _index = 5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
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