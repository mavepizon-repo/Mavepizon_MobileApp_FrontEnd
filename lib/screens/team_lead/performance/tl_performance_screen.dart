import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/staff_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_widget.dart';

class TlPerformanceScreen extends ConsumerStatefulWidget {
  const TlPerformanceScreen({super.key});
  @override
  ConsumerState<TlPerformanceScreen> createState() => _TlPerformanceScreenState();
}

class _TlPerformanceScreenState extends ConsumerState<TlPerformanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => ref.read(staffProvider.notifier).fetch());
  }

  @override
  Widget build(BuildContext context) {
    final prov = ref.watch(staffProvider);
    final sorted = [...prov.list]
      ..sort((a, b) => b.performanceScore.compareTo(a.performanceScore));

    return Scaffold(
      
      body: Column(children: [
        Container(
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 8, 20, 20),
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28))),
          child: Row(children: [
            GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20))),
            const SizedBox(width: 14),
            const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Performance',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  Text('Staff performance leaderboard',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                ]),
            const Spacer(),
            GestureDetector(
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.tlMonthlyReport),
                child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.calendar_month_rounded,
                        color: Colors.white, size: 20))),
          ]),
        ),
        Expanded(
          child: prov.isLoading
              ? const LoadingWidget()
              : sorted.isEmpty
                  ? const EmptyWidget(
                      message: 'No staff data yet',
                      icon: Icons.leaderboard_outlined)
                  : RefreshIndicator(
                      onRefresh: () => prov.fetch(),
                      color: AppColors.accent,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: sorted.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final s = sorted[i];
                          final rank = i + 1;
                          final color = rank == 1
                              ? const Color(0xFFFFD700)
                              : rank == 2
                                  ? const Color(0xFFC0C0C0)
                                  : rank == 3
                                      ? const Color(0xFFCD7F32)
                                      : AppColors.textHi(context);
                          final medal = rank == 1
                              ? '??'
                              : rank == 2
                                  ? '??'
                                  : rank == 3
                                      ? '??'
                                      : null;

                          // ? Only show task counts if backend actually returned them
                          final hasTaskData = s.totalCompletedTasks > 0 ||
                              s.totalPendingTasks > 0;

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: rank <= 3
                                  ? Border.all(color: color.withOpacity(0.4))
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: Row(children: [
                              // Rank badge
                              Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                      color: rank <= 3
                                          ? color.withOpacity(0.12)
                                          : Theme.of(context).scaffoldBackgroundColor,
                                      shape: BoxShape.circle),
                                  child: Center(
                                      child: medal != null
                                          ? Text(medal,
                                              style:
                                                  const TextStyle(fontSize: 20))
                                          : Text('#$rank',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors
                                                      .textSecondary)))),

                              const SizedBox(width: 12),

                              // Avatar
                              CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      AppColors.primary.withOpacity(0.1),
                                  child: Text(
                                      s.name.isNotEmpty
                                          ? s.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary))),

                              const SizedBox(width: 12),

                              // Info
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(s.name,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPri(context))),
                                    const SizedBox(height: 2),
                                    Text(s.role,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSec(context))),
                                    const SizedBox(height: 6),
                                    // Progress bar
                                    ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                            value: s.performanceScore / 100,
                                            backgroundColor: AppColors.borderC(context),
                                            color: rank <= 3
                                                ? color
                                                : AppColors.accent,
                                            minHeight: 5)),
                                  ])),

                              const SizedBox(width: 12),

                              // Score
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${s.performanceScore.toInt()}%',
                                        style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: rank <= 3
                                                ? color
                                                : AppColors.primary)),
                                    // ? Hide row entirely if backend returns no task data
                                    if (hasTaskData) ...[
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        const Icon(Icons.check_circle_rounded,
                                            size: 12, color: AppColors.success),
                                        const SizedBox(width: 2),
                                        Text('${s.totalCompletedTasks}',
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.success,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 6),
                                        const Icon(
                                            Icons.hourglass_empty_rounded,
                                            size: 12,
                                            color: AppColors.warning),
                                        const SizedBox(width: 2),
                                        Text('${s.totalPendingTasks}',
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.warning,
                                                fontWeight: FontWeight.w600)),
                                      ]),
                                    ],
                                  ]),
                            ]),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}
