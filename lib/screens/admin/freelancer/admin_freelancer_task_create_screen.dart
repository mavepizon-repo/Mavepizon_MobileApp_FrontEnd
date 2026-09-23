import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/admin_freelancer_provider.dart';
import '../../../providers/freelancer_provider.dart';

class AdminFreelancerTaskCreateScreen extends ConsumerStatefulWidget {
  final String? taskId;
  const AdminFreelancerTaskCreateScreen({super.key, this.taskId});
  @override
  ConsumerState<AdminFreelancerTaskCreateScreen> createState() =>
      _AdminFreelancerTaskCreateScreenState();
}

class _AdminFreelancerTaskCreateScreenState
    extends ConsumerState<AdminFreelancerTaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orgCtrl = TextEditingController();
  final _noDaysCtrl = TextEditingController();
  final _meetingLinkCtrl = TextEditingController();
  final _meetingEmailCtrl = TextEditingController();
  final _meetingPasswordCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _domainCtrl = TextEditingController();
  final _noStudentsCtrl = TextEditingController();
  final _syllabusCtrl = TextEditingController();
  File? _syllabusFile;
  String? _existingSyllabusUrl;
  DateTime? _startDate;
  DateTime? _endDate;
  String _status = 'PENDING';
  Set<String> _selected = {};
  bool _loading = true;
  bool _saving = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.taskId != null;
    Future.microtask(() async {
      // ensure freelancer list & tasks loaded
      final fp = ref.read(adminFreelancerProvider.notifier);
      if (ref.read(adminFreelancerProvider).list.isEmpty) {
        await fp.fetch(size: 100);
      }
      if (_isEdit) {
        final tp = ref.read(adminFreelancerTasksProvider.notifier);
        final pag = ref.read(adminFreelancerTasksProvider);
        dynamic task;
        var pg = 0;
        while (true) {
          if (pg != pag.currentPage || pag.pageSize != 100) {
            await tp.fetchAll(page: pg, size: 100);
          }
          task = ref
              .read(adminFreelancerTasksProvider)
              .tasks
              .where((t) => t.id == widget.taskId)
              .firstOrNull;
          if (task != null) break;
          final cur = ref.read(adminFreelancerTasksProvider);
          if (pg >= cur.totalPages - 1) break;
          pg++;
        }
        if (task != null) {
          setState(() {
            _orgCtrl.text = task.orgName;
            _noDaysCtrl.text = task.noOfDays;
            _meetingLinkCtrl.text = task.meetingLink;
            _meetingEmailCtrl.text = task.meetingEmail;
            _meetingPasswordCtrl.text = task.meetingPassword;
            _departmentCtrl.text = task.department;
            _domainCtrl.text = task.domain;
            _noStudentsCtrl.text = task.noOfStudents;
            _existingSyllabusUrl = task.syllabus;
            _status = task.status;
            _startDate = DateTime.tryParse(task.startDate);
            _endDate = DateTime.tryParse(task.endDate);
            _selected = task.freelancerIds.toSet();
          });
        }
      }
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _orgCtrl.dispose();
    _noDaysCtrl.dispose();
    _meetingLinkCtrl.dispose();
    _meetingEmailCtrl.dispose();
    _meetingPasswordCtrl.dispose();
    _departmentCtrl.dispose();
    _domainCtrl.dispose();
    _noStudentsCtrl.dispose();
    _syllabusCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(DateTime? current, void Function(DateTime) onPicked,
      {bool future = false}) async {
    final d = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: future ? DateTime.now() : DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => onPicked(d));
  }

  Future<void> _pickSyllabus() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
    );
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) setState(() => _syllabusFile = File(path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Select at least one freelancer')));
      return;
    }
    setState(() => _saving = true);

    final data = {
      'orgName': _orgCtrl.text.trim(),
      'noOfDays': _noDaysCtrl.text.trim(),
      'startDate': _startDate?.toIso8601String() ?? '',
      'endDate': _endDate?.toIso8601String() ?? '',
      'meetingLink': _meetingLinkCtrl.text.trim(),
      'meetingEmail': _meetingEmailCtrl.text.trim(),
      'meetingPassword': _meetingPasswordCtrl.text.trim(),
      'department': _departmentCtrl.text.trim(),
      'domain': _domainCtrl.text.trim(),
      'noOfStudents': _noStudentsCtrl.text.trim(),
      'status': _status,
      'freelancerIds': _selected.map(int.tryParse).whereType<int>().toList(),
      if (_syllabusFile != null) 'syllabusFile': _syllabusFile,
    };

    final ok = _isEdit
        ? await ref
            .read(adminFreelancerTasksProvider.notifier)
            .update(widget.taskId!, data)
        : await ref
            .read(adminFreelancerTasksProvider.notifier)
            .create(data);

    setState(() => _saving = false);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            ok ? (_isEdit ? 'Task updated' : 'Task created') : 'Failed to save task')));
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final freelancers = ref.watch(adminFreelancerProvider).list;

    return Scaffold(
      
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Freelancer Task' : 'Create Freelancer Task'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _field(_orgCtrl, 'Org Name (College/Company) *',
                      Icons.business_center_rounded,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null),
                  _field(_departmentCtrl, 'Department *', Icons.apartment_rounded,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null),
                  _field(_domainCtrl, 'Domain *', Icons.category_rounded,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null),
                  Row(children: [
                    Expanded(
                        child: _dateField('Start Date', _startDate, () => _pickDate(
                            _startDate,
                            (d) => _startDate = d,
                            future: true))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _dateField('End Date', _endDate, () => _pickDate(
                            _endDate,
                            (d) => _endDate = d,
                            future: true))),
                  ]),
                  Row(children: [
                    Expanded(
                        child: _field(_noDaysCtrl, 'No of Days',
                            Icons.timelapse_rounded,
                            keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(_noStudentsCtrl, 'No of Students',
                            Icons.groups_rounded,
                            keyboardType: TextInputType.number)),
                  ]),
                  _field(_meetingLinkCtrl, 'Meeting Link', Icons.link_rounded),
                  _field(_meetingEmailCtrl, 'Meeting Email', Icons.email_rounded),
                  _field(_meetingPasswordCtrl, 'Meeting Password',
                      Icons.password_rounded),
                  const SizedBox(height: 14),
                  Text('Syllabus File',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPri(context))),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickSyllabus,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _syllabusFile != null
                              ? AppColors.accent.withOpacity(0.5)
                              : AppColors.textHi(context).withOpacity(0.2),
                        ),
                      ),
                      child: Row(children: [
                        Icon(Icons.upload_file_rounded,
                            color: AppColors.textHi(context), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _syllabusFile != null
                                ? _syllabusFile!.path
                                    .split(Platform.pathSeparator)
                                    .last
                                : _existingSyllabusUrl != null &&
                                        _existingSyllabusUrl!.isNotEmpty
                                    ? _existingSyllabusUrl!
                                        .split('/')
                                        .last
                                    : 'Tap to select syllabus file (PDF, DOC)',
                            style: TextStyle(
                              fontSize: 13,
                              color: _syllabusFile != null
                                  ? AppColors.accent
                                  : AppColors.textHi(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          _syllabusFile != null
                              ? Icons.check_circle_rounded
                              : Icons.file_upload_rounded,
                          color: _syllabusFile != null
                              ? AppColors.success
                              : AppColors.textHi(context),
                          size: 18,
                        ),
                      ]),
                    ),
                  ),
                  // Status
                  const SizedBox(height: 14),
                  Text('Status',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPri(context))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['PENDING', 'ONGOING', 'COMPLETED', 'CANCELLED']
                        .map((s) => ChoiceChip(
                              label: Text(s,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _status == s
                                          ? Colors.white
                                          : AppColors.textSec(context))),
                              selected: _status == s,
                              selectedColor: AppColors.primary,
                              
                              onSelected: (_) => setState(() => _status = s),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  // Freelancer selection
                  Text('Assign Freelancers *',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPri(context))),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: freelancers.isEmpty
                        ? Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No freelancers available',
                                style: TextStyle(color: AppColors.textHi(context))),
                          )
                        : Column(
                            children: freelancers.map((f) {
                              final selected =
                                  _selected.contains(f.id);
                              return CheckboxListTile(
                                value: selected,
                                dense: true,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(f.name,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPri(context))),
                                subtitle: Text(
                                    '${f.district}${f.techStackNames.isNotEmpty ? ' • ${f.techStackNames.join(', ')}' : ''}',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textHi(context))),
                                onChanged: (v) => setState(() {
                                  if (v == true) {
                                    _selected.add(f.id);
                                  } else {
                                    _selected.remove(f.id);
                                  }
                                }),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(_isEdit ? 'Update' : 'Create',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.textHi(context), size: 20),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(Icons.calendar_today_rounded,
                color: AppColors.textHi(context), size: 20),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          child: Text(
            value == null
                ? 'Select date'
                : '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
            style: TextStyle(
                color: value == null ? AppColors.textHi(context) : AppColors.textPri(context)),
          ),
        ),
      ),
    );
  }
}
