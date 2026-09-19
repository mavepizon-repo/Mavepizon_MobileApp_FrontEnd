import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../services/telecaller_service.dart';
import '../../../services/telecalling_call_service.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/call_button.dart';

class StaffTelecallerEnquiriesScreen extends ConsumerStatefulWidget {
  const StaffTelecallerEnquiriesScreen({super.key});

  @override
  ConsumerState<StaffTelecallerEnquiriesScreen> createState() =>
      _StaffTelecallerEnquiriesScreenState();
}

class _StaffTelecallerEnquiriesScreenState
    extends ConsumerState<StaffTelecallerEnquiriesScreen> {
  String _staffId = '';
  List<dynamic> _enquiries = [];
  bool _loading = true;

  final _collegeCtrl = TextEditingController();
  final _studentCtrl = TextEditingController();
  String? _selectedStatus;
  DateTime? _selectedDate;
  DateTime? _selectedFollowupDate;
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

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await TelecallerService.getEnquiries(_staffId);
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) _enquiries = data;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load enquiries: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  List<dynamic> get _filtered {
    return _enquiries.where((e) {
      if (_collegeCtrl.text.trim().isNotEmpty) {
        final college = (e['collegeName']?.toString() ?? '').toLowerCase();
        if (!college.contains(_collegeCtrl.text.trim().toLowerCase())) return false;
      }
      if (_studentCtrl.text.trim().isNotEmpty) {
        final name = (e['studentName']?.toString() ?? '').toLowerCase();
        if (!name.contains(_studentCtrl.text.trim().toLowerCase())) return false;
      }
      if (_selectedStatus != null) {
        final status = (e['status']?.toString() ?? '').toUpperCase();
        if (status != _selectedStatus) return false;
      }
      if (_selectedDate != null) {
        final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
        final enquiryDate = (e['enquiryDate']?.toString() ?? '');
        if (enquiryDate.length >= 10) {
          if (enquiryDate.substring(0, 10) != dateStr) return false;
        } else {
          return false;
        }
      }
      if (_selectedFollowupDate != null) {
        final dateStr = '${_selectedFollowupDate!.year}-${_selectedFollowupDate!.month.toString().padLeft(2, '0')}-${_selectedFollowupDate!.day.toString().padLeft(2, '0')}';
        final nextDate = (e['nextFollowupDate']?.toString() ?? '');
        if (nextDate.length >= 10) {
          if (nextDate.substring(0, 10) != dateStr) return false;
        } else {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _applyFilters() {
    _hasActiveFilter = _collegeCtrl.text.trim().isNotEmpty ||
        _studentCtrl.text.trim().isNotEmpty ||
        _selectedStatus != null ||
        _selectedDate != null ||
        _selectedFollowupDate != null;
    setState(() {});
  }

  void _resetFilters() {
    _collegeCtrl.clear();
    _studentCtrl.clear();
    setState(() {
      _selectedStatus = null;
      _selectedDate = null;
      _selectedFollowupDate = null;
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

  Future<void> _pickFollowupDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedFollowupDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _selectedFollowupDate = d);
  }

  @override
  void dispose() {
    _collegeCtrl.dispose();
    _studentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Enquiries',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        actions: [
          if (_hasActiveFilter)
            IconButton(
              icon: const Icon(Icons.clear_all_rounded,
                  color: AppColors.error),
              onPressed: _resetFilters,
            ),
          IconButton(
            icon: const Icon(Icons.add_circle_rounded,
                color: AppColors.accent),
            onPressed: () async {
              await Navigator.pushNamed(
                  context, AppRoutes.telecallerEnquiryDetail,
                  arguments: {'mode': 'create'});
              _load();
            },
          ),
        ],
      ),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          color: Theme.of(context).colorScheme.surface,
          child: Column(children: [
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _collegeCtrl,
                    decoration: InputDecoration(
                      hintText: 'College name',
                      hintStyle: TextStyle(
                          color: AppColors.textHi(context), fontSize: 13),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.school_rounded,
                          size: 18, color: AppColors.textHi(context)),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _studentCtrl,
                    decoration: InputDecoration(
                      hintText: 'Student name',
                      hintStyle: TextStyle(
                          color: AppColors.textHi(context), fontSize: 13),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.person_rounded,
                          size: 16, color: AppColors.textHi(context)),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
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
                      builder: (ctx) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('Select Status',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color:
                                          AppColors.textPri(context))),
                              const SizedBox(height: 16),
                              ...['NEW', 'FOLLOWUP', 'INTERESTED',
                                      'JOINED', 'NOT_INTERESTED']
                                  .map((s) => ListTile(
                                        title: Text(s),
                                        leading: Radio<String>(
                                          value: s,
                                          groupValue:
                                              _selectedStatus,
                                          onChanged: (v) {
                                            Navigator.pop(ctx);
                                            setState(() =>
                                                _selectedStatus =
                                                    v);
                                          },
                                        ),
                                      ))
                            ]),
                      ),
                    );
                  },
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12),
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
                          onTap: () => setState(
                              () => _selectedStatus = null),
                          child: Icon(Icons.close_rounded,
                              size: 16,
                              color: AppColors.textHi(context)),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12),
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
                          onTap: () => setState(
                              () => _selectedDate = null),
                          child: Icon(Icons.close_rounded,
                              size: 16,
                              color: AppColors.textHi(context)),
                        ),
                    ]),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickFollowupDate,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(Icons.event_repeat_rounded,
                      size: 14, color: AppColors.textHi(context)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _selectedFollowupDate != null
                          ? 'Follow-up: ${_selectedFollowupDate!.year}-${_selectedFollowupDate!.month.toString().padLeft(2, '0')}-${_selectedFollowupDate!.day.toString().padLeft(2, '0')}'
                          : 'Follow-up date',
                      style: TextStyle(
                        fontSize: 13,
                        color: _selectedFollowupDate != null
                            ? AppColors.textPri(context)
                            : AppColors.textHi(context),
                      ),
                    ),
                  ),
                  if (_selectedFollowupDate != null)
                    GestureDetector(
                      onTap: () => setState(
                          () => _selectedFollowupDate = null),
                      child: Icon(Icons.close_rounded,
                          size: 16,
                          color: AppColors.textHi(context)),
                    ),
                ]),
              ),
            ),
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
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppColors.accent,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accent, strokeWidth: 2))
                : _filtered.isEmpty
                    ? ListView(children: [
                        SizedBox(
                          height:
                              MediaQuery.of(context).size.height *
                                  0.3,
                          child: Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                      Icons.contact_phone_rounded,
                                      size: 60,
                                      color: AppColors.textHi(context)
                                          .withOpacity(0.4)),
                                  const SizedBox(height: 16),
                                  Text(
                                    _hasActiveFilter
                                        ? 'No enquiries match filters'
                                        : 'No enquiries found',
                                    style: TextStyle(
                                        color:
                                            AppColors.textHi(context)),
                                  ),
                                ]),
                          ),
                        ),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) {
                          final e = _filtered[i];
                          return GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(
                                    context,
                                    AppRoutes
                                        .telecallerEnquiryDetail,
                                    arguments: {
                                  'enquiryId':
                                      e['id']?.toString() ??
                                          '',
                                }).then((_) => _load()),
                            child: Container(
                              margin: const EdgeInsets.only(
                                  bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.04),
                                        blurRadius: 8,
                                        offset:
                                            const Offset(0, 2))
                                  ]),
                              child: Row(children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.card6
                                        .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                      child: Text(
                                          e['studentName']
                                                  ?.toString()
                                                  .substring(
                                                      0, 1)
                                                  .toUpperCase() ??
                                              '?',
                                          style: const TextStyle(
                                              color:
                                                  AppColors.card6,
                                              fontWeight:
                                                  FontWeight.w700,
                                              fontSize: 16))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                            e['studentName']
                                                    ?.toString() ??
                                                'Unknown',
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: AppColors
                                                    .textPrimary)),
                                        const SizedBox(height: 2),
                                        Text(
                                            e['collegeName']
                                                    ?.toString() ??
                                                '',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors
                                                    .textSecondary)),
                                      ]),
                                ),
                                const SizedBox(width: 8),
                                // Telecalling: direct call to the enquiry
                                CallButton(
                                    phone: e['phone']?.toString() ?? '',
                                    enquiryId: e['id']?.toString()),
                              ]),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ]),
    );
  }
}
