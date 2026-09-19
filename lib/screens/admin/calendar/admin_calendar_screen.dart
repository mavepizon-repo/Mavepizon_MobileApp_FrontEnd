import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/admin_calendar_service.dart';

class AdminCalendarScreen extends StatefulWidget {
  const AdminCalendarScreen({super.key});
  @override
  State<AdminCalendarScreen> createState() => _AdminCalendarScreenState();
}

class _AdminCalendarScreenState extends State<AdminCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  Map<String, List<Map<String, dynamic>>> _leavesMap = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchLeaves();
  }

  Future<void> _fetchLeaves() async {
    setState(() => _loading = true);
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final last = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final result = await AdminCalendarService.getLeaves(
      first.toIso8601String().substring(0, 10),
      last.toIso8601String().substring(0, 10),
    );
    if (result['success'] == true && result['data'] is Map) {
      final raw = result['data'] as Map;
      _leavesMap = raw.map((k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v)));
    }
    if (mounted) setState(() => _loading = false);
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
    _fetchLeaves();
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
    _fetchLeaves();
  }

  List<Map<String, dynamic>> _getDayLeaves(DateTime day) {
    final key = day.toIso8601String().substring(0, 10);
    return _leavesMap[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final dayLeaves = _getDayLeaves(_selectedDate);

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Calendar'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
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
          child: Column(children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _prevMonth,
                  ),
                  Text(
                    '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPri(context)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _nextMonth,
                  ),
                ]),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.accent)),
              ),
            const SizedBox(height: 12),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .map((d) => SizedBox(
                        width: 36,
                        child: Text(d,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textHi(context)))))
                    .toList()),
            const SizedBox(height: 8),
            ..._buildWeeks(),
          ]),
        ),
        const SizedBox(height: 16),

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${_dayName(_selectedDate.weekday)}, ${_selectedDate.day} ${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPri(context))),
                const SizedBox(height: 8),
                if (dayLeaves.isEmpty)
                  Text('No events for this day',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textHi(context)))
                else
                  ...dayLeaves.map((l) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${l['type'] ?? 'Leave'} - ${l['name'] ?? l['status'] ?? ''}',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSec(context)),
                            ),
                          ),
                        ]),
                      )),
              ]),
        ),
      ]),
    );
  }

  List<Widget> _buildWeeks() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;
    final totalDays = lastDay.day;
    final today = DateTime.now();

    final weeks = <Widget>[];
    var day = 1 - startWeekday;

    while (day <= totalDays) {
      final cells = <Widget>[];
      for (var j = 0; j < 7; j++) {
        if (day < 1 || day > totalDays) {
          cells.add(const SizedBox(width: 36, height: 36));
        } else {
          final d = day;
          final date = DateTime(_focusedMonth.year, _focusedMonth.month, d);
          final isToday = date.day == today.day &&
              date.month == today.month &&
              date.year == today.year;
          final isSelected = date == _selectedDate;
          final hasLeaves = _getDayLeaves(date).isNotEmpty;

          cells.add(GestureDetector(
            onTap: () =>
                setState(() => _selectedDate = date),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.accent
                    : isToday
                        ? AppColors.accent.withOpacity(0.1)
                        : Colors.transparent,
              ),
              child: Center(
                child: Stack(alignment: Alignment.center, children: [
                  Text(
                    '$d',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? AppColors.accent
                              : AppColors.textPri(context),
                    ),
                  ),
                  if (hasLeaves && !isSelected)
                    Positioned(
                        bottom: 2,
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent,
                          ),
                        )),
                ]),
              ),
            ),
          ));
        }
        day++;
      }
      weeks.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: cells),
      ));
    }
    return weeks;
  }

  String _monthName(int m) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[m];
  }

  String _dayName(int d) {
    const names = [
      '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
      'Saturday', 'Sunday'
    ];
    return names[d];
  }
}
