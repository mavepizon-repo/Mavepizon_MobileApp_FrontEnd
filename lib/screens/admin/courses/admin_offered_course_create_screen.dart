import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/admin_course_management_service.dart';

class AdminOfferedCourseCreateScreen extends StatefulWidget {
  const AdminOfferedCourseCreateScreen({super.key});
  @override
  State<AdminOfferedCourseCreateScreen> createState() =>
      _AdminOfferedCourseCreateScreenState();
}

class _AdminOfferedCourseCreateScreenState
    extends State<AdminOfferedCourseCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _feesCtrl = TextEditingController();
  final _onlineCtrl = TextEditingController();
  final _offlineCtrl = TextEditingController();
  final _tvCtrl = TextEditingController();
  final _tyCtrl = TextEditingController();
  String _status = 'ACTIVE';

  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _regStartDate;
  DateTime? _regEndDate;

  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    _feesCtrl.dispose();
    _onlineCtrl.dispose();
    _offlineCtrl.dispose();
    _tvCtrl.dispose();
    _tyCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate(RxSetter setter, String label) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: 'Select $label',
    );
    if (picked != null) setState(() => setter(picked));
  }

  int _num(String? text) => int.tryParse(text?.trim() ?? '') ?? 0;
  double _fee(String? text) => double.tryParse(text?.trim() ?? '') ?? -1;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null ||
        _endDate == null ||
        _regStartDate == null ||
        _regEndDate == null) {
      _toast('All dates are required');
      return;
    }
    if (_startDate!.isAfter(_endDate!)) {
      _toast('Start Date cannot be after End Date');
      return;
    }
    if (_regStartDate!.isAfter(_regEndDate!)) {
      _toast('Registration Start Date cannot be after Registration End Date');
      return;
    }
    if (_regEndDate!.isAfter(_startDate!)) {
      _toast('Registration End Date cannot be after Course Start Date');
      return;
    }

    final totalFees = _fee(_feesCtrl.text);
    if (totalFees < 0) {
      _toast('Valid Total Fee is required');
      return;
    }

    final online = _num(_onlineCtrl.text);
    final offline = _num(_offlineCtrl.text);
    if (online == 0 && offline == 0) {
      _toast('At least one online or offline seat must be provided');
      return;
    }
    if (_num(_tvCtrl.text) + _num(_tyCtrl.text) > offline) {
      _toast('Tirunelveli and Tisaiyanvilai seats cannot exceed total offline seats');
      return;
    }

    setState(() => _saving = true);
    final data = {
      'courseName': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'duration': _durationCtrl.text.trim(),
      'startDate': _fmtDate(_startDate),
      'endDate': _fmtDate(_endDate),
      'registrationStartDate': _fmtDate(_regStartDate),
      'registrationEndDate': _fmtDate(_regEndDate),
      'totalFees': totalFees,
      'totalSeatsOnline': online,
      'totalSeatsOffline': offline,
      'totalSeatsTirunelveli': _num(_tvCtrl.text),
      'totalSeatsTisaiyanvilai': _num(_tyCtrl.text),
      'status': _status,
    };

    final result =
        await AdminCourseManagementService.createOfferedCourse(data);
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Offered course created'),
            backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true);
    } else {
      _toast(result['message'] ?? 'Failed to create offered course');
    }
    setState(() => _saving = false);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Create Offered Course'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            _buildField('Course Name', _nameCtrl, required: true),
            const SizedBox(height: 14),
            _buildField('Description', _descCtrl, maxLines: 3),
            const SizedBox(height: 14),
            _buildField('Duration (e.g. 3 months)', _durationCtrl),
            const SizedBox(height: 14),
            _buildField('Total Fee (₹)', _feesCtrl,
                required: true, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 14),
            _buildDateField('Start Date', _startDate,
                () => _pickDate((v) => _startDate = v, 'Start Date')),
            const SizedBox(height: 14),
            _buildDateField('End Date', _endDate,
                () => _pickDate((v) => _endDate = v, 'End Date')),
            const SizedBox(height: 14),
            _buildDateField('Registration Start Date', _regStartDate,
                () => _pickDate((v) => _regStartDate = v, 'Registration Start Date')),
            const SizedBox(height: 14),
            _buildDateField('Registration End Date', _regEndDate,
                () => _pickDate((v) => _regEndDate = v, 'Registration End Date')),
            const SizedBox(height: 20),
            Text('Seats', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPri(context))),
            const SizedBox(height: 8),
            _buildField('Online Seats', _onlineCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            _buildField('Offline Seats', _offlineCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            _buildField('Tirunelveli Seats', _tvCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            _buildField('Tisaiyanvilai Seats', _tyCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: _fieldDecoration('Status'),
              items: ['ACTIVE', 'INACTIVE']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? 'ACTIVE'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildField(
      String label, TextEditingController ctrl,
      {bool required = false,
      int maxLines = 1,
      TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? '$label is required' : null
          : null,
      decoration: _fieldDecoration(label),
    );
  }

  Widget _buildDateField(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _fieldDecoration(label),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textHi(context)),
          const SizedBox(width: 10),
          Text(
            value == null ? 'Select date' : _fmtDate(value),
            style: TextStyle(
              color: value == null ? AppColors.textHi(context) : AppColors.textPri(context),
              fontSize: 15,
            ),
          ),
          const Spacer(),
          Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textHi(context)),
        ]),
      ),
    );
  }
}

typedef RxSetter = void Function(DateTime value);