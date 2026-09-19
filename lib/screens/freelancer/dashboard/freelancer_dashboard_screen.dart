import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../core/utils/string_utils.dart';
import '../../../providers/freelancer_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../widgets/logout_dialog.dart';

class FreelancerDashboardScreen extends ConsumerStatefulWidget {
  const FreelancerDashboardScreen({super.key});
  @override
  ConsumerState<FreelancerDashboardScreen> createState() =>
      _FreelancerDashboardScreenState();
}

class _FreelancerDashboardScreenState
    extends ConsumerState<FreelancerDashboardScreen> {
  String _name = '';
  String _profilePhoto = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _name = await StorageHelper.getUserName() ?? 'Freelancer';
    _profilePhoto = await StorageHelper.getUserProfile() ?? '';
    if (mounted) setState(() {});
    ref.read(freelancerTasksProvider.notifier).fetchMyTasks();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(freelancerTasksProvider);
    final tasks = p.tasks;

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
                                Text(
                                    _name.isNotEmpty ? _name : 'Freelancer',
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
                                  child: const Text('FREELANCER',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.5)),
                                ),
                              ]),
                          Column(children: [
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              GestureDetector(
                                onTap: () => ref
                                    .read(themeModeProvider.notifier)
                                    .toggleTheme(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle),
                                  child: Icon(
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Icons.light_mode_rounded
                                        : Icons.dark_mode_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () =>
                                    logoutWithConfirmation(context, ref),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.logout_rounded,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 10),
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
                                              : 'F',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800))),
                            ),
                          ]),
                        ]),
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
                      title: 'Total Tasks',
                      icon: Icons.assignment_rounded,
                      color: AppColors.accent,
                      onTap: () => _openMyTasks(context),
                    ),
                    _StatCard(
                      title: 'Pending',
                      icon: Icons.hourglass_empty_rounded,
                      color: AppColors.warning,
                      onTap: () => _openMyTasks(context, status: 'PENDING'),
                    ),
                    _StatCard(
                      title: 'Ongoing',
                      icon: Icons.play_circle_fill_rounded,
                      color: AppColors.card3,
                      onTap: () => _openMyTasks(context, status: 'ONGOING'),
                    ),
                    _StatCard(
                      title: 'Completed',
                      icon: Icons.task_alt_rounded,
                      color: AppColors.success,
                      onTap: () => _openMyTasks(context, status: 'COMPLETED'),
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
                      'My Tasks',
                      Icons.task_alt_rounded,
                      AppColors.accent,
                      () => _openMyTasks(context)),
                  const SizedBox(width: 10),
                  _QuickAction(context,
                      'Pending',
                      Icons.hourglass_empty_rounded,
                      AppColors.warning,
                      () => _openMyTasks(context, status: 'PENDING')),
                  const SizedBox(width: 10),
                  _QuickAction(context,
                      'Ongoing',
                      Icons.play_circle_fill_rounded,
                      AppColors.card3,
                      () => _openMyTasks(context, status: 'ONGOING')),
                  const SizedBox(width: 10),
                  _QuickAction(context,
                      'Completed',
                      Icons.check_circle_rounded,
                      AppColors.success,
                      () => _openMyTasks(context, status: 'COMPLETED')),
                ]),
                const SizedBox(height: 28),

                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('My Tasks',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPri(context))),
                      GestureDetector(
                        onTap: () => _openMyTasks(context),
                        child: const Text('View all',
                            style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                const SizedBox(height: 12),
                if (p.isLoading)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent, strokeWidth: 2)))
                else if (tasks.isEmpty)
                  Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16)),
                      child: Center(
                          child: Text('No tasks assigned yet',
                              style:
                                  TextStyle(color: AppColors.textHi(context)))))
                else
                  ...tasks.take(5).map((t) => _TaskRow(
                      task: t,
                      onTap: () => _openTask(context, t.id))),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  void _openMyTasks(BuildContext context, {String? status}) {
    Navigator.of(context)
        .pushNamed('/freelancer/my-tasks', arguments: {'status': status});
  }

  void _openTask(BuildContext context, String id) {
    Navigator.of(context)
        .pushNamed('/freelancer/task-detail', arguments: {'id': id});
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
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
                color: color.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4)),
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

Widget _QuickAction(
    BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
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

class _TaskRow extends StatelessWidget {
  final dynamic task;
  final VoidCallback onTap;
  const _TaskRow({required this.task, required this.onTap});

  String get _title {
    final t = task.orgName?.toString() ?? '';
    if (t.isNotEmpty) return t;
    final d = task.domain?.toString() ?? '';
    return d.isNotEmpty ? d : 'Untitled';
  }

  String get _status => task.status?.toString().toUpperCase() ?? 'PENDING';

  String get _deadline {
    final end = task.endDate?.toString() ?? '';
    final start = task.startDate?.toString() ?? '';
    final d = truncate(end.isNotEmpty ? end : start, 10);
    return d.isEmpty ? 'No deadline' : d;
  }

  String get _chip {
    final d = task.domain?.toString() ?? '';
    return d.isEmpty ? '--' : truncate(d, 10);
  }

  Color get _statusColor {
    switch (_status) {
      case 'COMPLETED':
        return AppColors.success;
      case 'ONGOING':
        return AppColors.accent;
      case 'REVIEW':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ]),
          child: Row(children: [
            Container(
                width: 3,
                height: 40,
                decoration: BoxDecoration(
                    color: _statusColor,
                    borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPri(context))),
                      const SizedBox(height: 4),
                      Row(children: [
                        Text(_status,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _statusColor)),
                        const SizedBox(width: 8),
                        Text(_deadline,
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textHi(context))),
                      ]),
                    ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(_chip,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ),
          ]),
        ),
      );
}