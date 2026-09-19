import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/permission_provider.dart';
import '../../../services/permission_service.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_widget.dart';
import '../../../widgets/status_badge.dart';

class TlApplyPermissionScreen extends ConsumerStatefulWidget {
  const TlApplyPermissionScreen({super.key});
  @override
  ConsumerState<TlApplyPermissionScreen> createState() =>
      _TlApplyPermissionScreenState();
}

class _TlApplyPermissionScreenState
    extends ConsumerState<TlApplyPermissionScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _date;
  final _reasonCtrl = TextEditingController();
  int _durationHours = 1;
  bool _submitting = false;
  List<Map<String, dynamic>> _history = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    setState(() => _loadingHistory = true);
    final res = await PermissionService.getMyPermissionHistory();
    if (!mounted) return;
    if (res['success'] == true) {
      final d = res['data'];
      if (d is List) {
        _history = d.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{}).cast<Map<String, dynamic>>().toList();
      } else if (d is Map && d['data'] is List) {
        _history = (d['data'] as List).map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{}).cast<Map<String, dynamic>>().toList();
      }
    }
    setState(() => _loadingHistory = false);
  }

  Future<void> _pickDate() async {
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
    if (d != null) setState(() => _date = d);
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'Select date';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a date'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _submitting = true);

    final data = {
      'permissionDate':
          '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
      'durationHours': _durationHours,
      'reason': _reasonCtrl.text,
    };

    final success =
        await ref.read(permissionProvider.notifier).applyOwnPermission(data);
    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? 'Permission request submitted to Admin'
          : 'Failed to submit permission request'),
      backgroundColor: success ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
    if (success) {
      _reasonCtrl.clear();
      setState(() => _date = null);
      _fetchHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SingleChildScrollView(
        child: Column(children: [
          Container(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 8, 20, 24),
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
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
              const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Apply Permission',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    Text('Request 1 or 2-hour permission from Admin',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ]),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Permission Details',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPri(context))),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderC(context)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 16, color: AppColors.accent),
                              const SizedBox(width: 8),
                              Text(_fmt(_date),
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSec(context))),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Duration',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPri(context))),
                        const SizedBox(height: 8),
                        Row(children: [
                          _durChip('1 Hour', _durationHours == 1, () =>
                              setState(() => _durationHours = 1)),
                          const SizedBox(width: 10),
                          _durChip('2 Hours', _durationHours == 2, () =>
                              setState(() => _durationHours = 2)),
                          const SizedBox(width: 10),
                          Text('1 or 2 hours',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSec(context))),
                        ]),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _reasonCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Reason for permission',
                            hintStyle: const TextStyle(fontSize: 13),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: AppColors.borderC(context))),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Reason is required'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: _submitting ? null : _submit,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)
                              ]),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: _submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2))
                                  : const Text('Submit Permission Request',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ]),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColors.warning),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You can apply for 2 permissions per month (1 hour each). '
                        'Request will be sent to Admin for approval.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            height: 1.4),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          _buildHistorySection(),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _buildHistorySection() {
    Widget content;
    if (_loadingHistory) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(
            color: AppColors.accent, strokeWidth: 2)),
      );
    } else if (_history.isEmpty) {
      content = Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(children: [
            Icon(Icons.timer_off_rounded,
                size: 36, color: AppColors.textHi(context)),
            SizedBox(height: 8),
            Text('No permission requests yet',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textHi(context))),
          ]),
        ),
      );
    } else {
      content = Column(
        children: _history.map((item) {
          final date =
              item['permissionDate']?.toString() ?? '';
          final time =
              item['durationHours']?.toString() ?? '1';
          final reason =
              item['reason']?.toString() ?? '';
          final remarks =
              item['remarks']?.toString() ?? '';
          final status =
              item['status']?.toString() ?? 'PENDING';
          return Container(
            margin: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 4),
            padding: const EdgeInsets.all(14),
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
                  Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Permission',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPri(context))),
                        StatusBadge(
                            status: status, fontSize: 10),
                      ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: AppColors.textHi(context)),
                    const SizedBox(width: 5),
                    Text(date,
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSec(context))),
                    const SizedBox(width: 14),
                    Icon(Icons.timer_rounded,
                        size: 13,
                        color: AppColors.textHi(context)),
                    const SizedBox(width: 5),
                    Text('$time hr',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSec(context))),
                  ]),
                  if (reason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(reason,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHi(context))),
                  ],
                  if (remarks.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.feedback_rounded,
                          size: 13,
                          color: Color(0xFFEF4444)),
                      const SizedBox(width: 5),
                      Text('Admin: ',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEF4444))),
                    ]),
                    const SizedBox(height: 2),
                    Text(remarks,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFEF4444))),
                  ],
                ]),
          );
        }).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My Requests',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPri(context))),
              GestureDetector(
                onTap: _fetchHistory,
                child: const Icon(Icons.refresh_rounded,
                    size: 20, color: AppColors.accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _durChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
