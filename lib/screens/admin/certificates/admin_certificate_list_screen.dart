import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/string_utils.dart';
import '../../../providers/certificate_provider.dart';
import '../../../widgets/status_badge.dart';
import '../../../routes/app_routes.dart';

class AdminCertificateListScreen extends ConsumerStatefulWidget {
  const AdminCertificateListScreen({super.key});
  @override
  ConsumerState<AdminCertificateListScreen> createState() =>
      _AdminCertificateListScreenState();
}

class _AdminCertificateListScreenState
    extends ConsumerState<AdminCertificateListScreen> {
  final _searchCtrl = TextEditingController();
  String _collegeFilter = '';
  String _deptFilter = '';
  String _statusFilter = '';
  String _monthFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;

  List<String> get _departments {
    final all = ref.read(certificateProvider).list;
    return all
        .map((c) => c.department)
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(certificateProvider.notifier).fetch());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _colleges {
    final all = ref.read(certificateProvider).list;
    return all
        .map((c) => c.collegeName)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(certificateProvider);
    final list = p.list;

    var filtered = list.where((c) {
      final q = _searchCtrl.text.toLowerCase();
      if (q.isNotEmpty &&
          !c.studentName.toLowerCase().contains(q) &&
          !c.studentId.toLowerCase().contains(q))
        return false;
      if (_collegeFilter.isNotEmpty &&
          !c.collegeName.toLowerCase().contains(_collegeFilter.toLowerCase()))
        return false;
      if (_deptFilter.isNotEmpty &&
          !c.department.toLowerCase().contains(_deptFilter.toLowerCase()))
        return false;
      if (_statusFilter.isNotEmpty &&
          !c.status.toUpperCase().contains(_statusFilter))
        return false;
      if (_monthFilter.isNotEmpty) {
        final d = DateTime.tryParse(truncate(c.registrationDate, 10));
        if (d != null) {
          final mm = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
          if (mm != _monthFilter) return false;
        }
      }
      if (_startDate != null || _endDate != null) {
        final d = DateTime.tryParse(truncate(c.registrationDate, 10));
        if (d != null) {
          if (_startDate != null && d.isBefore(_startDate!)) return false;
          if (_endDate != null && d.isAfter(_endDate!)) return false;
        }
      }
      return true;
    }).toList();

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Certificate Management'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        // Search
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by student name or ID...',
              prefixIcon:
                  Icon(Icons.search_rounded, color: AppColors.textHi(context)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      })
                  : null,
            ),
          ),
        ),
        // Filters
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _FChip(context, 'All Status', '', _statusFilter, (v) {
                setState(() => _statusFilter = v);
              }),
              _FChip(context, 'Pending', 'PENDING', _statusFilter, (v) {
                setState(() => _statusFilter = v);
              }),
              _FChip(context, 'Issued', 'ISSUED', _statusFilter, (v) {
                setState(() => _statusFilter = v);
              }),
              const SizedBox(width: 12),
              _FChip(context, 'All Colleges', '', _collegeFilter, (v) {
                setState(() => _collegeFilter = v);
              }),
              ..._colleges.take(6).map((c) =>
                  _FChip(context, c.length > 12 ? '${c.substring(0, 12)}..' : c,
                      c, _collegeFilter, (v) {
                    setState(() => _collegeFilter = v);
                  })),
              const SizedBox(width: 8),
              _FChip(context, 'All Depts', '', _deptFilter, (v) {
                setState(() => _deptFilter = v);
              }),
              ..._departments.take(6).map((d) =>
                  _FChip(context, d.length > 12 ? '${d.substring(0, 12)}..' : d,
                      d, _deptFilter, (v) {
                    setState(() => _deptFilter = v);
                  })),
            ]),
          ),
        ),
        // Date Range
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() {
                    _startDate = picked;
                    _monthFilter = '';
                  });
                },
                icon: const Icon(Icons.date_range_rounded, size: 16),
                label: Text(
                    _startDate == null
                        ? 'Start Date'
                        : _startDate!.toIso8601String().substring(0, 10),
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textPri(context))),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('to', style: TextStyle(color: AppColors.textHi(context))),
            ),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() {
                    _endDate = picked;
                    _monthFilter = '';
                  });
                },
                icon: const Icon(Icons.date_range_rounded, size: 16),
                label: Text(
                    _endDate == null
                        ? 'End Date'
                        : _endDate!.toIso8601String().substring(0, 10),
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textPri(context))),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _monthFilter.isNotEmpty
                        ? DateTime.parse('$_monthFilter-01')
                        : DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDatePickerMode: DatePickerMode.year,
                    helpText: 'Select MONTH',
                    cancelText: 'Cancel',
                    confirmText: 'OK',
                  );
                  if (picked != null) setState(() {
                    _monthFilter =
                        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}';
                    _startDate = null;
                    _endDate = null;
                  });
                },
                icon: const Icon(Icons.calendar_month_rounded, size: 16),
                label: Text(
                    _monthFilter.isEmpty
                        ? 'Month (filter by month)'
                        : _monthFilter,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textPri(context))),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            if (_startDate != null ||
                _endDate != null ||
                _monthFilter.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                    _monthFilter = '';
                  });
                },
              ),
          ]),
        ),
        // Count
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text('${filtered.length} certificates (${list.length} total)',
              style:
                  TextStyle(fontSize: 12, color: AppColors.textHi(context))),
        ),
        // List
        Expanded(
          child: p.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : p.error != null
                  ? Center(child: Text(p.error!))
                  : filtered.isEmpty
                      ? Center(
                          child: Text('No certificates found',
                              style:
                                  TextStyle(color: AppColors.textHi(context))))
                      : RefreshIndicator(
                          onRefresh: () => p.fetch(),
                          color: AppColors.accent,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final c = filtered[i];
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
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(
                                          child: Text(c.studentName,
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      AppColors.textPri(context))),
                                        ),
                                        StatusBadge(status: c.status),
                                      ]),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${c.type} | ${c.courseOrInternshipName}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textHi(context))),
                                      if (c.collegeName.isNotEmpty)
                                        Text(c.collegeName,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    AppColors.textSec(context))),
                                      if (c.fileUrl != null &&
                                          c.fileUrl!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Row(children: [
                                            const Icon(Icons.link_rounded,
                                                size: 14,
                                                color: AppColors.accent),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                c.fileUrl!,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.accent,
                                                    decoration: TextDecoration
                                                        .underline),
                                              ),
                                            ),
                                          ]),
                                        ),
                                    ]),
                              );
                            },
                          ),
                        ),
        ),
      ]),
    );
  }
}

Widget _FChip(BuildContext context, String label, String value, String current, void Function(String) onTap) {
  final selected = current == value;
  return Padding(
    padding: const EdgeInsets.only(right: 6),
    child: GestureDetector(
      onTap: () => onTap(selected ? '' : value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSec(context))),
      ),
    ),
  );
}
