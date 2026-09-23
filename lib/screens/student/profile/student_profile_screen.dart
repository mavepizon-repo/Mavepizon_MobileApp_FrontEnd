import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/logout_dialog.dart';
import '../../../widgets/theme_toggle_tile.dart';

class StudentProfileScreen extends ConsumerStatefulWidget {
  const StudentProfileScreen({super.key});
  @override
  ConsumerState<StudentProfileScreen> createState() =>
      _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> {
  String _name = '';
  String _email = '';
  String _profilePhoto = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _name = await StorageHelper.getUserName() ?? 'Student';
    _email = await StorageHelper.getUserEmail() ?? '';
    _profilePhoto = await StorageHelper.getUserProfile() ?? '';
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 2),
                  image: _profilePhoto.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(_profilePhoto),
                          fit: BoxFit.cover)
                      : null,
                ),
                child: _profilePhoto.isEmpty
                    ? Center(
                        child: Text(
                            _name.isNotEmpty ? _name[0].toUpperCase() : 'S',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800)))
                    : null,
              ),
              const SizedBox(height: 16),
              Text(_name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(_email,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.65), fontSize: 14)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('STUDENT',
                    style: TextStyle(
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
                icon: Icons.edit_rounded,
                label: 'Edit Profile',
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.studentEditProfile),
              ),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.menu_book_rounded,
                label: 'My Courses',
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.studentMyCourses),
              ),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.work_rounded,
                label: 'My Internships',
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.studentMyInternships),
              ),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.payments_rounded,
                label: 'Payment History',
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.studentCashPaymentHistory),
              ),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.verified_rounded,
                label: 'Certificates',
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.studentCertificates),
              ),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.notifications_rounded,
                label: 'Notifications',
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.studentNotifications),
              ),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.lock_rounded,
                label: 'Change Password',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.changePassword),
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
