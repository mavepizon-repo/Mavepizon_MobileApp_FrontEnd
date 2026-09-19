import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../services/telecaller_service.dart';
import '../../../services/call_manager.dart';
import '../../../services/telecalling_call_service.dart';

class StaffTelecallerEnquiryDetailScreen extends ConsumerStatefulWidget {
  final String? enquiryId;
  final String? mode;
  const StaffTelecallerEnquiryDetailScreen(
      {super.key, this.enquiryId, this.mode});

  @override
  ConsumerState<StaffTelecallerEnquiryDetailScreen> createState() =>
      _StaffTelecallerEnquiryDetailScreenState();
}

class _StaffTelecallerEnquiryDetailScreenState
    extends ConsumerState<StaffTelecallerEnquiryDetailScreen> {
  String _staffId = '';
  Map<String, dynamic>? _enquiry;
  bool _loading = true;
  bool _editing = false;

  final _nameCtrl = TextEditingController();
  final _collegeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _latestFollowupDateCtrl = TextEditingController();
  DateTime? _latestFollowupDate;
  String? _editStatus;
  bool _submitting = false;

  List<dynamic> _followupHistory = [];
  bool _followupsLoading = false;

  // ─── Telecalling: call lifecycle + history ─────────────────────
  StreamSubscription<CallEvent>? _callSub;
  CallPhase? _callPhase;
  bool _callInProgress = false;
  DateTime? _callStarted;
  DateTime? _callConnected;
  DateTime? _callEnded;

  bool get _isCreate => widget.mode == 'create';

  @override
  void initState() {
    super.initState();
    _callSub = CallManager.instance.events.listen(_onCallEvent);
    _init();
  }

  Future<void> _init() async {
    _staffId = await StorageHelper.getStaffId() ?? '';
    TelecallingCallService.enableAutoLogging(_staffId);
    if (mounted) {
      if (!_isCreate && _staffId.isNotEmpty && widget.enquiryId != null) {
        await _load();
      } else {
        setState(() {
          _loading = false;
          _editing = true;
        });
      }
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await TelecallerService.getEnquiryById(
          _staffId, widget.enquiryId!);
      if (result['success'] == true) {
        final data = result['data'];
        if (data is Map) {
          _enquiry = Map<String, dynamic>.from(data);
          _nameCtrl.text = _enquiry?['studentName']?.toString() ?? '';
          _collegeCtrl.text = _enquiry?['collegeName']?.toString() ?? '';
          _phoneCtrl.text = _enquiry?['phone']?.toString() ?? '';
          _emailCtrl.text = _enquiry?['email']?.toString() ?? '';
          _departmentCtrl.text = _enquiry?['department']?.toString() ?? '';
          _cityCtrl.text = _enquiry?['city']?.toString() ?? '';
          _addressCtrl.text = _enquiry?['address']?.toString() ?? '';
          _districtCtrl.text = _enquiry?['district']?.toString() ?? '';
          _courseCtrl.text = _enquiry?['interestedCourse']?.toString() ?? '';
          _remarksCtrl.text = _enquiry?['remarks']?.toString() ?? '';
          final fDate = _enquiry?['nextFollowupDate']?.toString() ?? '';
          if (fDate.length >= 10) {
            _latestFollowupDate = DateTime.tryParse(fDate.substring(0, 10));
          }
          _latestFollowupDateCtrl.text = _latestFollowupDate != null
              ? '${_latestFollowupDate!.year}-${_latestFollowupDate!.month.toString().padLeft(2, '0')}-${_latestFollowupDate!.day.toString().padLeft(2, '0')}'
              : '';
          _editStatus = _enquiry?['status']?.toString() ?? '';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load enquiry: $e')));
      }
    }
    if (mounted) {
      setState(() => _loading = false);
      if (!_isCreate && widget.enquiryId != null) _loadFollowupHistory();
    }
  }

  Future<void> _loadFollowupHistory() async {
    if (!mounted) return;
    setState(() => _followupsLoading = true);
    try {
      final result = await TelecallerService.getFollowupHistory(
          _staffId, widget.enquiryId!);
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          _followupHistory = data;
        } else {
          _followupHistory = [];
        }
      } else {
        _followupHistory = [];
      }
    } catch (e) {
      debugPrint('Failed to load followup history: $e');
      _followupHistory = [];
    }
    if (mounted) setState(() => _followupsLoading = false);
  }

  // ─── Telecalling: call lifecycle ─────────────────────────────

  void _onCallEvent(CallEvent e) {
    if (!mounted) return;
    setState(() {
      _callPhase = e.phase;
      if (e.startedAt != null) _callStarted = e.startedAt;
      if (e.connectedAt != null) _callConnected = e.connectedAt;
      if (e.endAt != null) _callEnded = e.endAt;
      _callInProgress = e.phase != CallPhase.ended;
    });
    if (e.phase == CallPhase.ended) _handleCallEnded();
  }

  Future<void> _handleCallEnded() async {
    final duration = _callStarted == null
        ? 0
        : (_callEnded ?? DateTime.now())
            .difference(_callStarted!)
            .inSeconds;
    final status = _callConnected != null ? 'COMPLETED' : 'NO_ANSWER';
    final safeDuration = duration < 0 ? 0 : duration;

    if (mounted) {
      // The record is persisted (locally + best-effort backend) by the
      // TelecallingCallService auto logger. It is only displayed on the
      // admin Telecalling Calls page, not here.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Call ended · ${status == 'COMPLETED' ? 'Answered' : 'Not answered'} · ${_fmtDuration(safeDuration)}'),
        backgroundColor: AppColors.info,
      ));
    }
  }

  Future<void> _placeCall() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No phone number on this enquiry'),
          backgroundColor: AppColors.error));
      return;
    }
    final manager = CallManager.instance;
    final perms = await manager.getPermissions();
    if (perms['callPhone'] != true || perms['readPhoneState'] != true) {
      final granted = await manager.requestPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Phone permissions are required. Enable them in Settings -> Apps -> Mavepizon -> Permissions.'),
              backgroundColor: AppColors.error));
        }
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _callStarted = DateTime.now();
      _callConnected = null;
      _callEnded = null;
      _callPhase = CallPhase.ringing;
      _callInProgress = true;
    });
    final result = await manager.placeCall(phone, enquiryId: widget.enquiryId);
    if (!result.started && mounted) {
      setState(() {
        _callInProgress = false;
        _callPhase = CallPhase.ended;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.reason == 'permission_required'
              ? 'Permissions not granted'
              : 'Could not start the call'),
          backgroundColor: AppColors.error));
    }
  }

  String _callStatusNow() {
    switch (_callPhase) {
      case CallPhase.started:
        return 'Call started…';
      case CallPhase.ringing:
        return 'Ringing / Dialing…';
      case CallPhase.connected:
        return 'Connected / Active…';
      default:
        return '';
    }
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

  Widget _buildCallCard() {
    final phone = _phoneCtrl.text.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: [
        if (_callInProgress) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.info),
                  ),
                  const SizedBox(width: 10),
                  Text(_callStatusNow(),
                      style: const TextStyle(
                          color: AppColors.info,
                          fontWeight: FontWeight.w700)),
                ]),
          ),
          const SizedBox(height: 12),
        ],
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.call_rounded,
                color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Call this enquiry',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPri(context))),
                  if (phone.isNotEmpty)
                    Text(phone,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSec(context))),
                ]),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _placeCall,
            icon: const Icon(Icons.call_rounded,
                size: 18, color: Colors.white),
            label: const Text('Call',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ]),
      ]),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Student name is required'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _submitting = true);
    // Payload mirrors the backend DTOs exactly:
    //  - Create  -> TelecallingEnquiryRequest (includes address, district, latestFollowupDate)
    //  - Edit    -> TelecallingUpdateRequest  (no address/district; uses followupDate + status)
    final Map<String, dynamic> data = {
      'studentName': _nameCtrl.text.trim(),
      'collegeName': _collegeCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'department': _departmentCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'interestedCourse': _courseCtrl.text.trim(),
      'remarks': _remarksCtrl.text.trim(),
    };
    if (_isCreate) {
      data['address'] = _addressCtrl.text.trim();
      data['district'] = _districtCtrl.text.trim();
    }
    if (_latestFollowupDate != null) {
      final dateStr =
          '${_latestFollowupDate!.year}-${_latestFollowupDate!.month.toString().padLeft(2, '0')}-${_latestFollowupDate!.day.toString().padLeft(2, '0')}';
      // Create uses TelecallingEnquiryRequest.latestFollowupDate; update uses
      // TelecallingUpdateRequest.followupDate.
      data[_isCreate ? 'latestFollowupDate' : 'followupDate'] = dateStr;
    }
    if (!_isCreate && _editStatus != null && _editStatus!.trim().isNotEmpty) {
      data['status'] = _editStatus!;
    }

    final Map<String, dynamic> result;
    if (_isCreate) {
      result =
          await TelecallerService.createEnquiry(_staffId, data);
    } else {
      result = await TelecallerService.updateEnquiry(
          _staffId, widget.enquiryId!, data);
    }
    setState(() => _submitting = false);

    if (mounted) {
      final success = result['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? (_isCreate ? 'Enquiry created' : 'Enquiry updated')
              : result['message']?.toString() ?? 'Save failed'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      if (success) {
        setState(() => _editing = false);
        if (_isCreate) Navigator.pop(context);
      }
    }
  }

  Future<void> _pickLatestFollowupDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _latestFollowupDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) {
      setState(() {
        _latestFollowupDate = d;
        _latestFollowupDateCtrl.text =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Enquiry'),
        content: const Text('Delete this enquiry permanently?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm != true || widget.enquiryId == null) return;

    setState(() => _submitting = true);
    final result =
        await TelecallerService.deleteEnquiry(_staffId, widget.enquiryId!);
    setState(() => _submitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] == true
              ? 'Enquiry deleted'
              : 'Delete failed'),
          backgroundColor: result['success'] == true
              ? AppColors.success
              : AppColors.error,
        ),
      );
      if (result['success'] == true) Navigator.pop(context);
    }
  }

  Future<void> _convertEnquiry() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Convert to Student'),
        content: const Text(
            'Set this enquiry status to JOINED and convert to student?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Convert',
                style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );
    if (confirm != true || widget.enquiryId == null) return;

    setState(() => _submitting = true);
    final response = await TelecallerService.updateEnquiryStatus(
        _staffId, widget.enquiryId!, 'JOINED');
    setState(() => _submitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['success'] == true
              ? 'Enquiry converted to student'
              : 'Convert failed'),
          backgroundColor: response['success'] == true
              ? AppColors.success
              : AppColors.error,
        ),
      );
      if (response['success'] == true) _load();
    }
  }

  Future<void> _addFollowup() async {
    final dateCtrl = TextEditingController();
    DateTime? nextFollowupDate;
    String? selectedStatus;
    final remarksCtrl = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Followup'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) {
                      setDialogState(() {
                        nextFollowupDate = d;
                        dateCtrl.text =
                            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: dateCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Next Followup Date',
                        border: OutlineInputBorder(),
                        hintText: 'Select date',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: ['NEW', 'FOLLOWUP', 'INTERESTED', 'JOINED', 'NOT_INTERESTED']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedStatus = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: remarksCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Remarks',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, {
                'nextFollowupDate': nextFollowupDate != null
                    ? '${nextFollowupDate!.year}-${nextFollowupDate!.month.toString().padLeft(2, '0')}-${nextFollowupDate!.day.toString().padLeft(2, '0')}'
                    : null,
                'status': selectedStatus,
                'remarks': remarksCtrl.text.trim(),
              }),
              child: const Text('Save',
                  style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      ),
    );

    if (result != null && widget.enquiryId != null) {
      final selectedStatus = result['status']?.toString();
      if (selectedStatus == null || selectedStatus.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select a status (Interest / Not Interested)'),
            backgroundColor: AppColors.error,
          ));
        }
        return;
      }

      final staffId = await StorageHelper.getStaffId() ?? _staffId;
      final staffEmail = await StorageHelper.getUserEmail() ?? '';

      final body = <String, dynamic>{
        'status': selectedStatus,
        'remarks': (result['remarks'] as String?)?.trim() ?? '',
      };
      if (result['nextFollowupDate'] != null) {
        body['nextFollowupDate'] = result['nextFollowupDate'];
      }
      if (staffId.isNotEmpty) body['staffId'] = staffId;
      if (staffEmail.isNotEmpty) body['staffEmail'] = staffEmail;

      Map<String, dynamic> response = await TelecallerService.addFollowup(
          staffId, widget.enquiryId!, body);

      final failed = response['success'] != true;
      final errorMsg = response['message']?.toString() ?? '';
      if (failed &&
          (errorMsg.toLowerCase().contains('not found') ||
              errorMsg.toLowerCase().contains('anomaly'))) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        response =
            await TelecallerService.addFollowup(staffId, widget.enquiryId!, body);
      }

      if (mounted) {
        final ok = response['success'] == true;
        String message;
        if (ok) {
          message = 'Followup added';
        } else {
          final msg = response['message']?.toString() ?? '';
          message = msg.toLowerCase().contains('staff member not found')
              ? 'Followup save failed - session issue. Please logout and login again.'
              : msg.isNotEmpty
                  ? msg
                  : 'Failed to add followup';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: ok ? AppColors.success : AppColors.error,
          ),
        );
        if (ok) {
          _load();
          _loadFollowupHistory();
        }
      }
    }

    dateCtrl.dispose();
    remarksCtrl.dispose();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _collegeCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _departmentCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _districtCtrl.dispose();
    _courseCtrl.dispose();
    _remarksCtrl.dispose();
    _latestFollowupDateCtrl.dispose();
    _callSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
            _isCreate
                ? 'New Enquiry'
                : _editing
                    ? 'Edit Enquiry'
                    : 'Enquiry Detail',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPri(context)),
        actions: [
          if (!_isCreate && !_editing) ...[
            IconButton(
              icon: const Icon(Icons.edit_rounded,
                  color: AppColors.accent),
              onPressed: () => setState(() => _editing = true),
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded,
                  color: AppColors.error),
              onPressed: _submitting ? null : _delete,
            ),
          ],
          if (_editing)
            TextButton(
              onPressed: _submitting ? null : _save,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2))
                  : const Text('Save',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent)),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.accent, strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color:
                                Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _Field(
                        label: 'Student Name',
                        controller: _nameCtrl,
                        enabled: _editing),
                    const SizedBox(height: 14),
                    _Field(
                        label: 'Phone',
                        controller: _phoneCtrl,
                        enabled: _editing,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ]),
                    const SizedBox(height: 14),
                    _Field(
                        label: 'Email',
                        controller: _emailCtrl,
                        enabled: _editing,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 14),
                    _Field(
                        label: 'College Name',
                        controller: _collegeCtrl,
                        enabled: _editing),
                    const SizedBox(height: 14),
                    _Field(
                        label: 'Department',
                        controller: _departmentCtrl,
                        enabled: _editing),
                    const SizedBox(height: 14),
                    _Field(
                        label: 'City',
                        controller: _cityCtrl,
                        enabled: _editing),
                    const SizedBox(height: 14),
                    _Field(
                        label: 'Address',
                        controller: _addressCtrl,
                        enabled: _editing,
                        maxLines: 2),
                    const SizedBox(height: 14),
                    _Field(
                        label: 'District',
                        controller: _districtCtrl,
                        enabled: _editing),
                    const SizedBox(height: 14),
                    _Field(
                        label: 'Interested Course',
                        controller: _courseCtrl,
                        enabled: _editing),
                    const SizedBox(height: 14),
                    _Field(
                        label: 'Latest Follow-up Date',
                        controller: _latestFollowupDateCtrl,
                        enabled: true,
                        readOnly: true,
                        datePicker: true,
                        onTap: _pickLatestFollowupDate),
                    const SizedBox(height: 14),
                    _Field(
                        label: 'Remarks',
                        controller: _remarksCtrl,
                        enabled: _editing,
                        maxLines: 4),
                    if (!_isCreate && _editing) ...[
                      const SizedBox(height: 16),
                      Text('Status',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPri(context))),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _editStatus,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: ['NEW', 'FOLLOWUP', 'INTERESTED', 'JOINED', 'NOT_INTERESTED']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => _editStatus = v),
                      ),
                    ],
                    if (!_isCreate && !_editing && _enquiry != null) ...[
                      const SizedBox(height: 16),
                      _ReadOnlyRow(
                          label: 'Status',
                          value: _enquiry!['status']?.toString() ?? ''),
                      const SizedBox(height: 8),
                      _ReadOnlyRow(
                          label: 'Enquiry Date',
                          value: _enquiry!['enquiryDate']?.toString() ?? ''),
                      const SizedBox(height: 8),
                      _ReadOnlyRow(
                          label: 'Created',
                          value: _enquiry!['createdAt']?.toString() ?? ''),
                      if (_enquiry!['student'] != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.card1.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Linked Student',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPri(context))),
                                const SizedBox(height: 8),
                                _ReadOnlyRow(
                                    label: 'ID',
                                    value: _enquiry!['student']['id']
                                            ?.toString() ??
                                        ''),
                                if (_enquiry!['student']['studentName'] !=
                                    null) ...[
                                  const SizedBox(height: 6),
                                  _ReadOnlyRow(
                                      label: 'Name',
                                      value: _enquiry!['student']
                                              ['studentName']
                                          ?.toString() ?? ''),
                                ],
                                if (_enquiry!['student']['email'] != null) ...[
                                  const SizedBox(height: 6),
                                  _ReadOnlyRow(
                                      label: 'Email',
                                      value: _enquiry!['student']['email']
                                          ?.toString() ?? ''),
                                ],
                              ]),
                        ),
                      ],
                    ],
                  ]),
                ),
                if (!_isCreate && !_editing) ...[
                  const SizedBox(height: 16),
                  _buildCallCard(),
                  const SizedBox(height: 16),
                  if (_enquiry != null &&
                      _enquiry!['status']?.toString().toUpperCase() !=
                          'JOINED' &&
                      _enquiry!['status']?.toString().toUpperCase() !=
                          'NOT_INTERESTED') ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _convertEnquiry,
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: const Text('Convert to Student',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _addFollowup,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Followup',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Followup History',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPri(context))),
                        if (_followupsLoading)
                          const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2)),
                      ]),
                  const SizedBox(height: 12),
                  if (_followupHistory.isEmpty && !_followupsLoading)
                    Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16)),
                        child: Center(
                            child: Text('No followups yet',
                                style: TextStyle(
                                    color: AppColors.textHi(context)))))
                  else
                    ..._followupHistory.map((fh) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
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
                                  if (fh['nextFollowupDate'] != null)
                                    Text(
                                        'Next: ${fh['nextFollowupDate']}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.accent)),
                                  const Spacer(),
                                  if (fh['status'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.card3.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                          fh['status'].toString().toUpperCase(),
                                          style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.card3)),
                                    ),
                                ]),
                                if (fh['remarks']?.toString().isNotEmpty == true) ...[
                                  const SizedBox(height: 8),
                                  Text(fh['remarks'].toString(),
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSec(context))),
                                ],
                                if (fh['updatedBy']?.toString().isNotEmpty == true) ...[
                                  const SizedBox(height: 6),
                                  Text('By: ${fh['updatedBy']}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textHi(context))),
                                ],
                              ]),
                        )),
                ],
                if (!_isCreate && _editing) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => setState(() => _editing = false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSec(context),
                        side: BorderSide(color: AppColors.borderC(context)),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16)),
                      ),
                      child: const Text('Cancel Editing',
                          style: TextStyle(
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ]),
            ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool datePicker;

  const _Field({
    required this.label,
    required this.controller,
    required this.enabled,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.onTap,
    this.readOnly = false,
    this.datePicker = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPri(context))),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          filled: true,
          fillColor:
              enabled ? Theme.of(context).colorScheme.surface : AppColors.dividerC(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: enabled
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.accent, width: 1.5),
                )
              : null,
          suffixIcon: datePicker
              ? Icon(Icons.calendar_today_rounded,
                  size: 18, color: AppColors.textHi(context))
              : null,
        ),
      ),
    ]);
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text('$label: ',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSec(context))),
      Text(value,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPri(context))),
    ]);
  }
}
