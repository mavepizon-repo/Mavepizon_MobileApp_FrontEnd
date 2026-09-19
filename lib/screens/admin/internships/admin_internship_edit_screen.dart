import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/internship_model.dart';
import '../../../providers/internship_provider.dart';
import '../../../services/internship_service.dart';

class AdminInternshipEditScreen extends ConsumerStatefulWidget {
  final String internshipId;
  const AdminInternshipEditScreen({super.key, required this.internshipId});
  @override
  ConsumerState<AdminInternshipEditScreen> createState() =>
      _AdminInternshipEditScreenState();
}

class _AdminInternshipEditScreenState
    extends ConsumerState<AdminInternshipEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _feesCtrl = TextEditingController();
  final _onlineTotalCtrl = TextEditingController();
  final _offlineTotalCtrl = TextEditingController();
  final _tvlTotalCtrl = TextEditingController();
  final _tyTotalCtrl = TextEditingController();

  String _durationType = 'WEEKS';
  int _durationValue = 1;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _regStart;
  DateTime? _regEnd;
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _feesCtrl.dispose();
    _onlineTotalCtrl.dispose();
    _offlineTotalCtrl.dispose();
    _tvlTotalCtrl.dispose();
    _tyTotalCtrl.dispose();
    super.dispose();
  }

  void _populate(InternshipModel c) {
    if (_loaded) return;
    _nameCtrl.text = c.internshipName;
    _descCtrl.text = c.description;
    _feesCtrl.text = c.fees.toStringAsFixed(0);
    _onlineTotalCtrl.text = c.totalSeatsOnline.toString();
    _offlineTotalCtrl.text = c.totalSeatsOffline.toString();
    _tvlTotalCtrl.text = c.totalSeatsTirunelveli.toString();
    _tyTotalCtrl.text = c.totalSeatsTisaiyanvilai.toString();

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
      _regStart = DateTime.tryParse(c.registrationStartDate);
    }
    if (c.registrationEndDate.isNotEmpty) {
      _regEnd = DateTime.tryParse(c.registrationEndDate);
    }
    _loaded = true;
  }

  Future<void> _pickDate(bool isStart) async {
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
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  Future<void> _pickRegDate(bool isStart) async {
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
        if (isStart) _regStart = picked;
        else _regEnd = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'internshipName': _nameCtrl.text,
      'description': _descCtrl.text,
      'duration': '$_durationValue $_durationType',
      'startDate': _startDate?.toIso8601String().split('T').first ?? '',
      'endDate': _endDate?.toIso8601String().split('T').first ?? '',
      'registrationStartDate':
          _regStart?.toIso8601String().split('T').first ?? '',
      'registrationEndDate':
          _regEnd?.toIso8601String().split('T').first ?? '',
      'fees': double.tryParse(_feesCtrl.text) ?? 0,
      'totalSeatsOnline': int.tryParse(_onlineTotalCtrl.text) ?? 0,
      'totalSeatsOffline': int.tryParse(_offlineTotalCtrl.text) ?? 0,
      'totalSeatsTirunelveli': int.tryParse(_tvlTotalCtrl.text) ?? 0,
      'totalSeatsTisaiyanvilai': int.tryParse(_tyTotalCtrl.text) ?? 0,
      'category': 'INTERNSHIP',
    };

    final ok = await ref
        .read(internshipProvider.notifier)
        .update(widget.internshipId, data);
    if (mounted) {
      setState(() => _saving = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Internship updated successfully')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.error,
            content:
                Text(ref.read(internshipProvider).error ?? 'Failed')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Edit Internship'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: InternshipService.getById(widget.internshipId),
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
          final internship =
              InternshipModel.fromJson(snap.data!['data']);
          _populate(internship);

          return Form(
            key: _formKey,
            child:
                ListView(padding: const EdgeInsets.all(16), children: [
              _Field(label: 'Internship Name', controller: _nameCtrl, required: true),
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
                        setState(() => _durationType = v ?? 'WEEKS'),
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
                  value: _regStart,
                  onTap: () => _pickRegDate(true)),
              const SizedBox(height: 14),
              _DateField(
                  label: 'Registration End Date',
                  value: _regEnd,
                  onTap: () => _pickRegDate(false)),
              const SizedBox(height: 14),
              _Field(
                  label: 'Fees',
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
                  controller: _tvlTotalCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              _Field(
                  label: 'Total Seats Tisaiyanvilai',
                  controller: _tyTotalCtrl,
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
