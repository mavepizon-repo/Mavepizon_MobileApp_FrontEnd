import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/course_model.dart';
import '../../../providers/course_provider.dart';
import '../../../services/course_service.dart';

class AdminCourseEditScreen extends ConsumerStatefulWidget {
  final String courseId;
  const AdminCourseEditScreen({super.key, required this.courseId});
  @override
  ConsumerState<AdminCourseEditScreen> createState() =>
      _AdminCourseEditScreenState();
}

class _AdminCourseEditScreenState extends ConsumerState<AdminCourseEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _feesCtrl = TextEditingController();
  final _onlineTotalCtrl = TextEditingController();
  final _offlineTotalCtrl = TextEditingController();
  final _tirunelveliTotalCtrl = TextEditingController();
  final _tisaiyanvilaiTotalCtrl = TextEditingController();

  String _durationType = 'MONTHS';
  int _durationValue = 1;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _regStartDate;
  DateTime? _regEndDate;
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _feesCtrl.dispose();
    _onlineTotalCtrl.dispose();
    _offlineTotalCtrl.dispose();
    _tirunelveliTotalCtrl.dispose();
    _tisaiyanvilaiTotalCtrl.dispose();
    super.dispose();
  }

  void _populate(CourseModel c) {
    if (_loaded) return;
    _nameCtrl.text = c.courseName;
    _descCtrl.text = c.description;
    _feesCtrl.text = c.totalFees.toStringAsFixed(0);
    _onlineTotalCtrl.text = c.totalSeatsOnline.toString();
    _offlineTotalCtrl.text = c.totalSeatsOffline.toString();
    _tirunelveliTotalCtrl.text = c.totalSeatsTirunelveli.toString();
    _tisaiyanvilaiTotalCtrl.text = c.totalSeatsTisaiyanvilai.toString();
    // Category is no longer editable here, so there's nothing to load.

    final parts = c.duration.split(' ');
    if (parts.length == 2) {
      _durationValue = int.tryParse(parts[0]) ?? 1;
      _durationType = parts[1];
    }

    if (c.startDate.isNotEmpty) {
      _startDate = DateTime.tryParse(c.startDate);
    }
    if (c.endDate.isNotEmpty) {
      _endDate = DateTime.tryParse(c.endDate);
    }
    if (c.registrationStartDate.isNotEmpty) {
      _regStartDate = DateTime.tryParse(c.registrationStartDate);
    }
    if (c.registrationEndDate.isNotEmpty) {
      _regEndDate = DateTime.tryParse(c.registrationEndDate);
    }
    _loaded = true;
  }

  Future<void> _pickDate(bool isStart, {bool registration = false}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (_, child) => Theme(
          data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.accent)),
          child: child!),
    );
    if (picked != null) {
      setState(() {
        if (registration) {
          if (isStart) {
            _regStartDate = picked;
          } else {
            _regEndDate = picked;
          }
        } else {
          if (isStart) {
            _startDate = picked;
          } else {
            _endDate = picked;
          }
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'courseName': _nameCtrl.text,
      'description': _descCtrl.text,
      'duration': '$_durationValue $_durationType',
      'startDate': _startDate?.toIso8601String().split('T').first ?? '',
      'endDate': _endDate?.toIso8601String().split('T').first ?? '',
      'registrationStartDate':
          _regStartDate?.toIso8601String().split('T').first ?? '',
      'registrationEndDate':
          _regEndDate?.toIso8601String().split('T').first ?? '',
      'totalFees': double.tryParse(_feesCtrl.text) ?? 0,
      'totalSeatsOnline': int.tryParse(_onlineTotalCtrl.text) ?? 0,
      'totalSeatsOffline': int.tryParse(_offlineTotalCtrl.text) ?? 0,
      'totalSeatsTirunelveli': int.tryParse(_tirunelveliTotalCtrl.text) ?? 0,
      'totalSeatsTisaiyanvilai':
          int.tryParse(_tisaiyanvilaiTotalCtrl.text) ?? 0,
      // Category is set once at creation and isn't meant to change.
    };

    final ok =
        await ref.read(courseProvider.notifier).update(widget.courseId, data);
    if (mounted) {
      setState(() => _saving = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Course updated successfully')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.error,
            content:
                Text(ref.read(courseProvider).error ?? 'Failed')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Edit Course'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: CourseService.getById(widget.courseId),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.accent));
          }
          if (snap.hasError || (snap.data?['success'] != true)) {
            return Center(
                child: Text(snap.data?['message'] ?? 'Failed to load'));
          }
          final course =
              CourseModel.fromJson(snap.data!['data']);
          _populate(course);

          return Form(
            key: _formKey,
            child:
                ListView(padding: const EdgeInsets.all(16), children: [
              _Field(label: 'Course Name', controller: _nameCtrl, required: true),
              const SizedBox(height: 14),
              _Field(
                  label: 'Description',
                  controller: _descCtrl,
                  maxLines: 3),
              const SizedBox(height: 14),
              Text('Duration',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSec(context))),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: _durationValue.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        _durationValue = int.tryParse(v) ?? 1,
                    decoration: _inputDec(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _durationType,
                    items: ['WEEKS', 'MONTHS']
                        .map((e) => DropdownMenuItem(
                            value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _durationType = v ?? 'MONTHS'),
                    decoration: _inputDec(),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              _DateField(
                  label: 'Start Date',
                  value: _startDate,
                  onTap: () => _pickDate(true)),
              const SizedBox(height: 14),
              _DateField(
                  label: 'End Date',
                  value: _endDate,
                  onTap: () => _pickDate(false)),
              const SizedBox(height: 14),
              _DateField(
                  label: 'Registration Start Date',
                  value: _regStartDate,
                  onTap: () => _pickDate(true, registration: true)),
              const SizedBox(height: 14),
              _DateField(
                  label: 'Registration End Date',
                  value: _regEndDate,
                  onTap: () => _pickDate(false, registration: true)),
              const SizedBox(height: 14),
              _Field(
                  label: 'Total Fees (₹)',
                  controller: _feesCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              _Field(
                  label: 'Total Seats Online',
                  controller: _onlineTotalCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              _Field(
                  label: 'Total Seats Offline',
                  controller: _offlineTotalCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              _Field(
                  label: 'Total Seats Tirunelveli',
                  controller: _tirunelveliTotalCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              _Field(
                  label: 'Total Seats Tisaiyanvilai',
                  controller: _tisaiyanvilaiTotalCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12))),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                      : const Text('Update',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  InputDecoration _inputDec() {
    return InputDecoration(
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderC(context))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderC(context))),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool required;
  final TextInputType? keyboardType;
  final int maxLines;
  const _Field({
    required this.label,
    required this.controller,
    this.required = false,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: required
          ? (v) =>
              (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.borderC(context))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.borderC(context))),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  const _DateField(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderC(context)),
        ),
        child: Row(children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textHi(context))),
          const Spacer(),
          Text(
            value != null
                ? '${value!.day}/${value!.month}/${value!.year}'
                : 'Select',
            style: TextStyle(
                fontSize: 14,
                color: value != null
                    ? AppColors.textPri(context)
                    : AppColors.textHi(context)),
          ),
          const SizedBox(width: 4),
          Icon(Icons.calendar_today_rounded,
              size: 16, color: AppColors.textHi(context)),
        ]),
      ),
    );
  }
}