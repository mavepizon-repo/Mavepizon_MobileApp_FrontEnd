import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/internship_provider.dart';
import '../../../providers/student_provider.dart';
import '../../../providers/certificate_provider.dart';
import '../../../services/student_course_service.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_widget.dart';
import '../../../widgets/status_badge.dart';

class TlStudentMonitorScreen extends ConsumerStatefulWidget {
  const TlStudentMonitorScreen({super.key});
  @override
  ConsumerState<TlStudentMonitorScreen> createState() => _TlStudentMonitorScreenState();
}

class _TlStudentMonitorScreenState extends ConsumerState<TlStudentMonitorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  // -- Course tab filters --------------------------------------
  String? _courseId;
  DateTime? _courseStart, _courseEnd;
  String _courseMonth = '';

  // -- Internship tab filters ----------------------------------
  String? _internshipId;
  DateTime? _intStart, _intEnd;
  String _intMonth = '';

  // -- Registration data (frontend filtering) ------------------
  List<dynamic> _courseRegs = [];
  List<dynamic> _internshipRegs = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(courseProvider.notifier).fetch();
      ref.read(internshipProvider.notifier).fetch();
      ref.read(studentProvider.notifier).fetchAll();
      _loadRegistrations();
    });
  }

  Future<void> _loadRegistrations() async {
    try {
      final cpResult = await StudentCourseService.getAllRegistrations();
      if (cpResult['success'] == true && cpResult['data'] is List) {
        _courseRegs = cpResult['data'] as List;
      }
      final cert = ref.read(certificateProvider);
      if (cert.list.isEmpty) {
        await cert.fetch();
      }
      _internshipRegs = cert.list
          .where((c) => c.type.toUpperCase() == 'INTERNSHIP')
          .toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load registrations: $e')));
      }
    }
    if (mounted) setState(() {});
  }

  static String _monthOf(String dateStr) {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return '';
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
  }

  String _regKey(dynamic s, String key) {
    try {
      final v = s[key];
      if (v == null) return '';
      if (v is Map) return v['id']?.toString() ?? '';
      return v.toString();
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ? FIX: Backend Student entity has no courseId / internshipId field.
  // The old filter checked s['courseId'] which never matched � always empty.
  // New approach:
  //   - Date filter: filter by registrationDate or createdAt (these exist)
  //   - Course/Internship dropdown: show info banner that backend doesn't
  //     support this filter yet. All students are shown for now.
  //   - When backend adds courseRegistrationId to Student entity,
  //     replace the matchCourse condition below with the real field.
  List<dynamic> _filteredCourseStudents(List<dynamic> all) {
    // Student ids registered for the selected course (from /api/student-course/get-all)
    final regStudentIds = _courseRegs
        .where((r) =>
            _courseId == null ||
            _regKey(r, 'course') == _courseId ||
            _regKey(r, 'offeredCourse') == _courseId)
        .map((r) => _regKey(r, 'student'))
        .where((id) => id.isNotEmpty)
        .toSet();

    return all.where((s) {
      bool matchCourse = true;
      if (_courseId != null) {
        final sid = s['id']?.toString() ?? s['studentId']?.toString() ?? '';
        matchCourse = regStudentIds.contains(sid);
      }

      bool matchDate = true;
      String regDate = '';
      if (_courseStart != null && _courseEnd != null) {
        regDate = s['registrationDate']?.toString() ??
            s['createdAt']?.toString() ??
            '';
        try {
          if (regDate.isNotEmpty) {
            final reg = DateTime.parse(regDate);
            matchDate =
                !reg.isBefore(_courseStart!) && !reg.isAfter(_courseEnd!);
          }
        } catch (_) {
          // Malformed registrationDate on this record � skip date filtering
          // for it rather than excluding it entirely.
        }
      }
      bool matchMonth = true;
      if (_courseMonth.isNotEmpty) {
        final d = _monthOf(regDate.isNotEmpty
            ? regDate
            : s['registrationDate']?.toString() ??
                s['createdAt']?.toString() ??
                '');
        matchMonth = d == _courseMonth;
      }

      return matchCourse && matchDate && matchMonth;
    }).toList();
  }

  List<dynamic> _filteredInternshipStudents(List<dynamic> all) {
    // Internship registrations come from certificate records (type = INTERNSHIP).
    // Each certificate carries studentId + batchCode, matched against the
    // selected internship's batchCode.
    final selectedBatch = _internshipId != null
        ? ref
            .read(internshipProvider)
            .list
            .where((i) => i.id == _internshipId)
            .map((i) => i.batchCode)
            .firstOrNull
        : null;
    final regStudentIds = _internshipId == null
        ? <String>{}
        : _internshipRegs
            .where((c) =>
                selectedBatch == null ||
                (c.batchCode ?? '') == selectedBatch)
            .map((c) => c.studentId.toString())
            .where((id) => id.isNotEmpty)
            .toSet();

    return all.where((s) {
      bool matchInt = true;
      if (_internshipId != null) {
        final sid = s['id']?.toString() ?? s['studentId']?.toString() ?? '';
        matchInt = regStudentIds.contains(sid);
      }

      bool matchDate = true;
      String regDate = '';
      if (_intStart != null && _intEnd != null) {
        regDate = s['registrationDate']?.toString() ??
            s['createdAt']?.toString() ??
            '';
        try {
          if (regDate.isNotEmpty) {
            final reg = DateTime.parse(regDate);
            matchDate = !reg.isBefore(_intStart!) && !reg.isAfter(_intEnd!);
          }
        } catch (_) {
          // Malformed registrationDate on this record � skip date filtering
          // for it rather than excluding it entirely.
        }
      }
      bool matchMonth = true;
      if (_intMonth.isNotEmpty) {
        final d = _monthOf(regDate.isNotEmpty
            ? regDate
            : s['registrationDate']?.toString() ??
                s['createdAt']?.toString() ??
                '');
        matchMonth = d == _intMonth;
      }

      return matchInt && matchDate && matchMonth;
    }).toList();
  }

  Future<void> _pickDate(bool isStart, bool isCourse) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.accent)),
        child: child!,
      ),
    );
    if (d != null) {
      setState(() {
        if (isCourse) {
          if (isStart) {
            _courseStart = d;
          } else {
            _courseEnd = d;
          }
        } else {
          if (isStart) {
            _intStart = d;
          } else {
            _intEnd = d;
          }
        }
      });
    }
  }

  void _clearCourseFilters() => setState(() {
      _courseId = null;
      _courseStart = null;
      _courseEnd = null;
      _courseMonth = '';
    });

  void _clearIntFilters() => setState(() {
        _internshipId = null;
        _intStart = null;
        _intEnd = null;
        _intMonth = '';
      });

  Future<void> _pickMonth(bool isCourse) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select MONTH',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.accent)),
        child: child!,
      ),
    );
    if (d != null) {
      setState(() {
        final m =
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
        if (isCourse) {
          _courseMonth = m;
          _courseStart = null;
          _courseEnd = null;
        } else {
          _intMonth = m;
          _intStart = null;
          _intEnd = null;
        }
      });
    }
  }

  String _fmtDate(DateTime? d) => d == null
      ? 'From'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final cp = ref.watch(courseProvider);
    final ip = ref.watch(internshipProvider);
    final sp = ref.watch(studentProvider);

    final allStudents = sp.students;
    final courseStudents = _filteredCourseStudents(allStudents);
    final internshipStudents = _filteredInternshipStudents(allStudents);

    return Scaffold(
      
      body: Column(children: [
        // -- Header ----------------------------------------------
        Container(
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 8, 20, 0),
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28))),
          child: Column(children: [
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
              const Text('Student Monitor',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${allStudents.length} total',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 16),
            TabBar(
              controller: _tab,
              indicator: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.symmetric(vertical: 4),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(text: 'Course (${courseStudents.length})'),
                Tab(text: 'Internship (${internshipStudents.length})'),
              ],
            ),
            const SizedBox(height: 8),
          ]),
        ),

        Expanded(
          child: sp.isLoading
              ? const LoadingWidget(message: 'Loading students...')
              : TabBarView(controller: _tab, children: [
                  // -- Course Tab ------------------------------
                  _buildTab(
                    context: context,
                    isCourse: true,
                    dropdownHint: 'Filter by Course',
                    dropdownIcon: Icons.menu_book_rounded,
                    dropdownItems: cp.list
                        .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.courseName,
                                style: const TextStyle(fontSize: 14))))
                        .toList(),
                    selectedId: _courseId,
                    onDropdownChanged: (v) => setState(() => _courseId = v),
                    startDate: _courseStart,
                    endDate: _courseEnd,
                    month: _courseMonth,
                    onMonthTap: () => _pickMonth(true),
                    onClearFilters: _clearCourseFilters,
                    students: courseStudents,
                  ),

                  // -- Internship Tab --------------------------
                  _buildTab(
                    context: context,
                    isCourse: false,
                    dropdownHint: 'Filter by Internship',
                    dropdownIcon: Icons.work_rounded,
                    dropdownItems: ip.list
                        .map((i) => DropdownMenuItem(
                            value: i.id,
                            child: Text(i.internshipName,
                                style: const TextStyle(fontSize: 14))))
                        .toList(),
                    selectedId: _internshipId,
                    onDropdownChanged: (v) => setState(() => _internshipId = v),
                    startDate: _intStart,
                    endDate: _intEnd,
                    month: _intMonth,
                    onMonthTap: () => _pickMonth(false),
                    onClearFilters: _clearIntFilters,
                    students: internshipStudents,
                  ),
                ]),
        ),
      ]),
    );
  }

  Widget _buildTab({
    required BuildContext context,
    required bool isCourse,
    required String dropdownHint,
    required IconData dropdownIcon,
    required List<DropdownMenuItem<String>> dropdownItems,
    required String? selectedId,
    required void Function(String?) onDropdownChanged,
    required DateTime? startDate,
    required DateTime? endDate,
    required String month,
    required VoidCallback onMonthTap,
    required VoidCallback onClearFilters,
    required List<dynamic> students,
  }) {
    return Column(children: [
      // Filter section
      Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Course/Internship dropdown
          DropdownButtonFormField<String>(
            value: selectedId,
            hint: Text(dropdownHint,
                style:
                    TextStyle(color: AppColors.textHi(context), fontSize: 14)),
            decoration: InputDecoration(
              prefixIcon:
                  Icon(dropdownIcon, color: AppColors.textHi(context), size: 20),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderC(context))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderC(context))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 2)),
            ),
            items: dropdownItems,
            onChanged: onDropdownChanged,
          ),

          const SizedBox(height: 10),

          // Date range filter
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDate(true, isCourse),
                child:
                    _dateBox(_fmtDate(startDate), Icons.calendar_today_rounded),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDate(false, isCourse),
                child: _dateBox(_fmtDate(endDate), Icons.event_rounded),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onMonthTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: month.isNotEmpty
                      ? AppColors.accent.withOpacity(0.15)
                      : Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: month.isNotEmpty
                          ? AppColors.accent
                          : AppColors.borderC(context)),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_month_rounded,
                      size: 16,
                      color: month.isNotEmpty
                          ? AppColors.accent
                          : AppColors.textHi(context)),
                  const SizedBox(width: 6),
                  Text(
                    month.isEmpty ? 'Month' : month,
                    style: TextStyle(
                        color: month.isNotEmpty
                            ? AppColors.accent
                            : AppColors.textSec(context),
                        fontSize: 12,
                        fontWeight:
                            month.isNotEmpty ? FontWeight.w700 : FontWeight.w400),
                  ),
                ]),
              ),
            ),
            if (selectedId != null ||
                startDate != null ||
                endDate != null ||
                month.isNotEmpty)
              GestureDetector(
                onTap: onClearFilters,
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.error, size: 16),
                ),
              ),
          ]),
        ]),
      ),

      // Student list
      Expanded(
        child: students.isEmpty
            ? const EmptyWidget(
                message: 'No students found', icon: Icons.people_outline)
            : RefreshIndicator(
                onRefresh: () => ref.read(studentProvider.notifier).fetchAll(),
                color: AppColors.accent,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _StudentCard(students[i]),
                ),
              ),
      ),
    ]);
  }

  Widget _dateBox(String label, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderC(context)),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.textHi(context)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: AppColors.textSec(context), fontSize: 12)),
        ]),
      );
}

// ? FIX: _StudentCard uses safe null-aware access.
// s is dynamic (raw Map from API). Use safe toString() on all fields
// to avoid NoSuchMethodError if backend returns unexpected shape.
class _StudentCard extends StatelessWidget {
  final dynamic student;
  const _StudentCard(this.student);

  String _get(String key) {
    try {
      return student[key]?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _get('fullName').isNotEmpty ? _get('fullName') : _get('name');
    final email = _get('email');
    final college = _get('collegeName');
    final dept = _get('department');
    final regDate = _get('registrationDate').isNotEmpty
        ? _get('registrationDate')
        : _get('createdAt');
    final payStatus = _get('paymentStatus');
    final certStatus = _get('certificateStatus');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Row(children: [
        CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.card6.withOpacity(0.15),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.card6))),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name.isNotEmpty ? name : 'Unknown',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPri(context))),
          if (email.isNotEmpty)
            Text(email,
                style:
                    TextStyle(fontSize: 11, color: AppColors.textHi(context))),
          if (college.isNotEmpty)
            Text('$college${dept.isNotEmpty ? ' � $dept' : ''}',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textSec(context))),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (payStatus.isNotEmpty) StatusBadge(status: payStatus, fontSize: 9),
          if (certStatus.isNotEmpty) ...[
            const SizedBox(height: 4),
            StatusBadge(status: certStatus, fontSize: 9),
          ],
          if (regDate.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(regDate.length >= 10 ? regDate.substring(0, 10) : regDate,
                style: TextStyle(fontSize: 9, color: AppColors.textHi(context))),
          ],
        ]),
      ]),
    );
  }
}
