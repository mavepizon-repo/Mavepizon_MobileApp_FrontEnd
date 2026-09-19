import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/staff_permission_provider.dart';

class StaffApplyPermissionScreen extends ConsumerStatefulWidget {
  const StaffApplyPermissionScreen({super.key});

  @override
  ConsumerState<StaffApplyPermissionScreen> createState() =>
      _StaffApplyPermissionScreenState();
}

class _StaffApplyPermissionScreenState
    extends ConsumerState<StaffApplyPermissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  int _durationHours = 1;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    ref.read(staffPermissionProvider.notifier).fetchHistory();
  }

  int _countRemaining() {
    final perms = ref.read(staffPermissionProvider).permissions;
    final now = DateTime.now();
    final count = perms.where((p) {
      final d = p['permissionDate']?.toString() ?? '';
      return d.startsWith('${now.year}-${now.month.toString().padLeft(2, '0')}');
    }).length;
    return (2 - count).clamp(0, 2);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (d != null) setState(() => _date = d);
  }

  void _setDuration(int hours) {
    setState(() => _durationHours = hours);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final remaining = _countRemaining();
    if (remaining <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have used all 2 permissions this month'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _submitting = true);

    final data = {
      'permissionDate': _date.toIso8601String().substring(0, 10),
      'durationHours': _durationHours,
      'reason': _reasonCtrl.text.trim(),
    };

    final ok = await ref
        .read(staffPermissionProvider.notifier)
        .applyPermission(data);

    setState(() => _submitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              ok ? 'Permission applied' : 'Failed to apply permission'),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ),
      );
      if (ok) {
        // Navigate to permission history tab
        Navigator.pop(context);
        // The parent StaffMainScreen will handle tab switching
        // We need to signal to switch to permission history tab
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
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Apply Permission',
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
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textPri(context)),
                        children: [
                          TextSpan(
                              text: '${_countRemaining()}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          const TextSpan(
                              text:
                                  ' of 2 permissions remaining this month'),
                          const TextSpan(
                              text:
                                  '\nAuto-routed to your office Team Lead'),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
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
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 16, color: AppColors.textSec(context)),
                      const SizedBox(width: 10),
                      Text('Date',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSec(context))),
                      const SizedBox(width: 8),
                      Text(
                          '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPri(context))),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Duration',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPri(context))),
                const SizedBox(height: 8),
                Row(children: [
                  _DurationChip('1 Hour', _durationHours == 1,
                      () => _setDuration(1)),
                  const SizedBox(width: 10),
                  _DurationChip('2 Hours', _durationHours == 2,
                      () => _setDuration(2)),
                  const SizedBox(width: 10),
                  Text('1 or 2 hours',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSec(context))),
                ]),
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
                    hintText: 'Enter reason for permission...',
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
                    : const Text('Submit Permission Request',
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
                      context, '/staff/permission-history');
                },
                child: const Text('View Permission History',
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

class _DurationChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DurationChip(this.label, this.selected, this.onTap);

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