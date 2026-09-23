import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/team_lead_model.dart';
import '../../../providers/admin_team_lead_provider.dart';
import '../../../widgets/status_badge.dart';

class AdminTlDetailScreen extends ConsumerStatefulWidget {
  final String teamLeadId;
  const AdminTlDetailScreen({super.key, required this.teamLeadId});
  @override
  ConsumerState<AdminTlDetailScreen> createState() =>
      _AdminTlDetailScreenState();
}

class _AdminTlDetailScreenState extends ConsumerState<AdminTlDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(adminTeamLeadProvider.notifier).fetchById(widget.teamLeadId));
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(adminTeamLeadProvider);
    final t = p.selected;

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Team Lead Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: p.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : p.error != null
              ? Center(child: Text(p.error!))
              : t == null
                  ? const Center(child: Text('Not found'))
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(adminTeamLeadProvider.notifier).fetchById(widget.teamLeadId),
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
                                  backgroundImage: (t.profilePhoto != null &&
                                          t.profilePhoto!.isNotEmpty)
                                      ? NetworkImage(t.profilePhoto!)
                                      : null,
                                  backgroundColor:
                                      AppColors.primary.withOpacity(0.1),
                                  child: (t.profilePhoto == null ||
                                          t.profilePhoto!.isEmpty)
                                      ? Text(
                                          t.fullName.isNotEmpty
                                              ? t.fullName[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                Text(t.fullName,
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPri(context))),
                                const SizedBox(height: 4),
                                Text(t.employeeId,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textHi(context))),
                                const SizedBox(height: 8),
                                StatusBadge(status: t.status),
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
                                  '${t.performanceScore}',
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
                                          '${t.totalAssignedTasks}'),
                                      _PerfItem(context, 'Completed',
                                          '${t.totalCompletedTasks}'),
                                      _PerfItem(context, 'Pending',
                                          '${t.totalPendingTasks}'),
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
                                    _DetailRow(context, 
                                        'Email', t.email),
                                    _DetailRow(context, 
                                        'Phone', t.phone),
                                    _DetailRow(context, 
                                        'Branch', t.branchName),
                                    _DetailRow(context, 
                                        'Role', t.role),
                                    _DetailRow(context, 
                                        'Shift', _shiftLabel(t)),
                                    _DetailRow(context, 
                                        'Gender', t.gender ?? '-'),
                                    _DetailRow(context, 
                                        'DOB', t.dob ?? '-'),
                                    _DetailRow(context, 
                                        'Native Place', t.nativePlace ?? '-'),
                                    _DetailRow(context, 
                                        'Qualification', t.qualification),
                                    _DetailRow(context, 
                                        'Year Passed Out', t.yearPassedOut ?? '-'),
                                    _DetailRow(context, 
                                        'Experience', t.experience ?? '-'),
                                    _DetailRow(context, 
                                        'Previous Company', t.previousWorkingCompany ?? '-'),
                                    _DetailRow(context, 
                                        'Skills', t.skills.join(', ')),
                                    _DetailRow(context, 
                                        'Joining Date', t.joiningDate),
                                    _DetailRow(context, 
                                        'Created By Admin',
                                        t.createdByAdmin),
                                  ]),
                            ),
                          ]),
                    ),
    );
  }
}

String _shiftLabel(TeamLeadModel t) {
  String format(String raw) {
    if (raw.isEmpty) return '';
    final parts = raw.split(':');
    if (parts.isEmpty) return '';
    final h = int.tryParse(parts[0]);
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    if (h == null) return '';
    final period = h < 12 ? 'AM' : 'PM';
    final hh = h % 12 == 0 ? 12 : h % 12;
    return '$hh:${m.toString().padLeft(2, '0')} $period';
  }

  final s = format(t.shiftStart);
  final e = format(t.shiftEnd);
  if (s.isEmpty && e.isEmpty) return '-';
  if (s.isEmpty) return 'until $e';
  if (e.isEmpty) return 'from $s';
  return '$s – $e';
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
            width: 120,
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
