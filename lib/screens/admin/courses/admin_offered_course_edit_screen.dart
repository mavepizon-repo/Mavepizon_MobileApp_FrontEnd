import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/admin_course_management_service.dart';

class AdminOfferedCourseEditScreen extends StatefulWidget {
  final String courseId;
  const AdminOfferedCourseEditScreen({super.key, required this.courseId});
  @override
  State<AdminOfferedCourseEditScreen> createState() =>
      _AdminOfferedCourseEditScreenState();
}

class _AdminOfferedCourseEditScreenState
    extends State<AdminOfferedCourseEditScreen> {
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
  String _courseCode = '';
  String _batchId = '';

  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _regStartDate;
  DateTime? _regEndDate;

  int _registeredOnline = 0;
  int _registeredOffline = 0;
  int _registeredTv = 0;
  int _registeredTy = 0;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

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

  Future<void> _load() async {
    setState(() => _loading = true);
    final result =
        await AdminCourseManagementService.getOfferedCourseById(widget.courseId);
    if (result['success'] == true && result['data'] is Map) {
      final d = result['data'] as Map;
      _nameCtrl.text = (d['courseName'] ?? '').toString();
      _descCtrl.text = (d['description'] ?? '').toString();
      _durationCtrl.text = (d['duration'] ?? '').toString();
      _feesCtrl.text = (d['totalFees'] ?? '').toString();
      _onlineCtrl.text =
          ((d['totalSeatsOnline'] ?? 0)).toString();
      _offlineCtrl.text =
          ((d['totalSeatsOffline'] ?? 0)).toString();
      _tvCtrl.text = ((d['totalSeatsTirunelveli'] ?? 0)).toString();
      _tyCtrl.text = ((d['totalSeatsTisaiyanvilai'] ?? 0)).toString();
      _status = (d['status'] ?? 'ACTIVE').toString().toUpperCase();
      _courseCode = (d['courseCode'] ?? '').toString();
      _batchId = (d['batchId'] ?? '').toString();
      _startDate = _parseDate((d['startDate'] ?? '').toString());
      _endDate = _parseDate((d['endDate'] ?? '').toString());
      _regStartDate =
          _parseDate((d['registrationStartDate'] ?? '').toString());
      _regEndDate = _parseDate((d['registrationEndDate'] ?? '').toString());
      _registeredOnline = int.tryParse((d['registeredSeatsOnline'] ?? 0).toString()) ?? 0;
      _registeredOffline = int.tryParse((d['registeredSeatsOffline'] ?? 0).toString()) ?? 0;
      _registeredTv = int.tryParse((d['registeredSeatsTirunelveli'] ?? 0).toString()) ?? 0;
      _registeredTy = int.tryParse((d['registeredSeatsTisaiyanvilai'] ?? 0).toString()) ?? 0;
    }
    if (mounted) setState(() => _loading = false);
  }

  DateTime? _parseDate(String s) {
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
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
    if (online < _registeredOnline) {
      _toast('Online total seats cannot be less than already registered seats ($_registeredOnline)');
      return;
    }
    if (offline < _registeredOffline) {
      _toast('Offline total seats cannot be less than already registered seats ($_registeredOffline)');
      return;
    }
    if (_num(_tvCtrl.text) < _registeredTv) {
      _toast('Tirunelveli total seats cannot be less than already registered seats ($_registeredTv)');
      return;
    }
    if (_num(_tyCtrl.text) < _registeredTy) {
      _toast('Tisaiyanvilai total seats cannot be less than already registered seats ($_registeredTy)');
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

    final result = await AdminCourseManagementService.updateOfferedCourse(
        widget.courseId, data);
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Offered course updated'),
            backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true);
    } else {
      _toast(result['message'] ?? 'Failed to update offered course');
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
        title: const Text('Edit Offered Course'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(children: [
                  _buildInfoRow('Course Code', _courseCode),
                  const SizedBox(height: 8),
                  _buildInfoRow('Batch ID', _batchId),
                  const SizedBox(height: 20),
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
                          : const Text('Update', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Text('$label: ',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSec(context))),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
        ),
      ]),
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