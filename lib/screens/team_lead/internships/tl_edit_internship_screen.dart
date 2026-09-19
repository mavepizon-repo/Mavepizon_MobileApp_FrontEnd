import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/internship_provider.dart';
import '../../../widgets/app_button.dart';

class TlEditInternshipScreen extends ConsumerStatefulWidget {
  final String internshipId;
  const TlEditInternshipScreen({super.key, required this.internshipId});

  @override
  ConsumerState<TlEditInternshipScreen> createState() => _TlEditInternshipScreenState();
}

class _TlEditInternshipScreenState extends ConsumerState<TlEditInternshipScreen> {
  final _formKey = GlobalKey<FormState>();
  final _c = <String, TextEditingController>{};

  DateTime? _start, _end, _regStart, _regEnd;
  bool _isLoading = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadInternship();
  }

  void _loadInternship() {
    final internship = ref.read(internshipProvider).list.firstWhere(
      (i) => i.id == widget.internshipId,
      orElse: () => throw Exception('Internship not found'),
    );

    _c['name'] = TextEditingController(text: internship.internshipName);
    _c['desc'] = TextEditingController(text: internship.description);
    _c['duration'] = TextEditingController(text: internship.duration);
    _c['fees'] = TextEditingController(text: internship.fees.toString());
    _c['online'] =
        TextEditingController(text: internship.totalSeatsOnline.toString());
    _c['offline'] =
        TextEditingController(text: internship.totalSeatsOffline.toString());
    _c['tvl'] =
        TextEditingController(text: internship.totalSeatsTirunelveli.toString());
    _c['ty'] =
        TextEditingController(text: internship.totalSeatsTisaiyanvilai.toString());

    _start = DateTime.tryParse(internship.startDate);
    _end = DateTime.tryParse(internship.endDate);
    _regStart = DateTime.tryParse(internship.registrationStartDate);
    _regEnd = DateTime.tryParse(internship.registrationEndDate);

    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    for (var c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
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

  Future<void> _pickRegDate(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    if (d != null) {
      setState(() {
        if (isStart) {
          _regStart = d;
        } else {
          _regEnd = d;
        }
      });
    }
  }

  String _fmt(DateTime? d) => d == null ? 'Pick date'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _dateOnly(DateTime d) {
    final year = d.year.toString().padLeft(4, '0');
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_start == null || _end == null) {
      _snack('Select start and end dates', AppColors.error);
      return;
    }

    final data = {
      'internshipName': _c['name']!.text.trim(),
      'description': _c['desc']!.text.trim(),
      'duration': _c['duration']!.text.trim(),
      'fees': double.tryParse(_c['fees']!.text) ?? 0,
      'totalSeatsOnline': int.tryParse(_c['online']!.text) ?? 0,
      'totalSeatsOffline': int.tryParse(_c['offline']!.text) ?? 0,
      'totalSeatsTirunelveli': int.tryParse(_c['tvl']!.text) ?? 0,
      'totalSeatsTisaiyanvilai': int.tryParse(_c['ty']!.text) ?? 0,
      'startDate': _dateOnly(_start!),
      'endDate': _dateOnly(_end!),
      'registrationStartDate':
          _regStart != null ? _dateOnly(_regStart!) : '',
      'registrationEndDate':
          _regEnd != null ? _dateOnly(_regEnd!) : '',
      'category': 'INTERNSHIP',
    };

    setState(() => _isLoading = true);
    final ok = await ref
        .read(internshipProvider.notifier)
        .update(widget.internshipId, data);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      _snack('Internship updated!', AppColors.success);
      Navigator.pop(context);
    } else {
      _snack(ref.read(internshipProvider).error ?? 'Update failed',
          AppColors.error);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ? FIX: Removed prov.isLoading check � was hiding form during submit.
    // Only _loaded controls initial loading. Button handles its own loading.
    if (!_loaded) {
      return const Scaffold(
        
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

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
                  _sec('Internship Info'),
                  _f('Internship Name', 'name', Icons.work_rounded, req: true),
                  _f('Description', 'desc', Icons.description_rounded,
                      lines: 3),
                  _f('Duration', 'duration', Icons.timer_rounded,
                      hint: 'e.g. 6 weeks'),
                  _sec('Fees'),
                  Row(children: [
                    Expanded(
                      child: _f(
                          'Total Fees ?', 'fees', Icons.currency_rupee_rounded,
                          hint: '0', type: TextInputType.number),
                    ),
                  ]),
                  _sec('Seats'),
                  Row(children: [
                    Expanded(
                      child: _f(
                          'Online Seats', 'online', Icons.computer_rounded,
                          hint: '0', type: TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _f(
                          'Offline Seats', 'offline', Icons.people_rounded,
                          hint: '0', type: TextInputType.number),
                    ),
                  ]),
                  Row(children: [
                    Expanded(
                      child: _f(
                          'Tirunelveli Seats', 'tvl',
                          Icons.location_city_rounded,
                          hint: '0', type: TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _f(
                          'Tisaiyanvilai Seats', 'ty',
                          Icons.location_city_rounded,
                          hint: '0', type: TextInputType.number),
                    ),
                  ]),
                  _sec('Schedule'),
                  Row(children: [
                    Expanded(child: _datePicker('Start Date', _start, true)),
                    const SizedBox(width: 12),
                    Expanded(child: _datePicker('End Date', _end, false)),
                  ]),
                  Row(children: [
                    Expanded(
                        child:
                            _regDatePicker('Reg. Start Date', _regStart, true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child:
                            _regDatePicker('Reg. End Date', _regEnd, false)),
                  ]),
                  const SizedBox(height: 28),
                  AppButton(
                    text: 'Update Internship',
                    onPressed: _submit,
                    isLoading: _isLoading,
                    icon: Icons.save_rounded,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
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
            bottomRight: Radius.circular(28),
          ),
        ),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Internship',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              Text('Update internship details',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ]),
      );

  Widget _sec(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 14, top: 4),
        child: Row(children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.card2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(t,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPri(context))),
        ]),
      );

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
            borderSide: BorderSide(color: AppColors.borderC(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.borderC(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.accent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error),
          ),
        ),
        validator: req ? (v) => v!.isEmpty ? 'Required' : null : null,
      ),
      const SizedBox(height: 16),
    ]);
  }

  Widget _datePicker(String label, DateTime? date, bool isStart) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPri(context))),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickDate(isStart),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: date != null ? AppColors.accent : AppColors.borderC(context)),
              ),
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
            ),
          ),
          const SizedBox(height: 16),
        ],
      );

  Widget _regDatePicker(String label, DateTime? date, bool isStart) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPri(context))),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickRegDate(isStart),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: date != null ? AppColors.accent : AppColors.borderC(context)),
              ),
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
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
}
