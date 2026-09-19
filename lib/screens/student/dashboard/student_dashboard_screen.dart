import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../providers/student_dashboard_provider.dart';
import '../../../routes/app_routes.dart';


class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});
  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends ConsumerState<StudentDashboardScreen> {
  String _name = '';
  String _profilePhoto = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _name = await StorageHelper.getUserName() ?? 'Student';
    _profilePhoto = await StorageHelper.getUserProfile() ?? '';
    if (mounted) setState(() {});
    ref.read(studentDashboardProvider.notifier).loadAll();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final dp = ref.watch(studentDashboardProvider);

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
                                  child: const Text('STUDENT',
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
                                            : 'S',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800))),
                          ),
                        ]),
                  ]),
            ),
          ),
          if (dp.error != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.cloud_off_rounded,
                      size: 18, color: AppColors.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(dp.error!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.error)),
                  ),
                  GestureDetector(
                    onTap: () => ref
                        .read(studentDashboardProvider.notifier)
                        .loadAll(),
                    child: const Icon(Icons.refresh,
                        size: 18, color: AppColors.error),
                  ),
                ]),
              ),
            ),
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
                      title: 'Courses',
                      value: '${dp.courseCount}',
                      icon: Icons.menu_book_rounded,
                      color: AppColors.card1,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.studentCourseList),
                    ),
                    _StatCard(
                      title: 'Internships',
                      value: '${dp.internshipCount}',
                      icon: Icons.work_rounded,
                      color: AppColors.card2,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.studentInternshipList),
                    ),
                    _StatCard(
                      title: 'Payments',
                      value: '${dp.paymentCount}',
                      icon: Icons.payments_rounded,
                      color: AppColors.card3,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.studentCashPaymentHistory),
                    ),
                    _StatCard(
                      title: 'Certificates',
                      value: '${dp.certificateCount}',
                      icon: Icons.verified_rounded,
                      color: AppColors.card6,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.studentCertificates),
                    ),
                  ],
                ),
                if (dp.availableCourses.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text('Available Seats',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPri(context))),
                  const SizedBox(height: 14),
                  ...dp.availableCourses.map((c) => GestureDetector(
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.studentCourseDetail,
                        arguments: {'courseId': c['id']?.toString() ?? ''}),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ]),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                            c['courseName']?.toString() ?? 'Course',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPri(context))),
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(Icons.wifi_rounded,
                              size: 14, color: AppColors.accent),
                          const SizedBox(width: 6),
                          Text(
                              '${c['availableSeatsOnline'] ?? 0} / ${c['totalSeatsOnline'] ?? 0} online',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent)),
                          const SizedBox(width: 16),
                          Icon(Icons.location_on_rounded,
                              size: 14, color: AppColors.card2),
                          const SizedBox(width: 6),
                          Text(
                              '${c['availableSeatsOffline'] ?? 0} / ${c['totalSeatsOffline'] ?? 0} offline',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.card2)),
                        ]),
                        if ((c['availableSeatsTirunelveli'] ?? 0) > 0 || (c['availableSeatsTisaiyanvilai'] ?? 0) > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(children: [
                              Icon(Icons.location_city_rounded,
                                  size: 14, color: AppColors.card3),
                              const SizedBox(width: 6),
                              Text(
                                  'TV: ${c['availableSeatsTirunelveli'] ?? 0} / TY: ${c['availableSeatsTisaiyanvilai'] ?? 0}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.card3)),
                            ]),
                          ),
                      ]),
                    ),
                  )),
                ],
                const SizedBox(height: 28),
                Text('Quick Actions',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPri(context))),
                const SizedBox(height: 14),
                Row(children: [
                  _QuickAction(context, 
                      'Offered Courses',
                      Icons.storefront_rounded,
                      AppColors.card1,
                      () => Navigator.pushNamed(
                          context, AppRoutes.studentCourseList)),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'Internships',
                      Icons.work_rounded,
                      AppColors.card2,
                      () => Navigator.pushNamed(
                          context, AppRoutes.studentInternshipList)),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'Make Payment',
                      Icons.payments_rounded,
                      AppColors.card3,
                      () => Navigator.pushNamed(
                          context, AppRoutes.studentCashPaymentHistory)),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'My Courses',
                      Icons.list_alt_rounded,
                      AppColors.card5,
                      () => Navigator.pushNamed(
                          context, AppRoutes.studentMyCourses)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _QuickAction(context, 
                      'Internships',
                      Icons.badge_rounded,
                      AppColors.card6,
                      () => Navigator.pushNamed(
                          context, AppRoutes.studentMyInternships)),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'Certificates',
                      Icons.verified_rounded,
                      AppColors.card4,
                      () => Navigator.pushNamed(
                          context, AppRoutes.studentCertificates)),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'Notifications',
                      Icons.notifications_rounded,
                      AppColors.warning,
                      () => Navigator.pushNamed(
                          context, AppRoutes.studentNotifications)),
                  const SizedBox(width: 10),
                  _QuickAction(context, 
                      'Profile',
                      Icons.person_rounded,
                      AppColors.card1,
                      () => Navigator.pushNamed(
                          context, AppRoutes.studentProfile)),
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
