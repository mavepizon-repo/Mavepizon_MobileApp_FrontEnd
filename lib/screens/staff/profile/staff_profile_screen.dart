import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../providers/staff_profile_provider.dart';
import '../../../providers/staff_task_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/logout_dialog.dart';
import '../../../widgets/theme_toggle_tile.dart';

class StaffProfileScreen extends ConsumerStatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  ConsumerState<StaffProfileScreen> createState() =>
      _StaffProfileScreenState();
}

class _StaffProfileScreenState extends ConsumerState<StaffProfileScreen> {
  String _name = '';
  String _email = '';
  String _role = '';
  String _category = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _name = await StorageHelper.getUserName() ?? 'Office Staff';
    _email = await StorageHelper.getUserEmail() ?? '';
    _role = await StorageHelper.getRole() ?? '';
    _category = await StorageHelper.getStaffCategory() ?? '';
    final staffId = await StorageHelper.getStaffId() ?? '';
    if (staffId.isNotEmpty) {
      ref.read(staffProfileProvider.notifier).fetch(staffId);
    }
    if (mounted) setState(() {});
  }

  String _roleFromTasks(List<dynamic> tasks) {
    for (final t in tasks) {
      final r = t['staffRole']?.toString() ?? '';
      if (r.isNotEmpty) return r;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final profP = ref.watch(staffProfileProvider);
    final taskP = ref.watch(staffTaskProvider);
    final roleFromTasks = _roleFromTasks(taskP.tasks);
    final designation = profP.role.isNotEmpty
        ? profP.role
        : profP.category.isNotEmpty
            ? profP.category
            : roleFromTasks.isNotEmpty
                ? roleFromTasks
                : _category.isNotEmpty
                    ? _category
                    : _role;
    return Scaffold(
      
      body: CustomScrollView(slivers: [
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
            child: Column(children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 40,
                backgroundImage: profP.profilePhoto.isNotEmpty
                    ? NetworkImage(profP.profilePhoto)
                    : null,
                backgroundColor: AppColors.accent.withOpacity(0.3),
                child: profP.profilePhoto.isEmpty
                    ? Text(
                        _name.isNotEmpty
                            ? _name[0].toUpperCase()
                            : profP.name.isNotEmpty
                                ? profP.name[0].toUpperCase()
                                : 'S',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800))
                    : null,
              ),
              const SizedBox(height: 16),
              Text(profP.name.isNotEmpty ? profP.name : _name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(profP.email.isNotEmpty ? profP.email : _email,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.65), fontSize: 14)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.lock_rounded,
                label: 'Change Password',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.changePassword),
              ),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.fingerprint_rounded,
                label: 'Attendance History',
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.staffAttendanceHistory),
              ),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.event_note_rounded,
                label: 'Leave History',
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.staffLeaveHistory),
              ),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.access_time_rounded,
                label: 'Permission History',
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.staffPermissionHistory),
              ),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.leaderboard_rounded,
                label: 'Performance & Reports',
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.staffPerformance),
              ),
              const SizedBox(height: 8),
              const ThemeToggleTile(),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.logout_rounded,
                label: 'Logout',
                textColor: AppColors.error,
                iconColor: AppColors.error,
                onTap: () => logoutWithConfirmation(context, ref),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? textColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.textColor,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: iconColor ?? AppColors.textSec(context)),
          const SizedBox(width: 14),
          Text(label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? AppColors.textPri(context))),
          const Spacer(),
          Icon(Icons.chevron_right_rounded,
              color: AppColors.textHi(context), size: 20),
        ]),
      ),
    );
  }
}
