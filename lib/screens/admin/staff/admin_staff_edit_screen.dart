import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../models/staff_model.dart';
import '../../../providers/admin_staff_provider.dart';
import '../../../services/admin_staff_service.dart';

class AdminStaffEditScreen extends ConsumerStatefulWidget {
  final String staffId;
  const AdminStaffEditScreen({super.key, required this.staffId});
  @override
  ConsumerState<AdminStaffEditScreen> createState() =>
      _AdminStaffEditScreenState();
}

class _AdminStaffEditScreenState extends ConsumerState<AdminStaffEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _qualCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  Uint8List? _selectedImage;
  String? _existingPhoto;
  final _expCtrl = TextEditingController();
  final _prevCoCtrl = TextEditingController();
  final _bloodCtrl = TextEditingController();
  final _nativeCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  ({Uint8List bytes, String name})? _resumeFile;
  ({Uint8List bytes, String name})? _aadharFile;
  String? _resumePath;
  String? _aadharPath;
  String? _existingResume;
  String? _existingAadhar;
  String _role = 'DEVELOPER';
  String _category = 'DEVELOPER';
  String _gender = 'Male';
  String _branch = '';
  DateTime? _joiningDate;
  TimeOfDay? _shiftStart;
  TimeOfDay? _shiftEnd;
  bool _saving = false;
  bool _loaded = false;

  final _roles = [
    'DEVELOPER',
    'DEVELOPER_TRAINER',
    'TELECOM_SERVICE',
    'DESIGNER',
  ];
  final _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(adminStaffProvider.notifier).fetchById(widget.staffId));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _qualCtrl.dispose();
    _skillsCtrl.dispose();
    _expCtrl.dispose();
    _prevCoCtrl.dispose();
    _bloodCtrl.dispose();
    _nativeCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  void _populate() {
    if (_loaded) return;
    final s = ref.read(adminStaffProvider).selected;
    if (s == null) return;
    _nameCtrl.text = s.name;
    _emailCtrl.text = s.email;
    _phoneCtrl.text = s.mobileNumber;
    _qualCtrl.text = s.degree;
    _skillsCtrl.text = s.skills.join(', ');
    _existingPhoto = s.profilePhoto;
    _expCtrl.text = s.experience ?? '';
    _prevCoCtrl.text = s.previousCompany ?? '';
    _bloodCtrl.text = s.bloodGroup ?? '';
    _nativeCtrl.text = s.nativePlace;
    _yearCtrl.text = s.yearPassedOut != null ? s.yearPassedOut.toString() : '';
    _existingResume = s.resume;
    _existingAadhar = s.aadhar;
    _branch = s.branch;
    _role = _roles.contains(s.role) ? s.role : 'DEVELOPER';
    _category = s.category.isNotEmpty ? s.category : _role;
    _gender = s.gender.isNotEmpty ? s.gender : 'Male';
    _joiningDate = DateTime.tryParse(s.joiningDate);
    _shiftStart = _parseTime(s.shiftStartTime);
    _shiftEnd = _parseTime(s.shiftEndTime);
    _loaded = true;
  }

  TimeOfDay? _parseTime(String raw) {
    final parts = raw.split(':');
    if (parts.isEmpty) return null;
    final h = int.tryParse(parts[0]);
    final m = parts.length > 1 ? int.tryParse(parts[1]) : null;
    if (h == null) return null;
    return TimeOfDay(hour: h, minute: m ?? 0);
  }

  Future<void> _pickShiftStart() async {
    final picked = await _pickTime(
        initial: _shiftStart ?? const TimeOfDay(hour: 9, minute: 0));
    if (picked != null) setState(() => _shiftStart = picked);
  }

  Future<void> _pickShiftEnd() async {
    final picked = await _pickTime(
        initial: _shiftEnd ?? const TimeOfDay(hour: 18, minute: 0));
    if (picked != null) setState(() => _shiftEnd = picked);
  }

  Future<TimeOfDay?> _pickTime({required TimeOfDay initial}) async {
    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (_, child) => Theme(
          data: Theme.of(context).copyWith(
              colorScheme:
                  const ColorScheme.light(primary: AppColors.accent)),
          child: child!),
    );
  }

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return '';
    final h = t.hour.toString().padLeft(2, '0');
    return '$h:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (_, child) => Theme(
          data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.accent)),
          child: child!),
    );
    if (picked != null) setState(() => _joiningDate = picked);
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _selectedImage = bytes);
    }
  }

  Future<void> _pickResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        setState(() {
          _resumeFile = (bytes: file.bytes!, name: file.name);
          _resumePath = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pick resume: $e')));
      }
    }
  }

  Future<void> _pickAadhar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        setState(() {
          _aadharFile = (bytes: file.bytes!, name: file.name);
          _aadharPath = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pick aadhaar: $e')));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim().toLowerCase(),
        'mobileNumber': _phoneCtrl.text.trim(),
        'degree': _qualCtrl.text.trim(),
        'role': _role,
        'category': _category,
        'gender': _gender,
        'branch': _branch,
        'skills': _skillsCtrl.text.trim(),
        'nativePlace': _nativeCtrl.text.trim(),
        'yearPassedOut': int.tryParse(_yearCtrl.text.trim()) ?? 0,
        'joiningDate': _joiningDate?.toIso8601String().split('T').first ?? '',
        'experience': _expCtrl.text.trim(),
        'previousCompany': _prevCoCtrl.text.trim(),
        'bloodGroup': _bloodCtrl.text.trim(),
        'shiftStartTime': _fmtTime(_shiftStart),
        'shiftEndTime': _fmtTime(_shiftEnd),
      };

      final ok = await AdminStaffService.update(widget.staffId, data);
      if (mounted) {
        if (ok['success'] == true) {
          if (_selectedImage != null) {
            await ApiClient.multipartPut(
              '/api/admin/staff/update-files/${widget.staffId}',
              {'profile': (bytes: _selectedImage!, name: 'profile.jpg')},
            );
          }
          final files = <String, ({Uint8List bytes, String name})>{};
          if (_resumeFile != null) files['resume'] = _resumeFile!;
          if (_aadharFile != null) files['aadhaar'] = _aadharFile!;
          if (files.isNotEmpty) {
            await ApiClient.multipartPut(
              '/api/admin/staff/update-files/${widget.staffId}',
              files,
            );
          }
          await StorageHelper.saveStaffShiftTime(
            widget.staffId,
            shiftStartTime: _fmtTime(_shiftStart),
            shiftEndTime: _fmtTime(_shiftEnd),
          );
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Staff updated successfully')));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(ok['message'] ?? 'Failed')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _dropdownField(String label, String value, List<String> items,
      void Function(String?) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSec(context))),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: items.contains(value) ? value : null,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        decoration: _dropdownDecoration(context, ),
      ),
    ]);
  }

  Widget _buildFileUpload({
    required String label,
    required String? path,
    String? existingUrl,
    required IconData icon,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    final hasExisting = existingUrl != null && existingUrl.isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPri(context))),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: onPick,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderC(context)),
              ),
              child: Row(children: [
                Icon(icon, color: AppColors.textHi(context), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    path != null
                        ? path.split('\\').last.split('/').last
                        : (hasExisting ? 'Tap to replace' : 'Tap to select'),
                    style: TextStyle(
                      fontSize: 13,
                      color: path != null || hasExisting
                          ? AppColors.textPri(context)
                          : AppColors.textHi(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasExisting && path == null)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 18),
              ]),
            ),
          ),
        ),
        if (path != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close_rounded,
                  color: AppColors.error, size: 18),
            ),
          ),
        ],
      ]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    _populate();
    final p = ref.watch(adminStaffProvider);

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Edit Staff'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: p.isLoading && !_loaded
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : p.error != null && !_loaded
              ? Center(child: Text(p.error!))
              : Form(
                  key: _formKey,
                  child: ListView(
                      padding: const EdgeInsets.all(16), children: [
                    _Field(label: 'Full Name', controller: _nameCtrl, required: true),
                    const SizedBox(height: 14),
                    _Field(label: 'Email', controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 14),
                    _Field(label: 'Phone', controller: _phoneCtrl,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 14),
                    _Field(label: 'Qualification', controller: _qualCtrl),
                    const SizedBox(height: 14),
                    _Field(label: 'Experience (years)', controller: _expCtrl,
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 14),
                    _Field(label: 'Previous Company', controller: _prevCoCtrl),
                    const SizedBox(height: 14),
                    _Field(label: 'Blood Group', controller: _bloodCtrl),
                    const SizedBox(height: 14),
                    _Field(label: 'Native Place', controller: _nativeCtrl),
                    const SizedBox(height: 14),
                    _Field(label: 'Year Passed Out', controller: _yearCtrl,
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 14),
                    _Field(label: 'Skills (comma separated)',
                        controller: _skillsCtrl),
                    const SizedBox(height: 14),
                    _dropdownField('Gender', _gender, _genders,
                        (v) => setState(() => _gender = v ?? 'Male')),
                    const SizedBox(height: 14),
                    _dropdownField('Role', _role, _roles,
                        (v) => setState(() => _role = v ?? 'DEVELOPER')),
                    const SizedBox(height: 14),
                    _dropdownField('Category', _category, _roles,
                        (v) => setState(() => _category = v ?? 'DEVELOPER')),
                    const SizedBox(height: 14),
                    _dropdownField('Branch', _branch,
                        ['TIRUNELVELI', 'THISAYANVILAI', 'NAGERCOIL', 'COIMBATORE'],
                        (v) => setState(() => _branch = v ?? '')),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderC(context)),
                        ),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: _selectedImage != null
                                ? MemoryImage(_selectedImage!) as ImageProvider
                                : (_existingPhoto != null && _existingPhoto!.isNotEmpty
                                    ? NetworkImage(_existingPhoto!) as ImageProvider
                                    : null),
                            backgroundColor: AppColors.accent.withOpacity(0.1),
                            child: _selectedImage == null && (_existingPhoto == null || _existingPhoto!.isEmpty)
                                ? const Icon(Icons.camera_alt_rounded,
                                    color: AppColors.accent)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      _selectedImage != null
                                          ? 'Photo selected'
                                          : (_existingPhoto != null && _existingPhoto!.isNotEmpty
                                              ? 'Change Photo'
                                              : 'Add Photo'),
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPri(context))),
                                  Text('Tap to select from gallery',
                                      style: TextStyle(
                                          fontSize: 11, color: AppColors.textHi(context))),
                                ]),
                          ),
                          if (_selectedImage != null)
                            GestureDetector(
                              onTap: () => setState(() => _selectedImage = null),
                              child: const Icon(Icons.close_rounded,
                                  size: 18, color: AppColors.error),
                            ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildFileUpload(
                      label: 'Resume',
                      path: _resumePath,
                      existingUrl: _existingResume,
                      icon: Icons.description_rounded,
                      onPick: _pickResume,
                      onClear: () => setState(() {
                        _resumeFile = null;
                        _resumePath = null;
                      }),
                    ),
                    const SizedBox(height: 14),
                    _buildFileUpload(
                      label: 'Aadhaar Card',
                      path: _aadharPath,
                      existingUrl: _existingAadhar,
                      icon: Icons.badge_rounded,
                      onPick: _pickAadhar,
                      onClear: () => setState(() {
                        _aadharFile = null;
                        _aadharPath = null;
                      }),
                    ),
                    const SizedBox(height: 14),
                    _DateField(
                        label: 'Joining Date',
                        value: _joiningDate,
                        onTap: _pickDate),
                    const SizedBox(height: 14),
                    _TimeField(
                        label: 'Shift Start Time',
                        value: _shiftStart,
                        onTap: _pickShiftStart),
                    const SizedBox(height: 14),
                    _TimeField(
                        label: 'Shift End Time',
                        value: _shiftEnd,
                        onTap: _pickShiftEnd),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12))),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : const Text('Update',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                ),
    );
  }
}

InputDecoration _dropdownDecoration(context, ) {
  return InputDecoration(
    filled: true,
    fillColor: Theme.of(context).colorScheme.surface,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderC(context))),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderC(context))),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool required;
  final TextInputType? keyboardType;
  const _Field({
    required this.label,
    required this.controller,
    this.required = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: required
          ? (v) =>
              (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.borderC(context))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.borderC(context))),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  const _DateField(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderC(context)),
        ),
        child: Row(children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textHi(context))),
          const Spacer(),
          Text(
            value != null
                ? '${value!.day}/${value!.month}/${value!.year}'
                : 'Select',
            style: TextStyle(
                fontSize: 14,
                color: value != null
                    ? AppColors.textPri(context)
                    : AppColors.textHi(context)),
          ),
          const SizedBox(width: 4),
          Icon(Icons.calendar_today_rounded,
              size: 16, color: AppColors.textHi(context)),
        ]),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final VoidCallback onTap;
  const _TimeField(
      {required this.label, required this.value, required this.onTap});

  String _fmt(TimeOfDay? t) {
    if (t == null) return 'Select';
    final ampm = t.hour < 12 ? 'AM' : 'PM';
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h12:${t.minute.toString().padLeft(2, '0')} $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderC(context)),
        ),
        child: Row(children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textHi(context))),
          const Spacer(),
          Text(
            _fmt(value),
            style: TextStyle(
                fontSize: 14,
                color: value != null
                    ? AppColors.textPri(context)
                    : AppColors.textHi(context)),
          ),
          const SizedBox(width: 4),
          Icon(Icons.schedule_rounded,
              size: 16, color: AppColors.textHi(context)),
        ]),
      ),
    );
  }
}
