import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';

/// Reusable logout confirmation bottom sheet.
/// Returns true if user confirmed logout, false otherwise.
Future<bool> showLogoutDialog(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.borderC(context),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.logout_rounded,
                color: AppColors.error, size: 28)),
        const SizedBox(height: 16),
        Text('Logout',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPri(context))),
        const SizedBox(height: 8),
        Text('Are you sure you want to logout?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSec(context))),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
              child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.borderC(context)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text('Cancel',
                      style: TextStyle(
                          color: AppColors.textSec(context),
                          fontWeight: FontWeight.w600)))),
          const SizedBox(width: 12),
          Expanded(
              child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Logout',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700)))),
        ]),
        const SizedBox(height: 8),
      ]),
    ),
  );
  return result ?? false;
}

/// Call this after logout is confirmed: clears auth and navigates to login.
/// The user's chosen theme is kept (per requirement it persists until they
/// manually change it or uninstall the app), so it is NOT reset on logout.
Future<void> performLogout(BuildContext context, WidgetRef ref) async {
  await ref.read(authProvider.notifier).logout();
  if (context.mounted) {
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.login, (r) => false);
  }
}

/// Full logout flow: show dialog -> if confirmed, logout + navigate.
Future<void> logoutWithConfirmation(BuildContext context, WidgetRef ref) async {
  final confirmed = await showLogoutDialog(context);
  if (confirmed) {
    await performLogout(context, ref);
  }
}
