import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../services/college_staff_service.dart';
import '../../../widgets/logout_dialog.dart';

class CollegeStaffDashboardScreen extends ConsumerStatefulWidget {
  const CollegeStaffDashboardScreen({super.key});

  @override
  ConsumerState<CollegeStaffDashboardScreen> createState() =>
      _CollegeStaffDashboardScreenState();
}

class _CollegeStaffDashboardScreenState
    extends ConsumerState<CollegeStaffDashboardScreen> {
  String _name = '';
  String _collegeName = '';
  String _department = '';
  String _mobileNumber = '';
  String _profilePhoto = '';
  int _uploadedCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _name = await StorageHelper.getUserName() ?? 'College Staff';
    _profilePhoto = await StorageHelper.getUserProfile() ?? '';
    final id = await StorageHelper.getCollegeStaffId() ?? '';
    if (id.isNotEmpty) {
      final result = await CollegeStaffService.getProfile();
      if (result['success'] == true && result['data'] is Map) {
        final d = result['data'] as Map;
        _collegeName = d['collegeName']?.toString() ?? '';
        _department = d['department']?.toString() ?? '';
        _mobileNumber = d['mobileNumber']?.toString() ?? '';
        _uploadedCount = int.tryParse(d['uploadedStudentsCount']?.toString() ?? '0') ?? 0;
        if (_profilePhoto.isEmpty) {
          _profilePhoto = d['profile']?.toString() ?? d['profilePhoto']?.toString() ?? '';
        }
      }
    }
    if (mounted) {
      setState(() => _loading = false);
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
    return Scaffold(
      
      body: RefreshIndicator(
        onRefresh: _load,
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
                                  child: const Text('COLLEGE STAFF',
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
                                            : 'C',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800))),
                          ),
                        ]),
                  ]),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.accent, strokeWidth: 2)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _StatCard(
                        title: 'Students Uploaded',
                        value: '$_uploadedCount',
                        icon: Icons.people_rounded,
                        color: AppColors.card3,
                      ),
                      _StatCard(
                        title: 'College',
                        value: _collegeName.isNotEmpty ? _collegeName : 'N/A',
                        icon: Icons.school_rounded,
                        color: AppColors.card5,
                      ),
                      _StatCard(
                        title: 'Department',
                        value: _department.isNotEmpty ? _department : 'N/A',
                        icon: Icons.business_rounded,
                        color: AppColors.card6,
                      ),
                      _StatCard(
                        title: 'Mobile',
                        value: _mobileNumber.isNotEmpty ? _mobileNumber : 'N/A',
                        icon: Icons.phone_rounded,
                        color: AppColors.card4,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('Quick Actions',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPri(context))),
                  const SizedBox(height: 14),
                  Row(children: [
                    _QuickAction(context, 
                        'Upload Students',
                        Icons.upload_file_rounded,
                        AppColors.card3, () {
                      Navigator.pushNamed(context, '/college-staff/upload-students');
                    }),
                    const SizedBox(width: 10),
                    _QuickAction(context, 
                        'My Profile',
                        Icons.person_rounded,
                        AppColors.warning, () {
                      Navigator.pushNamed(context, '/college-staff/profile');
                    }),
                    const SizedBox(width: 10),
                    _QuickAction(context, 
                        'Logout',
                        Icons.logout_rounded,
                        AppColors.card5, () async {
                      await logoutWithConfirmation(context, ref);
                    }),
                  ]),
                  const SizedBox(height: 28),
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

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
