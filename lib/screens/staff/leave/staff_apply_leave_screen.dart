import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../providers/staff_leave_provider.dart';

class StaffApplyLeaveScreen extends ConsumerStatefulWidget {
  const StaffApplyLeaveScreen({super.key});

  @override
  ConsumerState<StaffApplyLeaveScreen> createState() =>
      _StaffApplyLeaveScreenState();
}

class _StaffApplyLeaveScreenState extends ConsumerState<StaffApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  String _staffId = '';
  final _reasonCtrl = TextEditingController();
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now().add(const Duration(days: 1));
  bool _halfDay = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _staffId = await StorageHelper.getStaffId() ?? '';
  }

  Future<void> _pickDate(bool isFrom) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) {
      setState(() {
        if (isFrom) {
          _from = d;
          if (_to.isBefore(_from)) _to = _from.add(const Duration(days: 1));
        } else {
          _to = d;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final data = {
      'leaveType': _halfDay ? 'HALF_DAY' : 'FULL_DAY',
      'startDate': _from.toIso8601String().substring(0, 10),
      'endDate': _to.toIso8601String().substring(0, 10),
      'reason': _reasonCtrl.text.trim(),
    };

    final ok = await ref
        .read(staffLeaveProvider.notifier)
        .applyLeave(_staffId, data);

    setState(() => _submitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Leave applied successfully' : 'Failed to apply leave'),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ),
      );
      if (ok) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diff = _to.difference(_from).inDays + 1;

    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Apply Leave',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPri(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ]),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Leave Type',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPri(context))),
                const SizedBox(height: 10),
                Row(children: [
                  _TypeChip('Full Day', !_halfDay, () => setState(() => _halfDay = false)),
                  const SizedBox(width: 10),
                  _TypeChip('Half Day', _halfDay, () => setState(() => _halfDay = true)),
                ]),
                const SizedBox(height: 22),
                _DateField(
                    label: 'From Date',
                    value: _from,
                    onTap: () => _pickDate(true)),
                const SizedBox(height: 14),
                _DateField(
                    label: 'To Date',
                    value: _to,
                    onTap: () => _pickDate(false)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Text('Total Days: ',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSec(context))),
                    Text('$diff day${diff > 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    if (_halfDay) ...[
                      const SizedBox(width: 6),
                      Text('(half day)',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textHi(context))),
                    ]
                  ]),
                ),
                const SizedBox(height: 22),
                Text('Reason',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPri(context))),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reasonCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter reason for leave...',
                    hintStyle: TextStyle(color: AppColors.textHi(context)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.accent, width: 1.5),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Reason is required' : null,
                ),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Leave Request',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                      context, '/staff/leave-history');
                },
                child: const Text('View Leave History',
                    style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip(
      this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : AppColors.textSec(context),
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final VoidCallback onTap;
  const _DateField(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded,
              size: 16, color: AppColors.textSec(context)),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSec(context))),
          const SizedBox(width: 8),
          Text(
              '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPri(context))),
        ]),
      ),
    );
  }
}