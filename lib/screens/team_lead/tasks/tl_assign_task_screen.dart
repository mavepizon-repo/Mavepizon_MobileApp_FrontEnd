import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/staff_model.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/staff_provider.dart';
import '../../../services/tl_profile_service.dart';
import '../../../widgets/app_button.dart';

class TlAssignTaskScreen extends ConsumerStatefulWidget {
  final String? staffId;
  const TlAssignTaskScreen({super.key, this.staffId});
  @override
  ConsumerState<TlAssignTaskScreen> createState() => _TlAssignTaskScreenState();
}

class _TlAssignTaskScreenState extends ConsumerState<TlAssignTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();

  String? _staffId;
  bool _isGroupMode = false;
  final Set<String> _selectedStaffIds = {};
  String _priority = 'MEDIUM';
  String _taskType = 'DEVELOPMENT';
  DateTime? _startDate;
  DateTime? _dueDate;
  String _tlBranch = '';
  bool _branchLoaded = false;

  @override
  void initState() {
    super.initState();
    _staffId = widget.staffId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(staffProvider).list.isEmpty) {
        ref.read(staffProvider.notifier).fetch();
      }
      _loadTlBranch();
    });
  }

  Future<void> _loadTlBranch() async {
    try {
      final res = await TlProfileService.getProfile();
      if (res['success'] == true) {
        final d = res['data'] is Map
            ? res['data'] as Map<String, dynamic>
            : const <String, dynamic>{};
        final b = d['branch']?.toString().trim().toUpperCase() ?? '';
        if (mounted && b.isNotEmpty) {
          setState(() {
            _tlBranch = b;
            _branchLoaded = true;
          });
        }
      }
    } catch (_) {
      // Branch unavailable � fall back to showing all visible staff.
    } finally {
      if (mounted && !_branchLoaded) {
        setState(() => _branchLoaded = true);
      }
    }
  }

  List<StaffModel> get _visibleStaff {
    final list = ref.read(staffProvider).list;
    if (_tlBranch.isEmpty) return list;
    return list
        .where((s) => s.branch.toString().trim().toUpperCase() == _tlBranch)
        .toList();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _remarkCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.accent)),
          child: child!),
    );
    if (d != null) {
      setState(() {
        if (isStart) {
          _startDate = d;
        } else {
          _dueDate = d;
        }
      });
    }
  }

  String _fmtDate(DateTime? d) => d == null
      ? 'Select date'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      _snack('Please select a due date', AppColors.error);
      return;
    }

    final data = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'priority': _priority,
      'taskType': _taskType,
      'deadline': _dueDate!.toIso8601String().split('T')[0],
      'estimatedHours': int.tryParse(_hoursCtrl.text.trim()) ?? 0,
      'remarks': _remarkCtrl.text.trim(),
      if (_startDate != null)
        'assignedDate': _startDate!.toIso8601String().split('T')[0],
    };

    bool ok;
    if (_isGroupMode) {
      if (_selectedStaffIds.isEmpty) {
        _snack('Please select at least one staff member', AppColors.error);
        return;
      }
      final staffIds = _selectedStaffIds
          .map((id) => int.tryParse(id) ?? 0)
          .where((id) => id > 0)
          .toList();
      ok = await ref.read(taskProvider.notifier).assignGroup(data, staffIds);
    } else {
      if (_staffId == null) {
        _snack('Please select a staff member', AppColors.error);
        return;
      }
      data['staffId'] = _staffId!;
      ok = await ref.read(taskProvider.notifier).assign(data);
    }

    if (!mounted) return;
    if (ok) {
      _snack('Task assigned successfully!', AppColors.success);
      Navigator.pop(context);
    } else {
      _snack(ref.read(taskProvider).error ?? 'Failed', AppColors.error);
    }
  }

  void _snack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16)));

  @override
  Widget build(BuildContext context) {
    final taskProv = ref.watch(taskProvider);
    ref.watch(staffProvider);

    return Scaffold(
      
      body: Column(children: [
        Container(
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 8, 20, 20),
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
                  Text('Assign Task',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  Text('Assign a task to your staff',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                ]),
          ]),
        ),
        Expanded(
          child: ResponsiveCentered(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Task Title'),
                    const SizedBox(height: 8),
                    TextFormField(
                        controller: _titleCtrl,
                        decoration:
                            _deco('e.g. Build login UI', Icons.title_rounded),
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    _label('Description'),
                    const SizedBox(height: 8),
                    TextFormField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: _deco('Describe the task in detail...',
                            Icons.description_rounded),
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    Row(children: [
                      _label('Assign To'),
                      const Spacer(),
                      Row(children: [
                        Text('Single',
                            style: TextStyle(
                                fontSize: 12,
                                color: !_isGroupMode ? AppColors.accent : AppColors.textHi(context),
                                fontWeight: FontWeight.w600)),
                        Switch(
                          value: _isGroupMode,
                          onChanged: (v) => setState(() {
                            _isGroupMode = v;
                            _staffId = null;
                            _selectedStaffIds.clear();
                          }),
                          activeColor: AppColors.accent,
                        ),
                        Text('Group',
                            style: TextStyle(
                                fontSize: 12,
                                color: _isGroupMode ? AppColors.accent : AppColors.textHi(context),
                                fontWeight: FontWeight.w600)),
                      ]),
                    ]),
                    const SizedBox(height: 8),
                    if (!_isGroupMode)
                      Container(
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderC(context))),
                        child: DropdownButtonFormField<String>(
                          value: _staffId,
                          hint: Text('Select staff member',
                              style: TextStyle(
                                  color: AppColors.textHi(context), fontSize: 14)),
                          decoration: InputDecoration(
                              prefixIcon: Icon(Icons.person_rounded,
                                  color: AppColors.textHi(context), size: 20),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14)),
                          items: _visibleStaff
                              .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text('${s.name} � ${s.role}',
                                      style: const TextStyle(fontSize: 14))))
                              .toList(),
                          onChanged: (v) => setState(() => _staffId = v),
                        ),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderC(context))),
                        child: _visibleStaff.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  _tlBranch.isEmpty
                                      ? 'No staff members available'
                                      : 'No staff available in your $_tlBranch branch to assign',
                                  style: TextStyle(
                                      color: AppColors.textHi(context)),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _visibleStaff.length,
                                itemBuilder: (_, i) {
                                  final s = _visibleStaff[i];
                                  final selected = _selectedStaffIds.contains(s.id);
                                  return CheckboxListTile(
                                    value: selected,
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _selectedStaffIds.add(s.id);
                                        } else {
                                          _selectedStaffIds.remove(s.id);
                                        }
                                      });
                                    },
                                    title: Text('${s.name}',
                                        style: const TextStyle(fontSize: 14)),
                                    subtitle: Text(s.role,
                                        style: TextStyle(fontSize: 12, color: AppColors.textHi(context))),
                                    controlAffinity: ListTileControlAffinity.leading,
                                    activeColor: AppColors.accent,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  );
                                },
                              ),
                      ),
                    const SizedBox(height: 16),
                    _label('Task Type'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderC(context))),
                      child: DropdownButtonFormField<String>(
                        value: _taskType,
                        decoration: InputDecoration(
                            prefixIcon: Icon(Icons.category_rounded,
                                color: AppColors.textHi(context), size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14)),
                        items: ['DEVELOPMENT', 'TRAINING', 'DESIGN', 'TELECOM']
                            .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t,
                                    style: const TextStyle(fontSize: 14))))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _taskType = v ?? 'DEVELOPMENT'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label('Priority'),
                    const SizedBox(height: 8),
                    Row(
                        children: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'].map((p) {
                      final color = p == 'CRITICAL'
                          ? AppColors.error
                          : p == 'HIGH'
                              ? AppColors.warning
                              : p == 'MEDIUM'
                                  ? const Color(0xFFF59E0B)
                                  : AppColors.success;
                      final sel = _priority == p;
                      return Expanded(
                          child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: GestureDetector(
                          onTap: () => setState(() => _priority = p),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                                color: sel ? color : color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        sel ? color : color.withOpacity(0.3))),
                            child: Center(
                                child: Text(p,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: sel ? Colors.white : color))),
                          ),
                        ),
                      ));
                    }).toList()),
                    const SizedBox(height: 16),
                    _label('Due Date'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _pickDate(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 15),
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: _dueDate != null
                                    ? AppColors.accent
                                    : AppColors.borderC(context))),
                        child: Row(children: [
                          Icon(Icons.event_rounded,
                              size: 18,
                              color: _dueDate != null
                                  ? AppColors.accent
                                  : AppColors.textHi(context)),
                          const SizedBox(width: 8),
                          Text(_fmtDate(_dueDate),
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _dueDate != null
                                      ? AppColors.textPri(context)
                                      : AppColors.textHi(context))),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label('Estimated Hours'),
                    const SizedBox(height: 8),
                    TextFormField(
                        controller: _hoursCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _deco(
                            'e.g. 8', Icons.access_time_rounded),
                        validator: (v) {
                          if (v != null && v.isNotEmpty) {
                            final n = int.tryParse(v);
                            if (n == null || n <= 0) {
                              return 'Enter a valid number';
                            }
                          }
                          return null;
                        }),
                    const SizedBox(height: 16),
                    _label('Remarks (Optional)'),
                    const SizedBox(height: 8),
                    TextFormField(
                        controller: _remarkCtrl,
                        maxLines: 2,
                        decoration: _deco(
                            'Any additional notes...', Icons.note_rounded)),
                    const SizedBox(height: 28),
                    AppButton(
                        text: _isGroupMode
                            ? 'Assign to ${_selectedStaffIds.length} Staff'
                            : 'Assign Task',
                        onPressed: _submit,
                        isLoading: taskProv.isLoading,
                        icon: Icons.check_rounded),
                    const SizedBox(height: 24),
                  ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _label(String t) => Text(t,
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPri(context)));

  InputDecoration _deco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textHi(context), fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textHi(context), size: 20),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.borderC(context))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.borderC(context))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.accent, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error)),
      );
}
