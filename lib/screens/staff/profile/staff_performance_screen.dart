import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../services/staff_profile_service.dart';

class StaffPerformanceScreen extends StatefulWidget {
  const StaffPerformanceScreen({super.key});

  @override
  State<StaffPerformanceScreen> createState() =>
      _StaffPerformanceScreenState();
}

class _StaffPerformanceScreenState extends State<StaffPerformanceScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _summary = {};
  List<dynamic> _leaderboard = [];
  String? _myStaffId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final staffId = await StorageHelper.getStaffId();
    _myStaffId = staffId;

    try {
      Future<Map<String, dynamic>>? summaryFuture;
      List<Future<Map<String, dynamic>>> futures = [];
      if (staffId != null) {
        summaryFuture = StaffProfileService.getPerformanceSummary(staffId);
        futures.add(summaryFuture);
      }
      futures.add(StaffProfileService.getLeaderboard());
      final results = await Future.wait(futures);

      int idx = 0;
      if (staffId != null && summaryFuture != null) {
        final summaryRes = results[idx];
        idx++;
        if (summaryRes['success'] == true) {
          final d = summaryRes['data'];
          _summary = d is Map<String, dynamic> ? d : {};
        }
      }

      final leaderboardRes = results[idx];
      if (leaderboardRes['success'] == true) {
        final d = leaderboardRes['data'];
        _leaderboard = d is List ? d : [];
      }
    } catch (e) {
      _error = 'Error: $e';
    }

    if (mounted) setState(() => _isLoading = false);
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
                  20, MediaQuery.of(context).padding.top + 16, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28)),
              ),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Performance & Reports',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    Text('Your score, monthly report & leaderboard',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ]),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent)),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                  child: Text(_error!,
                      style: TextStyle(color: AppColors.textHi(context)))),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_summary.isNotEmpty) ...[
                    Text('This Month',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPri(context))),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                          child: _StatCard(
                              label: 'Score',
                              value: '${_summary['currentScore'] ?? 0}',
                              icon: Icons.star_rounded,
                              color: AppColors.accent)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatCard(
                              label: 'Attendance',
                              value:
                                  '${_summary['attendancePercentage'] ?? 0}%',
                              icon: Icons.event_available_rounded,
                              color: AppColors.success)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                          child: _StatCard(
                              label: 'Completed Tasks',
                              value: '${_summary['completedTasks'] ?? 0}',
                              icon: Icons.task_alt_rounded,
                              color: AppColors.success)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatCard(
                              label: 'Pending Tasks',
                              value: '${_summary['pendingTasks'] ?? 0}',
                              icon: Icons.hourglass_empty_rounded,
                              color: AppColors.warning)),
                    ]),
                    const SizedBox(height: 10),
                    _StatCard(
                        label: 'Approval Rate',
                        value:
                            '${_summary['approvalRate'] ?? 0}%',
                        icon: Icons.verified_rounded,
                        color: AppColors.card2,
                        fullWidth: true),
                    const SizedBox(height: 24),
                  ],
                  Text('Leaderboard',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPri(context))),
                  const SizedBox(height: 10),
                  if (_leaderboard.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                          child: Text('No leaderboard data yet',
                              style: TextStyle(color: AppColors.textHi(context)))),
                    )
                  else
                    ..._leaderboard.asMap().entries.map((e) {
                      final rank = e.key + 1;
                      final s = e.value is Map ? e.value as Map : {};
                      final name = s['name']?.toString() ?? 'Staff';
                      final score = s['score']?.toString() ?? '0';
                      final isMe = _myStaffId != null &&
                          (s['staffId']?.toString() == _myStaffId ||
                              s['id']?.toString() == _myStaffId);
                      final medal = rank == 1
                          ? '??'
                          : rank == 2
                              ? '??'
                              : rank == 3
                                  ? '??'
                                  : '#$rank';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.accent.withOpacity(0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: isMe
                              ? Border.all(color: AppColors.accent, width: 1)
                              : null,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(children: [
                          SizedBox(
                              width: 32,
                              child: Text(medal,
                                  style: const TextStyle(fontSize: 14))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(isMe ? '$name (You)' : name,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isMe
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: AppColors.textPri(context))),
                          ),
                          Text(score,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent)),
                        ]),
                      );
                    }),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool fullWidth;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPri(context))),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textHi(context))),
            ],
          ),
        ),
      ]),
    );
  }
}
