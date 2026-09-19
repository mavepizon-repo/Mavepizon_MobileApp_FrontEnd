import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../services/admin_staff_service.dart';

class AdminStaffCreateScreen extends ConsumerStatefulWidget {
  const AdminStaffCreateScreen({super.key});
  @override
  ConsumerState<AdminStaffCreateScreen> createState() =>
      _AdminStaffCreateScreenState();
}

class _AdminStaffCreateScreenState extends ConsumerState<AdminStaffCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _qualCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  Uint8List? _selectedImage;
  ({Uint8List bytes, String name})? _resumeFile;
  ({Uint8List bytes, String name})? _aadharFile;
  String? _resumePath;
  String? _aadharPath;
  final _expCtrl = TextEditingController();
  final _prevCoCtrl = TextEditingController();
  final _bloodCtrl = TextEditingController();
  final _nativeCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  String _role = 'DEVELOPER';
  String _gender = 'Male';
  String _category = 'DEVELOPER';
  String _branch = '';
  DateTime? _joiningDate;
  TimeOfDay? _shiftStart;
  TimeOfDay? _shiftEnd;
  bool _saving = false;
  bool _obscurePassword = true;

  final _roles = [
    'DEVELOPER',
    'DEVELOPER_TRAINER',
    'TELECOM_SERVICE',
    'DESIGNER',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _qualCtrl.dispose();
    _skillsCtrl.dispose();
    _expCtrl.dispose();
    _prevCoCtrl.dispose();
    _bloodCtrl.dispose();
    _nativeCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
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

  Future<void> _pickShiftStart() async {
    final picked = await _pickTime(initial: _shiftStart ?? const TimeOfDay(hour: 9, minute: 0));
    if (picked != null) setState(() => _shiftStart = picked);
  }

  Future<void> _pickShiftEnd() async {
    final picked = await _pickTime(initial: _shiftEnd ?? const TimeOfDay(hour: 18, minute: 0));
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
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
      final adminId = await StorageHelper.getUserId() ?? '';
      final data = {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim().toLowerCase(),
        'mobileNumber': _phoneCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'degree': _qualCtrl.text.trim(),
        'role': _role,
        'category': _category,
        'gender': _gender,
        'branch': _branch,
        'nativePlace': _nativeCtrl.text.trim(),
        'yearPassedOut': int.tryParse(_yearCtrl.text.trim()) ?? 0,
        'skills': _skillsCtrl.text.trim(),
        'joiningDate': _joiningDate?.toIso8601String().split('T').first ?? '',
        'experience': int.tryParse(_expCtrl.text.trim()) ?? 0,
        'previousCompany': _prevCoCtrl.text.trim(),
        'bloodGroup': _bloodCtrl.text.trim(),
        'approvalStatus': 'APPROVED',
        'active': true,
        'shiftStartTime': _fmtTime(_shiftStart),
        'shiftEndTime': _fmtTime(_shiftEnd),
      };

      final ok = await AdminStaffService.create(adminId, data);
      if (mounted) {
        if (ok['success'] == true) {
          final createdId = (ok['data'] is Map)
              ? (ok['data'] as Map)['staffId']?.toString()
              : null;
          if (createdId != null && createdId.isNotEmpty) {
            if (_selectedImage != null) {
              await ApiClient.multipartPut(
                '/api/admin/staff/update-files/$createdId',
                {'profile': (bytes: _selectedImage!, name: 'profile.jpg')},
              );
            }
            final files = <String, ({Uint8List bytes, String name})>{};
            if (_resumeFile != null) files['resume'] = _resumeFile!;
            if (_aadharFile != null) files['aadhaar'] = _aadharFile!;
            if (files.isNotEmpty) {
              await ApiClient.multipartPut(
                '/api/admin/staff/update-files/$createdId',
                files,
              );
            }
            await StorageHelper.saveStaffShiftTime(
              createdId,
              shiftStartTime: _fmtTime(_shiftStart),
              shiftEndTime: _fmtTime(_shiftEnd),
            );
          }
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Staff created successfully')));
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

  Widget _buildFileUpload({
    required String label,
    required String? path,
    required IconData icon,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
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
                        : 'Tap to select',
                    style: TextStyle(
                      fontSize: 13,
                      color: path != null
                          ? AppColors.textPri(context)
                          : AppColors.textHi(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Create Staff'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _Field(label: 'Full Name', controller: _nameCtrl, required: true),
          const SizedBox(height: 14),
          _Field(label: 'Email', controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress, required: true),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Password is required' : null,
            decoration: InputDecoration(
              labelText: 'Password',
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
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textHi(context),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _Field(label: 'Phone', controller: _phoneCtrl,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          _Field(label: 'Qualification', controller: _qualCtrl),
          const SizedBox(height: 14),
          Text('Gender', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSec(context))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _gender,
            items: ['Male', 'Female', 'Other']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _gender = v ?? 'Male'),
            decoration: _dropdownDecoration(context, ),
          ),
          const SizedBox(height: 14),
          Text('Role', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSec(context))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _role,
            items: _roles
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _role = v ?? 'DEVELOPER'),
            decoration: _dropdownDecoration(context, ),
          ),
          const SizedBox(height: 14),
          Text('Category', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSec(context))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _category,
            items: _roles
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? 'DEVELOPER'),
            decoration: _dropdownDecoration(context, ),
          ),
          const SizedBox(height: 14),
          Text('Branch', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSec(context))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _branch.isEmpty ? null : _branch,
            items: ['TIRUNELVELI', 'THISAYANVILAI', 'NAGERCOIL', 'COIMBATORE']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _branch = v ?? ''),
            decoration: _dropdownDecoration(context, ),
            validator: (v) => (v == null || v.isEmpty) ? 'Branch is required' : null,
          ),
          const SizedBox(height: 14),
          _Field(label: 'Native Place', controller: _nativeCtrl),
          const SizedBox(height: 14),
          _Field(label: 'Year Passed Out', controller: _yearCtrl,
              keyboardType: TextInputType.number),
          const SizedBox(height: 14),
          _Field(label: 'Skills (comma separated)', controller: _skillsCtrl),
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
                      : null,
                  backgroundColor: AppColors.accent.withOpacity(0.1),
                  child: _selectedImage == null
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
                            _selectedImage != null ? 'Photo selected' : 'Add Photo',
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
          const SizedBox(height: 14),
          _Field(label: 'Experience (years)', controller: _expCtrl,
              keyboardType: TextInputType.number),
          const SizedBox(height: 14),
          _Field(label: 'Previous Company', controller: _prevCoCtrl),
          const SizedBox(height: 14),
          _Field(label: 'Blood Group', controller: _bloodCtrl),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Create',
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
  final bool obscureText;
  const _Field({
    required this.label,
    required this.controller,
    this.required = false,
    this.keyboardType,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
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
    final m = t.minute.toString().padLeft(2, '0');
    return '$h12:$m $ampm';
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
