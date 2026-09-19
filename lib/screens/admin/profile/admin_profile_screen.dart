import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/logout_dialog.dart';
import '../../../widgets/theme_toggle_tile.dart';
import '../calendar/admin_calendar_screen.dart';
import '../holidays/admin_holidays_screen.dart';
import '../leave/admin_leave_approval_screen.dart';
import '../permissions/admin_permission_approval_screen.dart';

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});
  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  String _name = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _name = await StorageHelper.getUserName() ?? 'Admin';
    _email = await StorageHelper.getUserEmail() ?? '';
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    await logoutWithConfirmation(context, ref);
  }

  Future<void> _changePassword() async {
    final otpCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    final step1 = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('An OTP will be sent to your email.'),
          const SizedBox(height: 16),
          TextField(
            controller: newCtrl,
            obscureText: true,
            decoration: const InputDecoration(
                labelText: 'New Password', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: confirmCtrl,
            obscureText: true,
            decoration: const InputDecoration(
                labelText: 'Confirm Password', border: OutlineInputBorder()),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'send'),
              child: const Text('Send OTP')),
        ],
      ),
    );

    if (step1 != 'send' || !mounted) return;
    if (newCtrl.text != confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    final otpResult = await AuthService.forgotPassword(_email, role: 'ADMIN');
    if (otpResult['success'] != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(otpResult['message'] ?? 'Failed to send OTP')));
      }
      return;
    }
    if (!mounted) return;

    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter OTP'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: otpCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'OTP', border: OutlineInputBorder()),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Verify')),
        ],
      ),
    );

    if (step2 == true && mounted) {
      final verifyResult = await AuthService.verifyOtp(_email, otpCtrl.text, role: 'ADMIN');
      if (verifyResult['success'] != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(verifyResult['message'] ?? 'Invalid OTP')));
        }
        return;
      }
      if (!mounted) return;

      final result = await AuthService.resetPassword(
          _email, otpCtrl.text, newCtrl.text, role: 'ADMIN');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result['success'] == true
                ? 'Password changed successfully'
                : result['message'] ?? 'Failed to change password')));
      }
    }
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
                ),
                child: Center(
                    child: Text(
                        _name.isNotEmpty ? _name[0].toUpperCase() : 'A',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800))),
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
                child: const Text('ADMIN',
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
              // -- Menu Items -----------------------------
              _MenuTile(context, Icons.lock_rounded, 'Change Password', AppColors.primary,
                  _changePassword),
              _MenuTile(context, Icons.event_note_rounded, 'Leave Approvals',
                  AppColors.warning, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLeaveApprovalScreen()))),
              _MenuTile(context, Icons.access_time_rounded, 'Permission Approvals',
                  AppColors.card3, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPermissionApprovalScreen()))),
              _MenuTile(context, Icons.calendar_month_rounded, 'Calendar',
                  AppColors.card5, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCalendarScreen()))),
              _MenuTile(context, Icons.celebration_rounded, 'Holidays',
                  AppColors.card2, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHolidaysScreen()))),

              const SizedBox(height: 8),
              const ThemeToggleTile(),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ]),
    );
  }
}

Widget _MenuTile(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: ListTile(
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
    ),
  );
}
