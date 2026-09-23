import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/pagination_data.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import '../../services/freelancer_task_service.dart';
import '../../services/freelancer_service.dart';
import '../../services/admin_team_lead_service.dart';
import '../../services/admin_staff_service.dart';
import '../../services/staff_service.dart';
import '../../utils/excel_export.dart';
import '../../core/utils/download/file_downloader.dart';
import 'excel_viewer_screen.dart';

/// Shared aggregated monthly report.
///
/// - [isAdmin] = true  -> Team Leads + Office Staff + Freelancers
/// - [isAdmin] = false -> Office Staff only (Team Lead view)
///
/// Includes a styled Excel (.xlsx) download for the selected month.
class MonthlyReportScreen extends StatefulWidget {
  final bool isAdmin;
  const MonthlyReportScreen({super.key, required this.isAdmin});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _PersonMetric {
  final String name;
  final String category;
  final String role;
  double score;
  int assigned = 0;
  int completed = 0;
  int pending = 0;
  int inProgress = 0;

  _PersonMetric({
    required this.name,
    required this.category,
    required this.role,
    this.score = 0,
  });

  int get total => assigned;
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  bool _loading = true;
  String? _error;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final List<_PersonMetric> _people = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _monthKey(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';

  bool _inSelectedMonth(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      // No date on task -> include in every month so totals stay visible.
      return true;
    }
    final d = DateTime.tryParse(dateStr);
    if (d == null) {
      final parts = dateStr.split('-');
      if (parts.length >= 2) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (y != null && m != null) {
          return _monthKey(y, m) ==
              _monthKey(_month.year, _month.month);
        }
      }
      return true;
    }
    return _monthKey(d.year, d.month) == _monthKey(_month.year, _month.month);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.isAdmin) {
        await _loadAdmin();
      } else {
        await _loadTeamLead();
      }
      if (!mounted) return;
      setState(() {
        _people.sort((a, b) {
          final order = {
            'TEAM_LEAD': 0,
            'OFFICE_STAFF': 1,
            'FREELANCER': 2,
          };
          final ca = order[a.category] ?? 9;
          final cb = order[b.category] ?? 9;
          if (ca != cb) return ca.compareTo(cb);
          return b.completed.compareTo(a.completed);
        });
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load report: $e';
      });
    }
  }

  void _bumpCategory(String category, String name, String role,
      double score, TaskModel t) {
    if (!_inSelectedMonth(
        t.deadline.isNotEmpty ? t.deadline : t.startDate)) {
      return;
    }
    var person = _find(name);
    if (person == null) {
      person = _PersonMetric(
          name: name, category: category, role: role, score: score);
      _people.add(person);
    }
    person.assigned++;
    switch (t.status.toUpperCase()) {
      case 'COMPLETED':
        person.completed++;
        break;
      case 'PENDING':
        person.pending++;
        break;
      case 'ASSIGNED':
      case 'IN_PROGRESS':
      case 'WAITING_FOR_REVIEW':
      case 'ONGOING':
      case 'REWORK_REQUIRED':
      case 'REJECTED':
        person.inProgress++;
        break;
    }
  }

  _PersonMetric? _find(String name) {
    for (final p in _people) {
      if (p.name == name) return p;
    }
    return null;
  }

  Future<void> _loadAdmin() async {
    final tlScores = <String, double>{};
    final stScores = <String, double>{};
    final flNames = <String>{};

    try {
      final tlRes = await AdminTeamLeadService.getAll(size: 500);
      if (tlRes['success'] == true) {
        for (final e in PaginationData.parse(tlRes['data']).content) {
          final m = Map<String, dynamic>.from(e as Map);
          final name = m['name']?.toString() ?? m['fullName']?.toString() ?? '';
          if (name.isEmpty) continue;
          tlScores[name] = (m['score'] ?? 0).toDouble();
          _addEmptyIfNotExists(
              name: name,
              category: 'TEAM_LEAD',
              role: 'Team Lead',
              score: tlScores[name]!);
        }
      }
    } catch (_) {}

    try {
      final stRes = await AdminStaffService.getAll(size: 500);
      if (stRes['success'] == true) {
        for (final e in PaginationData.parse(stRes['data']).content) {
          final m = Map<String, dynamic>.from(e as Map);
          final name = m['name']?.toString() ?? '';
          if (name.isEmpty) continue;
          stScores[name] = (m['score'] ?? 0).toDouble();
          _addEmptyIfNotExists(
              name: name,
              category: 'OFFICE_STAFF',
              role: m['role']?.toString() ?? 'Office Staff',
              score: stScores[name]!);
        }
      }
    } catch (_) {}

    try {
      final flRes = await FreelancerService.getAll(size: 500);
      if (flRes['success'] == true) {
        for (final e in PaginationData.parse(flRes['data']).content) {
          final m = Map<String, dynamic>.from(e as Map);
          final name = m['name']?.toString() ?? '';
          if (name.isEmpty) continue;
          flNames.add(name);
          _addEmptyIfNotExists(
              name: name, category: 'FREELANCER', role: 'Freelancer');
        }
      }
    } catch (_) {}

    // Team-lead / staff tasks
    final taskRes = await TaskService.getAllTasks();
    if (taskRes['success'] == true && taskRes['data'] is List) {
      for (final e in taskRes['data'] as List) {
        final t = TaskModel.fromJson(Map<String, dynamic>.from(e as Map));
        final name = t.staffName.isNotEmpty ? t.staffName : t.teamLeadName;
        if (name.isEmpty) continue;
        final isTL = tlScores.containsKey(name);
        final isStaff = stScores.containsKey(name);
        _bumpCategory(
          isTL && !isStaff ? 'TEAM_LEAD' : 'OFFICE_STAFF',
          name,
          isTL && !isStaff
              ? 'Team Lead'
              : (t.staffRole.isNotEmpty ? t.staffRole : 'Office Staff'),
          tlScores[name] ?? stScores[name] ?? 0,
          t,
        );
      }
    }

    // Freelancer tasks
    final flTaskRes = await FreelancerTaskService.getAll(size: 500);
    if (flTaskRes['success'] == true) {
      for (final e in PaginationData.parse(flTaskRes['data']).content) {
        final m = Map<String, dynamic>.from(e as Map);
        final names =
            (m['freelancerNames'] as List? ?? []).map((n) => n.toString());
        if (names.isEmpty) continue;
        final isInMonth = _inSelectedMonth(m['startDate']?.toString()) ||
            _inSelectedMonth(m['endDate']?.toString());
        if (!isInMonth) continue;
        for (final name in names) {
          var person = _find(name);
          if (person == null) {
            person = _PersonMetric(
                name: name, category: 'FREELANCER', role: 'Freelancer');
            _people.add(person);
          }
          person.assigned++;
          switch ((m['status']?.toString() ?? 'PENDING').toUpperCase()) {
            case 'COMPLETED':
              person.completed++;
              break;
            case 'PENDING':
              person.pending++;
              break;
            default:
              person.inProgress++;
          }
        }
      }
    }

    // Compute score % for freelancers (completion rate).
    for (final p in _people) {
      if (p.category == 'FREELANCER') {
        p.score = p.assigned == 0
            ? 0
            : (p.completed / p.assigned) * 100;
      }
    }
  }

  Future<void> _loadTeamLead() async {
    final stRes = await StaffService.getAll();
    final staffScores = <String, double>{};
    if (stRes['success'] == true && stRes['data'] is List) {
      for (final e in stRes['data'] as List) {
        final m = Map<String, dynamic>.from(e as Map);
        final name = m['name']?.toString() ?? '';
        if (name.isEmpty) continue;
        staffScores[name] = (m['score'] ?? 0).toDouble();
        _addEmptyIfNotExists(
            name: name,
            category: 'OFFICE_STAFF',
            role: m['role']?.toString() ?? 'Office Staff',
            score: staffScores[name]!);
      }
    }

    final taskRes = await TaskService.getAll();
    if (taskRes['success'] == true && taskRes['data'] is List) {
      for (final e in taskRes['data'] as List) {
        final t = TaskModel.fromJson(Map<String, dynamic>.from(e as Map));
        final name = t.staffName.isNotEmpty ? t.staffName : 'Unassigned';
        _bumpCategory(
            'OFFICE_STAFF',
            name,
            t.staffRole.isNotEmpty ? t.staffRole : 'Office Staff',
            staffScores[name] ?? 0,
            t);
      }
    }
  }

  void _addEmptyIfNotExists({
    required String name,
    required String category,
    required String role,
    double score = 0,
  }) {
    if (_find(name) == null) {
      _people.add(_PersonMetric(
          name: name, category: category, role: role, score: score));
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(
          _month.year, _month.month + delta, 1);
      _people.clear();
      _load();
    });
  }

  String _monthLabel() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[_month.month - 1]} ${_month.year}';
  }

  // ── Excel export & preview ─────────────────────────────────
  Future<void> _downloadExcel() async {
    final headers = [
      'Category', 'Name', 'Role', 'Assigned',
      'Completed', 'Pending', 'In Progress', 'Score %',
    ];
    final rows = _people.map((p) => [
          p.category.replaceAll('_', ' '),
          p.name,
          p.role,
          p.assigned,
          p.completed,
          p.pending,
          p.inProgress,
          p.score.toStringAsFixed(1),
        ]).toList();

    final bytes = await buildTableExcelBytes(
      sheetName: 'Monthly Report',
      headers: headers,
      rows: rows,
      title: 'Mavepizon Monthly Report',
      subtitle: '${_monthLabel()} - ${widget.isAdmin ? 'Admin' : 'Team Lead'}',
    );

    if (!mounted) return;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Export failed. Please retry.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Save a copy to the public Downloads folder.
    bool saveOk;
    String savedTo = '';
    try {
      savedTo = await downloadFileBytes(
        fileName:
            'Monthly_Report_${_month.year}_${_month.month.toString().padLeft(2, '0')}.xlsx',
        mimeType: xlsxMimeType,
        bytes: bytes,
      );
      saveOk = savedTo.isNotEmpty;
    } catch (_) {
      saveOk = false;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(saveOk
          ? 'Report saved: $savedTo'
          : 'Save cancelled. Please retry.'),
      backgroundColor: saveOk ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));

    // Open the in-app Excel viewer.
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ExcelViewerScreen(
        bytes: bytes,
        title: 'Monthly Report ${_monthLabel()}',
      ),
    ));
  }

  List<_PersonMetric> get _topPerformers {
    final withWork = _people.where((p) => p.completed > 0).toList();
    if (withWork.isNotEmpty) {
      return [...withWork]..sort((a, b) => b.completed.compareTo(a.completed));
    }
    return [..._people]
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  int get _totalAssigned =>
      _people.fold(0, (s, p) => s + p.assigned);
  int get _totalCompleted =>
      _people.fold(0, (s, p) => s + p.completed);
  int get _totalPending => _people.fold(0, (s, p) => s + p.pending);
  double get _avgScore => _people.isEmpty
      ? 0
      : _people.fold<double>(0, (s, p) => s + p.score) / _people.length;

  @override
  Widget build(BuildContext context) {
    final top = _topPerformers.take(5).toList();

    return Scaffold(
      body: Column(children: [
        Container(
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 8, 20, 18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28)),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
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
                  const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Monthly Reports',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                          Text('Task performance for the month',
                              style:
                                  TextStyle(color: Colors.white60, fontSize: 12)),
                        ]),
                  ),
                  // Excel download
                  GestureDetector(
                    onTap: _loading ? null : _downloadExcel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(children: [
                        Icon(Icons.file_download_rounded,
                            size: 18, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text('Excel',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                // Month selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _changeMonth(-1),
                      child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.chevron_left_rounded,
                              color: Colors.white, size: 22)),
                    ),
                    Text(_monthLabel(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    GestureDetector(
                      onTap: () => _changeMonth(1),
                      child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.chevron_right_rounded,
                              color: Colors.white, size: 22)),
                    ),
                  ],
                ),
              ]),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppColors.accent,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // Summary Cards
                  Row(children: [
                    _SummaryCard(
                        'Assigned', '$_totalAssigned', AppColors.card1),
                    const SizedBox(width: 10),
                    _SummaryCard(
                        'Completed', '$_totalCompleted', AppColors.card3),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    _SummaryCard('Pending', '$_totalPending', AppColors.card5),
                    const SizedBox(width: 10),
                    _SummaryCard('Avg Score',
                        _avgScore.toStringAsFixed(1), AppColors.card2),
                  ]),
                  const SizedBox(height: 20),

                  // Bar chart
                  if (!_loading && top.isNotEmpty)
                    Container(
                      height: 260,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Top Performers',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPri(context))),
                          const SizedBox(height: 8),
                          Expanded(
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: (top.fold<double>(
                                            0, (s, p) => p.completed.toDouble()) +
                                        1)
                                    .toDouble(),
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        '${top[groupIndex].name}\n${rod.toY.toStringAsFixed(0)} completed',
                                        const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11),
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
                                        if (index < top.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                top: 6),
                                            child: Text(
                                              top[index].name.length > 6
                                                  ? '${top[index].name.substring(0, 6)}...'
                                                  : top[index].name,
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
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: true, reservedSize: 32),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: top.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final p = entry.value;
                                  final color = [
                                    AppColors.card1,
                                    AppColors.card2,
                                    AppColors.card3,
                                    AppColors.card5,
                                    AppColors.card6,
                                  ][index % 5];
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY:
                                            p.completed.toDouble(),
                                        color: color,
                                        width: 22,
                                        borderRadius:
                                            BorderRadius.circular(5),
                                        backDrawRodData:
                                            BackgroundBarChartRodData(
                                          show: true,
                                          toY: 1,
                                          color: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Report list
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Performance Report',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPri(context))),
                        Icon(Icons.table_rows_rounded,
                            size: 18, color: AppColors.textHi(context)),
                      ]),
                  const SizedBox(height: 12),

                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent, strokeWidth: 2)),
                    )
                  else if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.error)),
                    )
                  else if (_people.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                          child: Text('No data for ${_monthLabel()}',
                              style: TextStyle(
                                  color: AppColors.textHi(context)))),
                    )
                  else
                    ...[
                      _PersonHeaderRow(),
                      ..._people
                          .where((p) => p.assigned > 0)
                          .map((p) => _PersonRow(person: p)),
                      if (_people.every((p) => p.assigned == 0))
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                              'All members have 0 tasks in ${_monthLabel()}.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHi(context))),
                        ),
                    ],
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

class _PersonHeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(children: [
        Expanded(
          flex: 3,
          child: Text('Member',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Text('Done',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Text('Pend',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Text('Active',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Text('Score',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class _PersonRow extends StatelessWidget {
  final _PersonMetric person;
  const _PersonRow({required this.person});

  @override
  Widget build(BuildContext context) {
    final p = person;
    final cat = p.category;
    final color = cat == 'TEAM_LEAD'
        ? AppColors.card2
        : cat == 'FREELANCER'
            ? AppColors.card6
            : AppColors.card1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderC(context)),
      ),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Row(children: [
            CircleAvatar(
                radius: 14,
                backgroundColor: color.withOpacity(0.12),
                child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color))),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPri(context))),
                    Text(cat.replaceAll('_', ' '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textHi(context))),
                  ]),
            ),
          ]),
        ),
        Expanded(
          child: Text('${p.completed}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success)),
        ),
        Expanded(
          child: Text('${p.pending}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning)),
        ),
        Expanded(
          child: Text('${p.inProgress}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent)),
        ),
        Expanded(
          child: Text(
            p.score.toStringAsFixed(0),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primary),
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
                offset: const Offset(0, 4)),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}