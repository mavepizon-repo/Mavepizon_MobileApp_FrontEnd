import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/staff_provider.dart';

class TlMonthlyReportScreen extends ConsumerStatefulWidget {
  const TlMonthlyReportScreen({super.key});
  @override
  ConsumerState<TlMonthlyReportScreen> createState() => _TlMonthlyReportScreenState();
}

class _TlMonthlyReportScreenState extends ConsumerState<TlMonthlyReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => ref.read(staffProvider.notifier).fetch());
  }

  @override
  Widget build(BuildContext context) {
    final prov = ref.watch(staffProvider);
    final staffList = prov.list;

    final sorted = [...staffList]
      ..sort((a, b) => b.performanceScore.compareTo(a.performanceScore));
    final topStaff = sorted.take(5).toList();

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
                  Text('Monthly Reports',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  Text('Staff performance trends',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                ]),
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(staffProvider.notifier).fetch(),
            color: AppColors.accent,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const SizedBox(height: 20),

                  // Summary Cards
                  Text('Summary',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPri(context))),
                  const SizedBox(height: 12),
                  Row(children: [
                    _SummaryCard(
                      'Avg Score',
                      staffList.isEmpty
                          ? '0'
                          : (staffList.fold<double>(
                                      0, (sum, s) => sum + s.performanceScore) /
                                  staffList.length)
                              .toStringAsFixed(1),
                      AppColors.card1,
                    ),
                    const SizedBox(width: 10),
                    _SummaryCard(
                      'Top Performer',
                      staffList.isEmpty
                          ? '-'
                          : staffList
                              .reduce((a, b) =>
                                  a.performanceScore > b.performanceScore
                                      ? a
                                      : b)
                              .name,
                      AppColors.card2,
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Bar Chart
                  if (topStaff.isNotEmpty)
                    Container(
                      height: 280,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Top 5 Performers',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPri(context))),
                          const SizedBox(height: 8),
                          Expanded(
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: 100,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        '${topStaff[groupIndex].name}\n${rod.toY.toStringAsFixed(0)}%',
                                        const TextStyle(color: Colors.white),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index < topStaff.length) {
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(
                                              topStaff[index].name.length > 6
                                                  ? '${topStaff[index].name.substring(0, 6)}...'
                                                  : topStaff[index].name,
                                              style:
                                                  const TextStyle(fontSize: 10),
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                      reservedSize: 30,
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          '${value.toInt()}%',
                                          style: const TextStyle(fontSize: 10),
                                        );
                                      },
                                      reservedSize: 30,
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups:
                                    topStaff.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final staff = entry.value;
                                  final color = [
                                    AppColors.card1,
                                    AppColors.card2,
                                    AppColors.card3,
                                    AppColors.card5,
                                    AppColors.card6
                                  ][index % 5];
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: staff.performanceScore,
                                        color: color,
                                        width: 20,
                                        borderRadius: BorderRadius.circular(4),
                                        backDrawRodData:
                                            BackgroundBarChartRodData(
                                          show: true,
                                          toY: 100,
                                          color: Theme.of(context).scaffoldBackgroundColor,
                                        ),
                                      ),
                                    ],
                                    showingTooltipIndicators: [0],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Staff list with scores
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('All Staff',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPri(context))),
                        const SizedBox(height: 12),
                        if (staffList.isEmpty)
                          const Center(child: Text('No staff data'))
                        else
                          ...staffList.map((s) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(children: [
                                  CircleAvatar(
                                      radius: 16,
                                      backgroundColor:
                                          AppColors.accent.withOpacity(0.1),
                                      child: Text(
                                          s.name.isNotEmpty
                                              ? s.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.accent))),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(s.name,
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPri(context))),
                                        Text(s.role,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                    AppColors.textSec(context))),
                                      ])),
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                          color: AppColors.accent
                                              .withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: Text(
                                          '${s.performanceScore.toInt()}%',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.accent))),
                                ]),
                              )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
