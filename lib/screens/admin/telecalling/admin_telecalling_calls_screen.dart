import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/telecalling_call_service.dart';

/// Admin view of telecalling call follow-ups.
///
/// Shows only calls that were actually connected/talked (callStatus
/// COMPLETED) with the phone number and call duration, filterable by date.
/// Reads records from the backend (GET /api/admin/telecalling/calls) merged
/// with any still-pending local records on the device.
class AdminTelecallingCallsScreen extends StatefulWidget {
  const AdminTelecallingCallsScreen({super.key});

  @override
  State<AdminTelecallingCallsScreen> createState() =>
      _AdminTelecallingCallsScreenState();
}

class _AdminTelecallingCallsScreenState
    extends State<AdminTelecallingCallsScreen> {
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;
  Timer? _timer;

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _load();
    // Refresh every few seconds so newly-synced calls show up live without
    // the admin having to tap the refresh button manually.
    _timer = Timer.periodic(
        const Duration(seconds: 5), (_) => _load(showSpinner: false));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _loading = true);
    try {
      // Push any locally-saved calls that are still pending sync to the
      // backend first, so the admin page reflects the full call history.
      await TelecallingCallService.syncPendingCalls();
      final calls = await TelecallingCallService.getAdminCalls();
      if (!mounted) return;
      setState(() {
        // Show every call log returned by the backend (COMPLETED, NO_ANSWER,
        // BUSY, FAILED, ...) plus any pending local records, so the full
        // history is always visible.
        _all = calls;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _filtered() {
    if (_selectedDate == null) return _all;
    final day = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    return _all.where((c) {
      final start = c['startTime']?.toString() ?? '';
      final t = DateTime.tryParse(start);
      final when = t ?? DateTime.tryParse(c['endTime']?.toString() ?? '');
      if (when == null) return false;
      final d = '${when.year}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')}';
      return d == day;
    }).toList();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  int _totalSeconds(List<Map<String, dynamic>> list) {
    var s = 0;
    for (final c in list) {
      s += int.tryParse(c['durationSeconds']?.toString() ?? '') ?? 0;
    }
    return s;
  }

  String _fmtDuration(int seconds) {
    if (seconds <= 0) return '0s';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  String _fmtDateTime(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered();
    final totalSeconds = _totalSeconds(list);

    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Telecalling Calls',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPri(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded,
                size: 18, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Showing every call made to enquiries, synced to the server, '
                'plus any pending local records.',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSec(context),
                    fontWeight: FontWeight.w600),
              ),
            ),
          ]),
        ),
        // Summary cards
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
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
                child: Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.call_rounded,
                        color: AppColors.success, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${list.length}',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPri(context))),
                        Text('Total calls',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSec(context))),
                      ]),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
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
                child: Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.timelapse_rounded,
                        color: AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fmtDuration(totalSeconds),
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPri(context))),
                        Text('Talk time',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSec(context))),
                      ]),
                ]),
              ),
            ),
          ]),
        ),
        // Date filter
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(children: [
            Expanded(
              child: _FilterChip(
                label: 'All dates',
                selected: _selectedDate == null,
                icon: Icons.calendar_view_month_rounded,
                onTap: () => setState(() => _selectedDate = null),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FilterChip(
                label: 'Today',
                selected: _isTodaySelected,
                icon: Icons.today_rounded,
                onTap: () => setState(
                    () => _selectedDate = DateTime.now()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FilterChip(
                label: _selectedDate != null
                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                    : 'Pick date',
                selected: _selectedDate != null && !_isTodaySelected,
                icon: Icons.event_rounded,
                onTap: _pickDate,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.accent, strokeWidth: 2))
              : list.isEmpty
                  ? ListView(children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.3,
                        child: Center(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.phone_missed_rounded,
                                    size: 60,
                                    color:
                                        AppColors.textHi(context).withOpacity(0.4)),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedDate != null
                                      ? 'No calls recorded on this date'
                                      : 'No calls recorded yet',
                                  style: TextStyle(
                                      color: AppColors.textHi(context)),
                                ),
                              ]),
                        ),
                      ),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: list.length,
                      itemBuilder: (ctx, i) {
                        final c = list[i];
                        return _CallCard(record: c, fmtDateTime: _fmtDateTime);
                      },
                    ),
        ),
      ]),
    );
  }

  bool get _isTodaySelected {
    final d = _selectedDate;
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.borderC(context),
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon,
              size: 15,
              color: selected ? Colors.white : AppColors.textSec(context)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    selected ? Colors.white : AppColors.textSec(context),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _CallCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final String Function(String) fmtDateTime;

  const _CallCard({required this.record, required this.fmtDateTime});

  @override
  Widget build(BuildContext context) {
    final phone = record['phoneNumber']?.toString() ?? '';
    final duration = int.tryParse(record['durationSeconds']?.toString() ?? '') ?? 0;
    final start = record['startTime']?.toString() ?? '';
    final staffId = record['staffId']?.toString() ?? '';
    final staffName = record['staffName']?.toString() ?? '';
    final staffBranch = record['staffBranch']?.toString() ?? '';
    final enquiryId = record['enquiryId']?.toString() ?? '';
    final synced = record['synced'] == true;
    final status = record['callStatus']?.toString().toUpperCase() ?? '';
    final statusColor = status == 'COMPLETED'
        ? AppColors.success
        : (status.isEmpty ? AppColors.textSec(context) : AppColors.warning);
    final staffLabel = staffName.isNotEmpty
        ? staffName
        : (staffId.isNotEmpty ? staffId : '');
    final branchLabel = staffBranch.isNotEmpty ? staffBranch : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.call_rounded,
                color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(phone,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPri(context))),
                  const SizedBox(height: 2),
                  Text(fmtDateTime(start),
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSec(context))),
                ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_fmtDuration(duration),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success)),
          ),
        ]),
        if (status.isNotEmpty) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(status,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor)),
            ),
          ),
        ],
        if (staffLabel.isNotEmpty ||
            branchLabel.isNotEmpty ||
            enquiryId.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(children: [
            if (staffLabel.isNotEmpty)
              Text(staffLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSec(context))),
            if (branchLabel.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(branchLabel,
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textHi(context))),
            ],
            if ((staffLabel.isNotEmpty || branchLabel.isNotEmpty) &&
                enquiryId.isNotEmpty)
              const SizedBox(width: 12),
            if (enquiryId.isNotEmpty)
              Text('Enquiry: $enquiryId',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textHi(context))),
            const Spacer(),
            if (staffId.isNotEmpty)
              Text(synced ? 'Synced' : 'Pending sync',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color:
                          synced ? AppColors.success : AppColors.warning)),
          ]),
        ],
      ]),
    );
  }

  String _fmtDuration(int seconds) {
    if (seconds <= 0) return '0s';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}