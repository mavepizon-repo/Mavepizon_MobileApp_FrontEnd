import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/admin_staff_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/status_badge.dart';

class AdminStaffDetailScreen extends ConsumerStatefulWidget {
  final String staffId;
  const AdminStaffDetailScreen({super.key, required this.staffId});
  @override
  ConsumerState<AdminStaffDetailScreen> createState() =>
      _AdminStaffDetailScreenState();
}

class _AdminStaffDetailScreenState extends ConsumerState<AdminStaffDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(adminStaffProvider.notifier).fetchById(widget.staffId));
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(adminStaffProvider);
    final s = p.selected;

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Staff Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (p.selected != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit Staff',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.adminStaffEdit,
                  arguments: {'staffId': widget.staffId},
                ).then((_) => ref
                    .read(adminStaffProvider.notifier)
                    .fetchById(widget.staffId));
              },
            ),
        ],
      ),
      body: p.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : p.error != null
              ? Center(child: Text(p.error!))
              : s == null
                  ? const Center(child: Text('Not found'))
                  : RefreshIndicator(
                      onRefresh: () => p.fetchById(widget.staffId),
                      child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Profile Card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Column(children: [
                                CircleAvatar(
                                  radius: 36,
                                  backgroundImage: (s.profilePhoto != null &&
                                          s.profilePhoto!.isNotEmpty)
                                      ? NetworkImage(s.profilePhoto!)
                                      : null,
                                  backgroundColor:
                                      AppColors.card2.withOpacity(0.1),
                                  child: (s.profilePhoto == null ||
                                          s.profilePhoto!.isEmpty)
                                      ? Text(
                                          s.name.isNotEmpty
                                              ? s.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.card2),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                Text(s.name,
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPri(context))),
                                const SizedBox(height: 4),
                                Text(s.employeeId,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textHi(context))),
                                const SizedBox(height: 8),
                                StatusBadge(status: s.status),
                              ]),
                            ),
                            const SizedBox(height: 16),

                            // Performance Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.accent,
                                    AppColors.accent.withOpacity(0.8)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(children: [
                                const Text('Performance Score',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(
                                  '${s.performanceScore}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                      fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _PerfItem(context, 'Assigned',
                                          '${s.totalAssignedTasks}'),
                                      _PerfItem(context, 'Completed',
                                          '${s.totalCompletedTasks}'),
                                      _PerfItem(context, 'Pending',
                                          '${s.totalPendingTasks}'),
                                    ]),
                              ]),
                            ),
                            const SizedBox(height: 16),

                            // Details Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Details',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPri(context))),
                                    const SizedBox(height: 12),
                                    _DetailRow(context, 'Email', s.email),
                                    _DetailRow(context, 'Phone', s.phone),
                                    _DetailRow(context, 'Branch', s.branch),
                                    _DetailRow(context, 'Role', s.role),
                                    _DetailRow(context, 'Category', s.category),
                                    _DetailRow(context, 
                                        'Joining Date', s.joiningDate),
                                    _DetailRow(context, 'Created By',
                                        s.createdByAdmin ?? '-'),
                                  ]),
                            ),
                          ]),
                    ),
    );
  }
}

Widget _PerfItem(BuildContext context, String label, String value) {
  return Column(children: [
    Text(value,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800)),
    Text(label,
        style: TextStyle(
            color: Colors.white.withOpacity(0.8), fontSize: 11)),
  ]);
}

Widget _DetailRow(BuildContext context, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHi(context))),
          ),
          Expanded(
            child: Text(value.isNotEmpty ? value : '-',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPri(context))),
          ),
        ]),
  );
}