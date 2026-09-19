import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../services/admin_team_lead_service.dart';

class AdminTlCreateScreen extends ConsumerStatefulWidget {
  const AdminTlCreateScreen({super.key});
  @override
  ConsumerState<AdminTlCreateScreen> createState() =>
      _AdminTlCreateScreenState();
}

class _AdminTlCreateScreenState extends ConsumerState<AdminTlCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _selectedBranch = 'TIRUNELVELI';
  String _selectedRole = '';
  String _selectedGender = 'Male';
  final _degreeCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  Uint8List? _selectedImage;
  ({Uint8List bytes, String name})? _aadhaarFile;
  ({Uint8List bytes, String name})? _resumeFile;
  final _passwordCtrl = TextEditingController();
  final _nativePlaceCtrl = TextEditingController();
  final _yearPassedOutCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _previousCompanyCtrl = TextEditingController();
  DateTime? _dob;
  DateTime? _joiningDate;
  TimeOfDay _shiftStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _shiftEnd = const TimeOfDay(hour: 18, minute: 0);
  bool _saving = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _degreeCtrl.dispose();
    _skillsCtrl.dispose();
    _passwordCtrl.dispose();
    _nativePlaceCtrl.dispose();
    _yearPassedOutCtrl.dispose();
    _experienceCtrl.dispose();
    _previousCompanyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(DateTime? current, void Function(DateTime) onPicked) async {
    final d = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => onPicked(d));
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _pickTime(TimeOfDay current, void Function(TimeOfDay) onPicked) async {
    final t = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (t != null) setState(() => onPicked(t));
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
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pick resume: $e')));
      }
    }
  }

  Future<void> _pickAadhaar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        setState(() {
          _aadhaarFile = (bytes: file.bytes!, name: file.name);
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
        'branch': _selectedBranch,
        'role': _selectedRole,
        'gender': _selectedGender,
        'degree': _degreeCtrl.text.trim(),
        'skills': _skillsCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'nativePlace': _nativePlaceCtrl.text.trim(),
        'previousCompany': _previousCompanyCtrl.text.trim(),
        if (_dob != null)
          'dob': _dob!.toIso8601String().split('T')[0],
        if (_joiningDate != null)
          'joiningDate': _joiningDate!.toIso8601String().split('T')[0],
        'shiftStart': _fmtTime(_shiftStart),
        'shiftEnd': _fmtTime(_shiftEnd),
        if (_yearPassedOutCtrl.text.isNotEmpty)
          'yearPassedOut': int.tryParse(_yearPassedOutCtrl.text.trim()),
        if (_experienceCtrl.text.isNotEmpty)
          'experience': int.tryParse(_experienceCtrl.text.trim()),
      };

      final result = await AdminTeamLeadService.create(data);
      if (mounted) {
        if (result['success'] == true) {
          final createdId = (result['data'] is Map)
              ? (((result['data'] as Map)['id'] ??
                      (result['data'] as Map)['teamLeadId'])
                  ?.toString())
              : null;
          if (createdId != null && createdId.isNotEmpty) {
            await StorageHelper.saveStaffShiftTime(
              createdId,
              shiftStartTime: _fmtTime(_shiftStart),
              shiftEndTime: _fmtTime(_shiftEnd),
            );
            final files = <String, ({Uint8List bytes, String name})>{};
            if (_selectedImage != null) {
              files['profile'] =
                  (bytes: _selectedImage!, name: 'profile.jpg');
            }
            if (_resumeFile != null) files['resume'] = _resumeFile!;
            if (_aadhaarFile != null) files['aadhaar'] = _aadhaarFile!;
            if (files.isNotEmpty) {
              await ApiClient.multipartPut(
                '/api/admin/teamlead/update-files/$createdId',
                files,
              );
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Team Lead created successfully')));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(result['message']?.toString() ?? 'Failed')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Create Team Lead'),
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
          _Field(label: 'Email', controller: _emailCtrl, keyboardType: TextInputType.emailAddress, required: true),
          const SizedBox(height: 14),
          _Field(label: 'Phone', controller: _phoneCtrl, keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _selectedBranch,
            decoration: _dropdownDeco(context, 'Branch'),
            items: ['TIRUNELVELI', 'THISAYANVILAI', 'NAGERCOIL']
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (v) => setState(() => _selectedBranch = v ?? 'TIRUNELVELI'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: _dropdownDeco(context, 'Gender'),
            items: ['Male', 'Female']
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) => setState(() => _selectedGender = v ?? 'Male'),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => _pickDate(_dob, (d) => _dob = d),
            child: InputDecorator(
              decoration: _dropdownDeco(context, 'Date of Birth'),
              child: Text(
                _dob != null
                    ? '${_dob!.day}/${_dob!.month}/${_dob!.year}'
                    : 'Select Date of Birth',
                style: TextStyle(
                  color: _dob != null ? Colors.black : AppColors.textHi(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _selectedRole.isNotEmpty ? _selectedRole : null,
            decoration: _dropdownDeco(context, 'Role'),
            hint: Text('Select Role', style: TextStyle(color: AppColors.textHi(context))),
            items: ['Senior Team Lead', 'Junior Team Lead', 'LEAD', 'MANAGER', 'TRAINER', 'DEVELOPER']
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => setState(() => _selectedRole = v ?? ''),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => _pickDate(_joiningDate, (d) => _joiningDate = d),
            child: InputDecorator(
              decoration: _dropdownDeco(context, 'Joining Date'),
              child: Text(
                _joiningDate != null
                    ? '${_joiningDate!.day}/${_joiningDate!.month}/${_joiningDate!.year}'
                    : 'Select Joining Date',
                style: TextStyle(
                  color: _joiningDate != null ? Colors.black : AppColors.textHi(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => _pickTime(_shiftStart, (t) => _shiftStart = t),
            child: InputDecorator(
              decoration: _dropdownDeco(context, 'Shift Start Time'),
              child: Row(children: [
                const Icon(Icons.work_outline_rounded,
                    size: 18, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  _fmtTime(_shiftStart),
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w600),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => _pickTime(_shiftEnd, (t) => _shiftEnd = t),
            child: InputDecorator(
              decoration: _dropdownDeco(context, 'Shift End Time'),
              child: Row(children: [
                const Icon(Icons.work_off_outlined,
                    size: 18, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  _fmtTime(_shiftEnd),
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w600),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          _Field(label: 'Native Place', controller: _nativePlaceCtrl),
          const SizedBox(height: 14),
          _Field(label: 'Qualification', controller: _degreeCtrl),
          const SizedBox(height: 14),
          _Field(label: 'Year Passed Out', controller: _yearPassedOutCtrl, keyboardType: TextInputType.number),
          const SizedBox(height: 14),
          _Field(label: 'Experience (years)', controller: _experienceCtrl, keyboardType: TextInputType.number),
          const SizedBox(height: 14),
          _Field(label: 'Previous Company', controller: _previousCompanyCtrl),
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
          _filePickerCard(
            icon: Icons.description_outlined,
            title: 'Resume',
            subtitle: 'Tap to select (pdf, doc, docx)',
            fileName: _resumeFile?.name,
            onTap: _pickResume,
            onClear: _resumeFile != null
                ? () => setState(() => _resumeFile = null)
                : null,
          ),
          const SizedBox(height: 14),
          _filePickerCard(
            icon: Icons.badge_outlined,
            title: 'Aadhaar',
            subtitle: 'Tap to select (pdf, jpg, jpeg, png)',
            fileName: _aadhaarFile?.name,
            onTap: _pickAadhaar,
            onClear: _aadhaarFile != null
                ? () => setState(() => _aadhaarFile = null)
                : null,
          ),
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
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _filePickerCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String? fileName,
    required VoidCallback onTap,
    required VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderC(context)),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.accent.withOpacity(0.1),
            child: Icon(icon, color: AppColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName ?? title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPri(context)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fileName != null ? 'Tap to change' : subtitle,
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textHi(context)),
                  ),
                ]),
          ),
          if (fileName != null && onClear != null)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.error),
            ),
        ]),
      ),
    );
  }
}

InputDecoration _dropdownDeco(BuildContext context, String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Theme.of(context).colorScheme.surface,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderC(context))),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderC(context))),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final bool required;
  final TextInputType? keyboardType;
  const _Field({
    required this.label,
    required this.controller,
    this.obscure = false,
    this.required = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: required && label.isNotEmpty
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
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
