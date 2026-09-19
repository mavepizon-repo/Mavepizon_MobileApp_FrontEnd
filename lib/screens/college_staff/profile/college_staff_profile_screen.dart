import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../services/college_staff_service.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/logout_dialog.dart';
import '../../../widgets/theme_toggle_tile.dart';

class CollegeStaffProfileScreen extends ConsumerStatefulWidget {
  const CollegeStaffProfileScreen({super.key});

  @override
  ConsumerState<CollegeStaffProfileScreen> createState() =>
      _CollegeStaffProfileScreenState();
}

class _CollegeStaffProfileScreenState
    extends ConsumerState<CollegeStaffProfileScreen> {
  bool _loading = true;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final id = await StorageHelper.getCollegeStaffId() ?? '';
    if (id.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final result = await CollegeStaffService.getProfile();
    if (result['success'] == true && result['data'] is Map) {
      _profile = Map<String, dynamic>.from(result['data'] as Map);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => logoutWithConfirmation(context, ref),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _profile == null
              ? const Center(child: Text('Failed to load profile'))
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: AppColors.accent.withOpacity(0.2),
                        child: Text(
                          (_profile!['name']?.toString() ?? 'C')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _profile!['name']?.toString() ?? '',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPri(context)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20)),
                        child: const Text('COLLEGE STAFF',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                                letterSpacing: 1.5)),
                      ),
                      const SizedBox(height: 28),
                      _ProfileField(
                          label: 'Email',
                          value: _profile!['email']?.toString() ?? ''),
                      _ProfileField(
                          label: 'Mobile Number',
                          value: _profile!['mobileNumber']?.toString() ?? ''),
                      _ProfileField(
                          label: 'College Name',
                          value: _profile!['collegeName']?.toString() ?? ''),
                      _ProfileField(
                          label: 'Department',
                          value: _profile!['department']?.toString() ?? ''),
                      _ProfileField(
                          label: 'Gender',
                          value: _profile!['gender']?.toString() ?? ''),
                      _ProfileField(
                          label: 'Students Uploaded',
                          value: _profile!['uploadedStudentsCount']
                                  ?.toString() ??
                              '0'),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                              context, AppRoutes.changePassword),
                          icon: const Icon(Icons.lock_rounded,
                              color: AppColors.accent),
                          label: const Text('Change Password',
                              style: TextStyle(color: AppColors.accent)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.accent),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const ThemeToggleTile(),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => logoutWithConfirmation(context, ref),
                          icon: const Icon(Icons.logout_rounded,
                              color: Colors.redAccent),
                          label: const Text('Logout',
                              style: TextStyle(color: Colors.redAccent)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHi(context))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPri(context))),
          ),
        ],
      ),
    );
  }
}
