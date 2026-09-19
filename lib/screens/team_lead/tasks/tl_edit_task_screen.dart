import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/staff_provider.dart';
import '../../../widgets/app_button.dart';

// ? FIX: Removed hardcoded 'status': 'IN_PROGRESS' in _submit().
// Old code forced every edit to reset task status to IN_PROGRESS.
// If a task was WAITING_FOR_REVIEW or COMPLETED, editing it would
// silently reset it � wrong behavior.
// Fix: Load current status from task in _loadTask() and preserve it on submit.

class TlEditTaskScreen extends ConsumerStatefulWidget {
  final String taskId;
  const TlEditTaskScreen({super.key, required this.taskId});

  @override
  ConsumerState<TlEditTaskScreen> createState() => _TlEditTaskScreenState();
}

class _TlEditTaskScreenState extends ConsumerState<TlEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();

  String _priority = 'MEDIUM';
  String _taskType = 'DEVELOPMENT';
  String _currentStatus = 'IN_PROGRESS';
  String? _staffId;
  DateTime? _startDate;
  DateTime? _deadline;
  bool _isLoading = false;
  bool _loaded = false;
  bool _fetchingTask = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTask());
  }

  Future<void> _loadTask() async {
    final prov = ref.read(taskProvider.notifier);

    var task = prov.getById(widget.taskId);

    if (task == null && !_fetchingTask) {
      _fetchingTask = true;
      await prov.fetch();
      if (!mounted) return;
      task = prov.getById(widget.taskId);
    }

    if (task == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Task not found'),
          backgroundColor: AppColors.error,
        ));
        Navigator.pop(context);
      }
      return;
    }

    _titleCtrl.text = task.title;
    _descCtrl.text = task.description;
    _remarkCtrl.text = task.remarks ?? '';
    _priority = task.priority;
    _taskType = task.taskType.isNotEmpty ? task.taskType : 'DEVELOPMENT';
    _hoursCtrl.text = task.estimatedHours > 0 ? task.estimatedHours.toString() : '';
    _staffId = task.staffId.isNotEmpty ? task.staffId : null;
    _startDate =
        task.startDate.isNotEmpty ? DateTime.tryParse(task.startDate) : null;
    _deadline =
        task.deadline.isNotEmpty ? DateTime.tryParse(task.deadline) : null;

    _currentStatus = task.status.isNotEmpty ? task.status : 'IN_PROGRESS';

    if (mounted) setState(() => _loaded = true);
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
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    if (d != null) {
      setState(() {
        if (isStart) {
          _startDate = d;
        } else {
          _deadline = d;
        }
      });
    }
  }

  String _fmtDate(DateTime? d) => d == null
      ? 'Select date'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _dateOnly(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null) {
      _snack('Select due date', AppColors.error);
      return;
    }

    final data = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'priority': _priority,
      'taskType': _taskType,
      'deadline': _dateOnly(_deadline!),
      'remarks': _remarkCtrl.text.trim(),
      'status': _currentStatus,
    };
    final hours = int.tryParse(_hoursCtrl.text.trim());
    if (hours != null && hours > 0) data['estimatedHours'] = hours;

    setState(() => _isLoading = true);
    final ok = await ref.read(taskProvider.notifier).update(widget.taskId, data);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      _snack('Task updated!', AppColors.success);
      Navigator.pop(context);
    } else {
      _snack(ref.read(taskProvider).error ?? 'Update failed',
          AppColors.error);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final staffProv = ref.watch(staffProvider);

    if (!_loaded) {
      return const Scaffold(
        
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return Scaffold(
      
      body: Column(children: [
        _header(context),
        Expanded(
          child: ResponsiveCentered(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ? Show current task status as info chip (read-only)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.accent.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text(
                        'Current Status: ${_currentStatus.replaceAll('_', ' ')}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),

                  _label('Task Title'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleCtrl,
                    decoration:
                        _deco('e.g. Build login UI', Icons.title_rounded),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  _label('Description'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: _deco(
                        'Describe the task...', Icons.description_rounded),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  _label('Assign To (Optional)'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderC(context)),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: staffProv.list.any((s) => s.id == _staffId)
                          ? _staffId
                          : null,
                      hint: Text('Staff member (unchanged)',
                          style: TextStyle(
                              color: AppColors.textHi(context), fontSize: 14)),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.person_rounded,
                            color: AppColors.textHi(context), size: 20),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: staffProv.list
                          .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text('${s.name} � ${s.role}',
                                  style: const TextStyle(fontSize: 14))))
                          .toList(),
                      onChanged: (v) => setState(() => _staffId = v),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _label('Task Type'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderC(context)),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _taskType,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.category_rounded,
                            color: AppColors.textHi(context), size: 20),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'].map((p) {
                      final color = p == 'CRITICAL'
                          ? const Color(0xFF06B6D4)
                          : p == 'HIGH'
                              ? AppColors.error
                              : p == 'MEDIUM'
                                  ? AppColors.warning
                                  : AppColors.success;
                      final sel = _priority == p;
                      return GestureDetector(
                        onTap: () => setState(() => _priority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 13),
                          decoration: BoxDecoration(
                            color: sel ? color : color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: sel ? color : color.withOpacity(0.3)),
                          ),
                          child: Text(p,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: sel ? Colors.white : color)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  _label('Estimated Hours (Optional)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _hoursCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _deco(
                        'e.g. 8', Icons.access_time_rounded),
                  ),
                  const SizedBox(height: 16),

                  Row(children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Start Date'),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _pickDate(true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 15),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: _startDate != null
                                          ? AppColors.accent
                                          : AppColors.borderC(context)),
                                ),
                                child: Row(children: [
                                  Icon(Icons.calendar_today_rounded,
                                      size: 18,
                                      color: _startDate != null
                                          ? AppColors.accent
                                          : AppColors.textHi(context)),
                                  const SizedBox(width: 8),
                                  Text(_fmtDate(_startDate),
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: _startDate != null
                                              ? AppColors.textPri(context)
                                              : AppColors.textHi(context))),
                                ]),
                              ),
                            ),
                          ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                      color: _deadline != null
                                          ? AppColors.accent
                                          : AppColors.borderC(context)),
                                ),
                                child: Row(children: [
                                  Icon(Icons.event_rounded,
                                      size: 18,
                                      color: _deadline != null
                                          ? AppColors.accent
                                          : AppColors.textHi(context)),
                                  const SizedBox(width: 8),
                                  Text(_fmtDate(_deadline),
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: _deadline != null
                                              ? AppColors.textPri(context)
                                              : AppColors.textHi(context))),
                                ]),
                              ),
                            ),
                          ]),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  _label('Remarks (Optional)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _remarkCtrl,
                    maxLines: 2,
                    decoration:
                        _deco('Any additional notes...', Icons.note_rounded),
                  ),
                  const SizedBox(height: 28),

                  AppButton(
                    text: 'Update Task',
                    onPressed: _submit,
                    isLoading: _isLoading,
                    icon: Icons.save_rounded,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        ),
      ]),
    );
  }

  Widget _header(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 8, 20, 20),
        decoration: const BoxDecoration(
          gradient:
              LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Edit Task',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            Text('Update task details',
                style: TextStyle(color: Colors.white60, fontSize: 12)),
          ]),
        ]),
      );

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
