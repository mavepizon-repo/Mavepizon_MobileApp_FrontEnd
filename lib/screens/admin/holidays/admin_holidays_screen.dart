import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/pagination_data.dart';
import '../../../services/admin_holiday_service.dart';
import '../../../services/admin_staff_service.dart';
import '../../../services/admin_team_lead_service.dart';
import '../../../models/staff_model.dart';
import '../../../models/team_lead_model.dart';

class AdminHolidaysScreen extends StatefulWidget {
  const AdminHolidaysScreen({super.key});
  @override
  State<AdminHolidaysScreen> createState() => _AdminHolidaysScreenState();
}

class _AdminHolidaysScreenState extends State<AdminHolidaysScreen> {
  DateTime? _holidayDate;
  DateTime? _saturdayDate;
  DateTime? _tlHolidayDate;
  DateTime? _staffHolidayDate;

  List<TeamLeadModel> _teamLeads = [];
  List<StaffModel> _staffs = [];
  TeamLeadModel? _selectedTeamLead;
  StaffModel? _selectedStaff;

  bool _loading = false;
  bool _loadingLists = false;

  Future<DateTime?> _pickDate() async {
    return showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
  }

  Future<void> _pickHolidayDate() async {
    final picked = await _pickDate();
    if (picked != null) setState(() => _holidayDate = picked);
  }

  Future<void> _pickSaturdayDate() async {
    final picked = await _pickDate();
    if (picked != null) setState(() => _saturdayDate = picked);
  }

  Future<void> _pickTlHolidayDate() async {
    final picked = await _pickDate();
    if (picked != null) setState(() => _tlHolidayDate = picked);
  }

  Future<void> _pickStaffHolidayDate() async {
    final picked = await _pickDate();
    if (picked != null) setState(() => _staffHolidayDate = picked);
  }

  Future<void> _loadLists() async {
    setState(() => _loadingLists = true);
    try {
      final tlResult = await AdminTeamLeadService.getAll(size: 500);
      if (tlResult['success'] == true) {
        _teamLeads = PaginationData.parse(tlResult['data'])
            .content
            .map((e) => TeamLeadModel.fromJson(e))
            .where((t) => t.status == 'ACTIVE')
            .toList();
      }
      final staffResult = await AdminStaffService.getAll(size: 500);
      if (staffResult['success'] == true) {
        _staffs = PaginationData.parse(staffResult['data'])
            .content
            .map((e) => StaffModel.fromJson(e))
            .where((s) => s.status == 'ACTIVE')
            .toList();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingLists = false);
    }
  }

  String _fmt(DateTime? d) =>
      d == null ? '' : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _markHoliday() async {
    if (_holidayDate == null) {
      _snack('Please select a date');
      return;
    }
    setState(() => _loading = true);
    final staff = await AdminHolidayService.markHoliday(_fmt(_holidayDate));
    final teamLeads = await AdminHolidayService.markTeamLeadHoliday(_fmt(_holidayDate));
    if (staff['success'] == true && teamLeads['success'] == true) {
      _snack('Holiday marked for staff & team leads');
    } else {
      final msg = teamLeads['message']?.toString() ??
          staff['message']?.toString() ??
          'Failed to mark holiday';
      _snack('Failed: $msg');
    }
    setState(() => _loading = false);
  }

  Future<void> _setSaturdayWorking() async {
    if (_saturdayDate == null) {
      _snack('Please select a Saturday date');
      return;
    }
    setState(() => _loading = true);
    final result = await AdminHolidayService.setSaturdayWorking(_fmt(_saturdayDate));
    _snack(result['success'] == true ? 'Saturday set as working day' : (result['message'] ?? 'Failed'));
    setState(() => _loading = false);
  }

  Future<void> _markTeamLeadHoliday() async {
    if (_selectedTeamLead == null) {
      _snack('Please select a Team Lead');
      return;
    }
    if (_tlHolidayDate == null) {
      _snack('Please select a date');
      return;
    }
    setState(() => _loading = true);
    final result = await AdminHolidayService.markTeamLeadHolidayById(
        _selectedTeamLead!.id, _fmt(_tlHolidayDate));
    _snack(result['success'] == true
        ? 'Holiday marked for ${_selectedTeamLead!.fullName}'
        : (result['message']?.toString() ?? 'Failed to mark holiday'));
    setState(() => _loading = false);
  }

  Future<void> _markStaffHoliday() async {
    if (_selectedStaff == null) {
      _snack('Please select a Staff');
      return;
    }
    if (_staffHolidayDate == null) {
      _snack('Please select a date');
      return;
    }
    setState(() => _loading = true);
    final result = await AdminHolidayService.markStaffHolidayById(
        _selectedStaff!.id, _fmt(_staffHolidayDate));
    _snack(result['success'] == true
        ? 'Holiday marked for ${_selectedStaff!.name}'
        : (result['message']?.toString() ?? 'Failed to mark holiday'));
    setState(() => _loading = false);
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Holidays'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Mark Holiday
        Container(
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
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mark Holiday',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPri(context))),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickHolidayDate(),
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text(
                          _holidayDate == null
                              ? 'Pick Date'
                              : _fmt(_holidayDate!),
                          style: TextStyle(
                              color: AppColors.textPri(context))),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _markHoliday,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Mark as Holiday',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
              ]),
        ),
        const SizedBox(height: 16),

        // Mark Holiday for a Team Lead (by ID)
        Container(
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
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mark Holiday for a Team Lead',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPri(context))),
                const SizedBox(height: 4),
                Text('Mark OD for a single team lead by name',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textHi(context))),
                const SizedBox(height: 12),
                _loadingLists
                    ? const SizedBox(
                        height: 50,
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2)))
                    : DropdownButtonFormField<TeamLeadModel>(
                        value: _selectedTeamLead,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Select Team Lead',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          prefixIcon: const Icon(Icons.badge_rounded),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                        items: _teamLeads
                            .map((t) => DropdownMenuItem<TeamLeadModel>(
                                  value: t,
                                  child: Text(
                                    t.fullName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedTeamLead = value),
                      ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTlHolidayDate(),
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text(
                          _tlHolidayDate == null
                              ? 'Pick Date'
                              : _fmt(_tlHolidayDate!),
                          style: TextStyle(
                              color: AppColors.textPri(context))),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _markTeamLeadHoliday,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Mark Team Lead Holiday',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
              ]),
        ),
        const SizedBox(height: 16),

        // Mark Holiday for a Staff (by ID)
        Container(
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
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mark Holiday for a Staff',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPri(context))),
                const SizedBox(height: 4),
                Text('Mark OD for a single office staff by name',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textHi(context))),
                const SizedBox(height: 12),
                _loadingLists
                    ? const SizedBox(
                        height: 50,
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2)))
                    : DropdownButtonFormField<StaffModel>(
                        value: _selectedStaff,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Select Staff',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          prefixIcon: const Icon(Icons.person_rounded),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                        items: _staffs
                            .map((s) => DropdownMenuItem<StaffModel>(
                                  value: s,
                                  child: Text(
                                    s.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedStaff = value),
                      ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickStaffHolidayDate(),
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text(
                          _staffHolidayDate == null
                              ? 'Pick Date'
                              : _fmt(_staffHolidayDate!),
                          style: TextStyle(
                              color: AppColors.textPri(context))),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _markStaffHoliday,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Mark Staff Holiday',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
              ]),
        ),
        const SizedBox(height: 16),

        // Saturday Working Day
        Container(
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
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saturday as Working Day',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPri(context))),
                const SizedBox(height: 4),
                Text(
                    'Select a Saturday to change it to a working day',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textHi(context))),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickSaturdayDate(),
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text(
                          _saturdayDate == null
                              ? 'Pick Saturday'
                              : _fmt(_saturdayDate!),
                          style: TextStyle(
                              color: AppColors.textPri(context))),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _setSaturdayWorking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Set as Working Day',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
              ]),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}
