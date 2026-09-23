import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/tl_profile_service.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/logout_dialog.dart';
import '../../../widgets/theme_toggle_tile.dart';

class TlProfileScreen extends ConsumerStatefulWidget {
  const TlProfileScreen({super.key});
  @override
  ConsumerState<TlProfileScreen> createState() => _TlProfileScreenState();
}

class _TlProfileScreenState extends ConsumerState<TlProfileScreen> {
  String _name = '';
  String _email = '';
  String _mobile = '';
  String _branch = '';
  String _teamLeadId = '';
  String _profilePhoto = '';
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    _name = await StorageHelper.getUserName() ?? '';
    _email = await StorageHelper.getUserEmail() ?? '';
    final res = await TlProfileService.getProfile();
    if (res['success'] == true) {
      final d = res['data'] is Map ? res['data'] as Map<String, dynamic> : {};
      _name = d['name']?.toString() ?? _name;
      _email = d['email']?.toString() ?? _email;
      _mobile = d['mobileNumber']?.toString() ?? '';
      _branch = d['branch']?.toString() ?? '';
      _teamLeadId = d['teamLeadId']?.toString() ?? '';
      _profilePhoto = d['profilePhoto']?.toString() ?? '';
    }
    _loadingProfile = false;
    if (mounted) setState(() {});
  }

  String get displayName => _name;
  String get displayEmail => _email;

  Future<void> _logout() async {
    await logoutWithConfirmation(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(children: [
            // -- Header -------------------------------------------
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 20, 20, 36),
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36))),
              child: Column(children: [
                // Avatar
                Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: _profilePhoto.isNotEmpty
                          ? null
                          : LinearGradient(colors: [
                              AppColors.accent,
                              AppColors.accent.withOpacity(0.7)
                            ]),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4), width: 3),
                    ),
                    child: _profilePhoto.isNotEmpty
                        ? CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(_profilePhoto))
                        : Center(
                            child: Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : 'T',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900)))),
                const SizedBox(height: 14),
                Text(displayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(displayEmail,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.65), fontSize: 13)),
                if (_branch.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 14, color: Colors.white.withOpacity(0.65)),
                      const SizedBox(width: 4),
                      Text(_branch,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 13)),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('TEAM LEAD',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1))),

              ]),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [

                if (_loadingProfile)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accent, strokeWidth: 2)),
                  )
                else ...[
                  // -- Profile Info card ----------------------------
                  if (_teamLeadId.isNotEmpty || _mobile.isNotEmpty || _branch.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ]),
                      child: Column(children: [
                        if (_teamLeadId.isNotEmpty)
                          _InfoRow(Icons.badge_rounded, 'Employee ID', _teamLeadId),
                        if (_mobile.isNotEmpty)
                          _InfoRow(Icons.phone_rounded, 'Mobile', _mobile),
                        if (_branch.isNotEmpty)
                          _InfoRow(Icons.location_on_rounded, 'Branch', _branch),
                      ]),
                    ),
                ],

                // Quick links
                _MenuCard([
                  _MenuItem(
                      Icons.people_rounded, 'Staff Management', AppColors.card1,
                      subtitle: 'Manage your staff team',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.tlStaffList)),
                  _divider(context, ),
                  _MenuItem(
                      Icons.task_alt_rounded, 'Task Overview', AppColors.card2,
                      subtitle: 'View all assigned tasks',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.tlTaskList)),
                  _divider(context, ),
                  _MenuItem(Icons.menu_book_rounded, 'Courses', AppColors.card3,
                      subtitle: 'Manage courses',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.tlCourseList)),
                  _divider(context, ),
                  _MenuItem(Icons.work_rounded, 'Internships', AppColors.card6,
                      subtitle: 'Manage internships',
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.tlInternshipList)),
                  _divider(context, ),
                  _MenuItem(Icons.people_alt_rounded, 'Student Monitor',
                      AppColors.card5,
                      subtitle: 'Track student registrations',
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.tlStudentMonitor)),
                  _divider(context, ),
                  _MenuItem(Icons.card_membership_rounded, 'Certificates',
                      AppColors.card4,
                      subtitle: 'Update certificate status',
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.tlCertificates)),
                  _divider(context, ),
                  _MenuItem(
                      Icons.leaderboard_rounded, 'Performance', AppColors.card2,
                      subtitle: 'Staff performance board',
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.tlPerformance)),
                  _divider(context, ),
                  _MenuItem(
                      Icons.event_note_rounded, 'Leave Management', AppColors.warning,
                      subtitle: 'Approve/reject staff leaves',
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.tlLeaveManagement)),
                  _divider(context, ),
                  _MenuItem(
                      Icons.access_time_rounded, 'Permission Management', AppColors.card3,
                      subtitle: 'Approve/reject staff permissions',
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.tlPermissionManagement)),
                  _divider(context, ),
                  _MenuItem(
                      Icons.logout_rounded, 'Apply Leave', AppColors.card6,
                      subtitle: 'Submit leave request to Admin',
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.tlApplyLeave)),
                  _divider(context, ),
                  _MenuItem(
                      Icons.timer_rounded, 'Apply Permission', AppColors.card5,
                      subtitle: 'Request 1-hour permission from Admin',
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.tlApplyPermission)),
                ]),

                const SizedBox(height: 16),

                _MenuCard([
                  _MenuItem(Icons.lock_outline_rounded, 'Change Password',
                      AppColors.textSec(context),
                      subtitle: 'Update your password',
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.changePassword)),
                ]),

                const SizedBox(height: 16),

                _MenuCard([
                  const ThemeToggleTile(),
                ]),

                const SizedBox(height: 16),

                // Logout
                GestureDetector(
                  onTap: _logout,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: AppColors.error.withOpacity(0.2))),
                    child: Row(children: [
                      Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.logout_rounded,
                              color: AppColors.error, size: 20)),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Logout',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.error)),
                            Text('Sign out of your account',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textHi(context))),
                          ])),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.error),
                    ]),
                  ),
                ),

                const SizedBox(height: 24),
                // ? FIX: Hardcoded "� 2024" replaced with dynamic current
                // year (DateTime.now().year) so it always shows the right
                // year automatically � no manual edit needed every January.
                Text(
                    'Mavepizon Technologies Pvt. Ltd. � ${DateTime.now().year}',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                const SizedBox(height: 4),
                Text('v1.0.0',
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey.shade300)),
                const SizedBox(height: 28),
              ]),
            ),
          ]),
        ),
      );
  }

}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.accent),
      const SizedBox(width: 12),
      Text('$label: ',
          style: TextStyle(
              fontSize: 13, color: AppColors.textHi(context))),
      Expanded(
        child: Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPri(context))),
      ),
    ]),
  );
}

Widget _divider(BuildContext context, ) =>
    Divider(height: 1, indent: 68, color: AppColors.dividerC(context));

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard(this.children);
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ]),
      child: Column(children: children));
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuItem(this.icon, this.label, this.color,
      {this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPri(context))),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textHi(context))),
                ])),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: AppColors.textHi(context)),
          ]),
        ),
      );
}