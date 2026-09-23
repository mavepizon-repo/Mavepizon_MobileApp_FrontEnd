import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/pagination_data.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../services/telecaller_service.dart';
import '../../../services/telecalling_call_service.dart';
import '../../../widgets/call_button.dart';
import '../../../widgets/pagination_bar.dart';

class StaffTelecallerFollowupsScreen extends ConsumerStatefulWidget {
  const StaffTelecallerFollowupsScreen({super.key});

  @override
  ConsumerState<StaffTelecallerFollowupsScreen> createState() =>
      _StaffTelecallerFollowupsScreenState();
}

class _StaffTelecallerFollowupsScreenState
    extends ConsumerState<StaffTelecallerFollowupsScreen> {
  String _staffId = '';
  List<dynamic> _followups = [];
  PaginationData _paged = const PaginationData();
  bool _loading = true;
  int _tabIndex = 0;

  String? _selectedStatus;
  DateTime? _selectedDate;
  String? _updatedByFilter;
  bool _hasActiveFilter = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _staffId = await StorageHelper.getStaffId() ?? '';
    TelecallingCallService.enableAutoLogging(_staffId);
    if (mounted && _staffId.isNotEmpty) await _load();
  }

  List<dynamic> get _filtered {
    return _followups.where((f) {
      if (_selectedStatus != null) {
        final status = (f['status']?.toString() ?? '').toUpperCase();
        if (status != _selectedStatus) return false;
      }
      if (_selectedDate != null) {
        final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
        final raw = f['followupDate']?.toString() ?? '';
        final followupDate =
            raw.length >= 10 ? raw.substring(0, 10) : '';
        final nextRaw = f['nextFollowupDate']?.toString() ?? '';
        final nextDate =
            nextRaw.length >= 10 ? nextRaw.substring(0, 10) : '';
        if (followupDate != dateStr && nextDate != dateStr) return false;
      }
      if (_updatedByFilter?.isNotEmpty == true) {
        final by = (f['updatedBy']?.toString() ?? '').toLowerCase();
        if (!by.contains(_updatedByFilter!.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  void _applyFilters() {
    _hasActiveFilter = _selectedStatus != null ||
        _selectedDate != null ||
        (_updatedByFilter?.isNotEmpty == true);
    setState(() {});
  }

  void _resetFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedDate = null;
      _updatedByFilter = null;
      _hasActiveFilter = false;
    });
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

  Future<void> _load({int page = 0}) async {
    setState(() => _loading = true);
    try {
      final result = _tabIndex == 0
          ? await TelecallerService.getTodayFollowups(_staffId)
          : await TelecallerService.getCustomFollowups(_staffId,
              page: page);
      if (result['success'] == true) {
        final data = result['data'];
        if (_tabIndex == 0) {
          _paged = const PaginationData();
          if (data is List) _followups = data;
          else _followups = [];
        } else {
          final paged = PaginationData.parse(data);
          _paged = paged;
          _followups = paged.content;
        }
      } else {
        _followups = [];
      }
    } catch (_) {
      _followups = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildContent() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        color: Theme.of(context).colorScheme.surface,
        child: Column(children: [
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24)),
                    ),
                    builder: (ctx) => StatefulBuilder(
                      builder: (ctx, setDialogState) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Filter by Status',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPri(context))),
                              const SizedBox(height: 16),
                              ...['NEW', 'FOLLOWUP', 'INTERESTED',
                                      'JOINED', 'NOT_INTERESTED']
                                  .map((s) => ListTile(
                                        title: Text(s),
                                        leading: Radio<String>(
                                          value: s,
                                          groupValue: _selectedStatus,
                                          onChanged: (v) {
                                            Navigator.pop(ctx);
                                            setState(() =>
                                                _selectedStatus = v);
                                          },
                                        ),
                                      ))
                            ]),
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    Icon(Icons.filter_alt_rounded,
                        size: 14, color: AppColors.textHi(context)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _selectedStatus ?? 'Status',
                        style: TextStyle(
                          fontSize: 13,
                          color: _selectedStatus != null
                              ? AppColors.textPri(context)
                              : AppColors.textHi(context),
                        ),
                      ),
                    ),
                    if (_selectedStatus != null)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _selectedStatus = null),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: AppColors.textHi(context)),
                      ),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: _pickDate,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 14, color: AppColors.textHi(context)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _selectedDate != null
                            ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                            : 'Date',
                        style: TextStyle(
                          fontSize: 13,
                          color: _selectedDate != null
                              ? AppColors.textPri(context)
                              : AppColors.textHi(context),
                        ),
                      ),
                    ),
                    if (_selectedDate != null)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _selectedDate = null),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: AppColors.textHi(context)),
                      ),
                  ]),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Apply Filters',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
      Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          _Tab('Today', 0),
          _Tab('Custom', 1),
        ]),
      ),
      if (_loading)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
              child: CircularProgressIndicator(
                  color: AppColors.accent, strokeWidth: 2)),
        )
      else if (_filtered.isEmpty)
        Padding(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.1),
          child: Column(children: [
            Icon(Icons.repeat_rounded,
                size: 60,
                color: AppColors.textHi(context).withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
                _hasActiveFilter
                    ? 'No followups match filters'
                    : _tabIndex == 0
                        ? 'No followups today'
                        : 'No custom followups',
                style: TextStyle(color: AppColors.textHi(context))),
          ]),
        )
      else
        ..._filtered.map((f) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _FollowupCard(f: f),
            )),
      if (_tabIndex == 1 && _paged.totalElements > 0)
        PaginationBar(
          data: _paged,
          isLoading: _loading,
          onPageChanged: (page) => _load(page: page),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Follow Ups',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPri(context)),
        actions: [
          if (_hasActiveFilter)
            IconButton(
              icon: const Icon(Icons.clear_all_rounded,
                  color: AppColors.error),
              onPressed: _resetFilters,
            ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _load(),
            color: AppColors.accent,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _Tab(String label, int index) {
    final selected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _tabIndex = index;
          _load();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : AppColors.textSec(context))),
        ),
      ),
    );
  }
}

class _FollowupCard extends StatelessWidget {
  final dynamic f;
  const _FollowupCard({required this.f});

  // The "Today" tab is fed by the backend's `/today-followups`, which returns
  // ENQUIRIES scheduled for follow-up today (they carry `studentName`). The
  // "Custom" tab is fed by `/custom-followups`, which returns actual followup
  // records (no top-level `studentName`, but a `followupDate`). Detect which
  // shape we received and render accordingly.
  bool get _isEnquiry => f['studentName']?.toString().isNotEmpty == true;

  @override
  Widget build(BuildContext context) {
    if (_isEnquiry) return _EnquiryDueCard(f: f);
    return _FollowupRecordCard(f: f);
  }
}

class _EnquiryDueCard extends StatelessWidget {
  final dynamic f;
  const _EnquiryDueCard({required this.f});

  @override
  Widget build(BuildContext context) {
    final name = f['studentName']?.toString() ?? 'Unknown';
    final college = f['collegeName']?.toString() ?? '';
    final phone = f['phone']?.toString() ?? '';
    final nextDate = f['nextFollowupDate']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.card6.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                    child: Text(
                        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                        style: const TextStyle(
                            color: AppColors.card6,
                            fontWeight: FontWeight.w700,
                            fontSize: 16))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPri(context))),
                      if (college.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(college,
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSec(context))),
                      ],
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(phone,
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSec(context))),
                      ],
                    ]),
              ),
              // Telecalling: direct call to the follow-up enquiry
              CallButton(phone: phone, enquiryId: f['id']?.toString()),
            ]),
            if (nextDate.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Follow-up due: $nextDate',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent)),
            ],
          ]),
    );
  }
}

class _FollowupRecordCard extends StatelessWidget {
  final dynamic f;
  const _FollowupRecordCard({required this.f});

  @override
  Widget build(BuildContext context) {
    final status = f['status']?.toString().toUpperCase() ?? '';
    final followupDate = f['followupDate']?.toString() ?? '';
    final nextDate = f['nextFollowupDate']?.toString() ?? '';
    final remarks = f['remarks']?.toString() ?? '';
    final updatedBy = f['updatedBy']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                    child: Icon(Icons.repeat_rounded,
                        color: AppColors.accent, size: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (followupDate.isNotEmpty)
                        Text('Followup: $followupDate',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPri(context))),
                      if (nextDate.isNotEmpty)
                        Text('Next: $nextDate',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.accent)),
                    ]),
              ),
              if (status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: status == 'NEW'
                        ? AppColors.accent.withOpacity(0.1)
                        : status == 'INTERESTED'
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.textHi(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: status == 'NEW'
                              ? AppColors.accent
                              : status == 'INTERESTED'
                                  ? AppColors.success
                                  : AppColors.textHi(context))),
                ),
            ]),
            if (remarks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(remarks,
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSec(context))),
              ),
            ],
            if (updatedBy.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('By: $updatedBy',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textHi(context))),
            ],
          ]),
    );
  }
}
