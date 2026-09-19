import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../providers/admin_team_lead_provider.dart';
import '../../../services/admin_team_lead_service.dart';

class AdminTlEditScreen extends ConsumerStatefulWidget {
  final String tlId;
  const AdminTlEditScreen({super.key, required this.tlId});
  @override
  ConsumerState<AdminTlEditScreen> createState() => _AdminTlEditScreenState();
}

class _AdminTlEditScreenState extends ConsumerState<AdminTlEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _degreeCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  Uint8List? _selectedImage;
  String? _existingPhoto;
  final _nativePlaceCtrl = TextEditingController();
  final _yearPassedOutCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _previousCompanyCtrl = TextEditingController();
  String _selectedBranch = 'TIRUNELVELI';
  String _selectedRole = '';
  String _selectedGender = 'Male';
  DateTime? _dob;
  DateTime? _joiningDate;
  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminTeamLeadProvider.notifier).fetchById(widget.tlId));
  }

  void _populate() {
    if (_loaded) return;
    final tl = ref.read(adminTeamLeadProvider).selected;
    if (tl == null) return;
    _nameCtrl.text = tl.fullName;
    _emailCtrl.text = tl.email;
    _phoneCtrl.text = tl.phone;
    _selectedBranch = tl.branchName;
    _selectedRole = tl.role;
    _degreeCtrl.text = tl.qualification;
    _skillsCtrl.text = tl.skills.join(', ');
    _existingPhoto = tl.profilePhoto;
    _selectedGender = tl.gender ?? 'Male';
    _nativePlaceCtrl.text = tl.nativePlace ?? '';
    _yearPassedOutCtrl.text = tl.yearPassedOut ?? '';
    _experienceCtrl.text = tl.experience ?? '';
    _previousCompanyCtrl.text = tl.previousWorkingCompany ?? '';
    if (tl.dob != null && tl.dob!.isNotEmpty) {
      _dob = DateTime.tryParse(tl.dob!);
    }
    if (tl.joiningDate.isNotEmpty) {
      _joiningDate = DateTime.tryParse(tl.joiningDate);
    }
    _loaded = true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _degreeCtrl.dispose();
    _skillsCtrl.dispose();
    _nativePlaceCtrl.dispose();
    _yearPassedOutCtrl.dispose();
    _experienceCtrl.dispose();
    _previousCompanyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(DateTime? current, void Function(DateTime) onPicked) async {
    final d = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(2000),
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => onPicked(d));
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _selectedImage = bytes);
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
        'degree': _degreeCtrl.text.trim(),
        'skills': _skillsCtrl.text.trim(),
        if (_existingPhoto != null && _existingPhoto!.isNotEmpty)
          'profilePhoto': _existingPhoto,
        'gender': _selectedGender,
        'nativePlace': _nativePlaceCtrl.text.trim(),
        'previousCompany': _previousCompanyCtrl.text.trim(),
        if (_dob != null)
          'dob': _dob!.toIso8601String().split('T')[0],
        if (_joiningDate != null)
          'joiningDate': _joiningDate!.toIso8601String().split('T')[0],
        if (_yearPassedOutCtrl.text.isNotEmpty)
          'yearPassedOut': int.tryParse(_yearPassedOutCtrl.text.trim()),
        if (_experienceCtrl.text.isNotEmpty)
          'experience': int.tryParse(_experienceCtrl.text.trim()),
      };

      final result = await AdminTeamLeadService.update(widget.tlId, data);
      if (mounted) {
        if (result['success'] == true) {
          if (_selectedImage != null) {
            await ApiClient.multipartPut(
              '/api/admin/teamlead/update-files/${widget.tlId}',
              {'profile': (bytes: _selectedImage!, name: 'profile.jpg')},
            );
          }
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Updated successfully')));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(result['message']?.toString() ?? 'Update failed')));
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
    _populate();
    final p = ref.watch(adminTeamLeadProvider);

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Edit Team Lead'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: p.isLoading && !_loaded
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : Form(
              key: _formKey,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                _Field(label: 'Full Name', controller: _nameCtrl, required: true),
                const SizedBox(height: 14),
                _Field(label: 'Email', controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
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
