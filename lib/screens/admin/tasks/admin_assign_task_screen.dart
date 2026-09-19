import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/admin_staff_provider.dart';
import '../../../services/task_service.dart';
import '../../../core/utils/storage_helper.dart';

class AdminAssignTaskScreen extends ConsumerStatefulWidget {
  const AdminAssignTaskScreen({super.key});
  @override
  ConsumerState<AdminAssignTaskScreen> createState() =>
      _AdminAssignTaskScreenState();
}

class _AdminAssignTaskScreenState extends ConsumerState<AdminAssignTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  String? _selectedStaffId;
  String _priority = 'MEDIUM';
  String _taskType = 'DEVELOPMENT';
  DateTime? _deadline;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminStaffProvider.notifier).fetch());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _remarksCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final adminId = await StorageHelper.getUserId();
    final data = {
      'staffId': int.tryParse(_selectedStaffId ?? '') ?? 0,
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'deadline': _deadline?.toIso8601String().substring(0, 10) ?? '',
      'taskType': _taskType,
      'priority': _priority,
      'estimatedHours': int.tryParse(_hoursCtrl.text) ?? 0,
      'remarks': _remarksCtrl.text.trim(),
    };
    final result = await TaskService.assignTaskAdmin(adminId ?? '', data);
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task assigned'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed'), backgroundColor: AppColors.error),
      );
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final staffProv = ref.watch(adminStaffProvider);

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Assign Task'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            DropdownButtonFormField<String>(
              value: _selectedStaffId,
              decoration: _dec('Assign To'),
              items: staffProv.list.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
              onChanged: (v) => setState(() => _selectedStaffId = v),
              validator: (v) => v == null ? 'Select a staff member' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _titleCtrl,
              decoration: _dec('Title'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: _dec('Description'),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: _dec('Priority'),
                  items: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _priority = v ?? 'MEDIUM'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _taskType,
                  decoration: _dec('Type'),
                  items: ['DEVELOPMENT', 'TRAINING', 'DESIGN', 'TELECOM']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _taskType = v ?? 'DEVELOPMENT'),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setState(() => _deadline = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Icon(Icons.event_rounded, size: 18, color: AppColors.textHi(context)),
                      const SizedBox(width: 8),
                      Text(_deadline == null ? 'Deadline' : _deadline!.toIso8601String().substring(0, 10),
                          style: TextStyle(color: _deadline == null ? AppColors.textHi(context) : AppColors.textPri(context))),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _hoursCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _dec('Est. Hours'),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            TextFormField(
              controller: _remarksCtrl,
              maxLines: 2,
              decoration: _dec('Remarks'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Assign Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Theme.of(context).colorScheme.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
