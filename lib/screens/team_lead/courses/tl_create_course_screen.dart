import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/course_provider.dart';
import '../../../widgets/app_button.dart';

class TlCreateCourseScreen extends ConsumerStatefulWidget {
  const TlCreateCourseScreen({super.key});
  @override
  ConsumerState<TlCreateCourseScreen> createState() => _TlCreateCourseScreenState();
}

class _TlCreateCourseScreenState extends ConsumerState<TlCreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _c = <String, TextEditingController>{
    'name': TextEditingController(),
    'desc': TextEditingController(),
    'duration': TextEditingController(),
    'fees': TextEditingController(),
    'online': TextEditingController(),
    'offline': TextEditingController(),
    'tirunelveli': TextEditingController(),
    'tisaiyanvilai': TextEditingController(),
  };
  // Category is fixed to 'COURSE' for this screen.
  static const String _category = 'COURSE';
  DateTime? _start, _end, _regStart, _regEnd;

  @override
  void dispose() {
    for (var c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(bool isStart) async {
    final d = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2024),
        lastDate: DateTime(2030),
        builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
                colorScheme:
                    const ColorScheme.light(primary: AppColors.accent)),
            child: child!));
    if (d != null) {
      setState(() {
        if (isStart) {
          _start = d;
        } else {
          _end = d;
        }
      });
    }
  }

  String _fmt(DateTime? d) => d == null
      ? 'Pick date'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_start == null || _end == null) {
      _snack('Select start and end dates', AppColors.error);
      return;
    }
    // Registration Start/End Date are required.
    if (_regStart == null || _regEnd == null) {
      _snack('Select registration start and end dates', AppColors.error);
      return;
    }
    if (_regStart!.isAfter(_regEnd!)) {
      _snack('Registration Start Date cannot be after Registration End Date',
          AppColors.error);
      return;
    }
    if (_regEnd!.isAfter(_start!)) {
      _snack('Registration End Date cannot be after Course Start Date',
          AppColors.error);
      return;
    }
    final data = {
      'courseName': _c['name']!.text.trim(),
      'description': _c['desc']!.text.trim(),
      'duration': _c['duration']!.text.trim(),
      'totalFees': double.tryParse(_c['fees']!.text) ?? 0,
      'totalSeatsOnline': int.tryParse(_c['online']!.text) ?? 0,
      'totalSeatsOffline': int.tryParse(_c['offline']!.text) ?? 0,
      'totalSeatsTirunelveli': int.tryParse(_c['tirunelveli']!.text) ?? 0,
      'totalSeatsTisaiyanvilai': int.tryParse(_c['tisaiyanvilai']!.text) ?? 0,
      'startDate': _dateOnly(_start!),
      'endDate': _dateOnly(_end!),
      'registrationStartDate': _regStart != null ? _dateOnly(_regStart!) : '',
      'registrationEndDate': _regEnd != null ? _dateOnly(_regEnd!) : '',
      'category': _category,
    };
    final ok = await ref.read(courseProvider.notifier).create(data);
    if (!mounted) return;
    if (ok) {
      _snack('Course created!', AppColors.success);
      Navigator.pop(context);
    } else {
      _snack(ref.read(courseProvider).error ?? 'Failed', AppColors.error);
    }
  }

  void _snack(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16)));

  @override
  Widget build(BuildContext context) {
    final prov = ref.watch(courseProvider);
    return Scaffold(
      
      body: Column(children: [
        _header(context),
        Expanded(
          child: ResponsiveCentered(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
              key: _formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sec('Course Info'),
                    _f('Course Name', 'name', Icons.menu_book_rounded,
                        req: true),
                    _f('Description', 'desc', Icons.description_rounded,
                        lines: 3),
                    _f('Duration', 'duration', Icons.timer_rounded,
                        hint: 'e.g. 3 months'),
                    _sec('Fees'),
                    Row(children: [
                      Expanded(
                          child: _f(
                              'Total Fees ?', 'fees',
                              Icons.currency_rupee_rounded,
                              hint: '0', type: TextInputType.number)),
                    ]),
                    _sec('Seats'),
                    Row(children: [
                      Expanded(
                          child: _f(
                              'Online Seats', 'online', Icons.computer_rounded,
                              hint: '0', type: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _f(
                              'Offline Seats', 'offline', Icons.people_rounded,
                              hint: '0', type: TextInputType.number)),
                    ]),
                    const SizedBox(height: 0),
                    Row(children: [
                      Expanded(
                          child: _f(
                              'Tirunelveli Seats', 'tirunelveli', Icons.location_city_rounded,
                              hint: '0', type: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _f(
                              'Tisaiyanvilai Seats', 'tisaiyanvilai', Icons.map_rounded,
                              hint: '0', type: TextInputType.number)),
                    ]),
                    _sec('Schedule'),
                    Row(children: [
                      Expanded(child: _datePicker('Start Date', _start, true)),
                      const SizedBox(width: 12),
                      Expanded(child: _datePicker('End Date', _end, false)),
                    ]),
                    const SizedBox(height: 0),
                    Row(children: [
                      Expanded(child: _datePicker('Reg Start Date', _regStart, true, isReg: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _datePicker('Reg End Date', _regEnd, false, isReg: true)),
                    ]),
                    const SizedBox(height: 28),
                    AppButton(
                        text: 'Create Course',
                        onPressed: _submit,
                        isLoading: prov.isLoading,
                        icon: Icons.add_rounded),
                    const SizedBox(height: 24),
                  ])),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _header(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 8, 20, 20),
        decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
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
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Create Course',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            Text('Add a new course for students',
                style: TextStyle(color: Colors.white60, fontSize: 12)),
          ]),
        ]),
      );

  Widget _sec(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: Row(children: [
        Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(t,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPri(context))),
      ]));

  Widget _f(
    String label,
    String key,
    IconData icon, {
    String? hint,
    TextInputType? type,
    int lines = 1,
    bool req = false,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPri(context))),
      const SizedBox(height: 8),
      TextFormField(
          controller: _c[key],
          keyboardType: type,
          maxLines: lines,
          decoration: InputDecoration(
            hintText: hint ?? 'Enter $label',
            hintStyle: TextStyle(color: AppColors.textHi(context), fontSize: 14),
            prefixIcon: lines == 1
                ? Icon(icon, color: AppColors.textHi(context), size: 20)
                : null,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.borderC(context))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.borderC(context))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.accent, width: 2)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.error)),
          ),
          validator: req ? (v) => v!.isEmpty ? 'Required' : null : null),
      const SizedBox(height: 16),
    ]);
  }

  Widget _datePicker(String label, DateTime? date, bool isStart, {bool isReg = false}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPri(context))),
        const SizedBox(height: 8),
        GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                  builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                          colorScheme:
                              const ColorScheme.light(primary: AppColors.accent)),
                      child: child!));
              if (d != null) {
                setState(() {
                  if (isReg) {
                    if (isStart) { _regStart = d; } else { _regEnd = d; }
                  } else {
                    if (isStart) { _start = d; } else { _end = d; }
                  }
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color:
                          date != null ? AppColors.accent : AppColors.borderC(context))),
              child: Row(children: [
                Icon(Icons.calendar_today_rounded,
                    size: 18,
                    color:
                        date != null ? AppColors.accent : AppColors.textHi(context)),
                const SizedBox(width: 8),
                Text(_fmt(date),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: date != null
                            ? AppColors.textPri(context)
                            : AppColors.textHi(context))),
              ]),
            )),
        const SizedBox(height: 16),
      ]);
}