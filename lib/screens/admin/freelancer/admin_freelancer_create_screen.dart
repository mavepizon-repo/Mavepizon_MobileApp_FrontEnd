import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/admin_freelancer_provider.dart';

class AdminFreelancerCreateScreen extends ConsumerStatefulWidget {
  final String? freelancerId;
  const AdminFreelancerCreateScreen({super.key, this.freelancerId});
  @override
  ConsumerState<AdminFreelancerCreateScreen> createState() =>
      _AdminFreelancerCreateScreenState();
}

class _AdminFreelancerCreateScreenState
    extends ConsumerState<AdminFreelancerCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _yearPassingCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _techStackCtrl = TextEditingController();
  List<String> _techStacks = [];
  bool _loading = true;
  bool _saving = false;
  bool _isEdit = false;
  bool _obscurePassword = true;

  // File pickers
  File? _profileFile;
  File? _aadhaarFile;
  File? _resumeFile;
  String? _existingProfileUrl;
  String? _existingAadhaarUrl;
  String? _existingResumeUrl;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.freelancerId != null;
    if (_isEdit) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    final f = await ref
        .read(adminFreelancerProvider.notifier)
        .getById(widget.freelancerId!);
    if (f != null && mounted) {
      setState(() {
        _nameCtrl.text = f.name;
        _yearPassingCtrl.text = f.yearOfPassing;
        _experienceCtrl.text = f.experience;
        _districtCtrl.text = f.district;
        _addressCtrl.text = f.address;
        _mobileCtrl.text = f.mobileNo;
        _emailCtrl.text = f.email;
        _existingResumeUrl = f.resume;
        _existingAadhaarUrl = f.aadhaar;
        _existingProfileUrl = f.profile;
        _techStacks = List.from(f.techStackNames);
        _techStackCtrl.text = f.techStackNames.join(', ');
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _yearPassingCtrl.dispose();
    _experienceCtrl.dispose();
    _districtCtrl.dispose();
    _addressCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _techStackCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProfile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) setState(() => _profileFile = File(path));
    }
  }

  Future<void> _pickAadhaar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) setState(() => _aadhaarFile = File(path));
    }
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) setState(() => _resumeFile = File(path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    if (_techStackCtrl.text.trim().isNotEmpty) {
      _techStacks = _techStackCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final data = {
      'name': _nameCtrl.text.trim(),
      'yearOfPassing': _yearPassingCtrl.text.trim(),
      'experience': _experienceCtrl.text.trim(),
      'district': _districtCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'mobileNo': _mobileCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passwordCtrl.text.trim(),
      'resume': _existingResumeUrl ?? '',
      'aadhaar': _existingAadhaarUrl ?? '',
      'techStackNames': _techStacks,
      if (_profileFile != null) 'profileFile': _profileFile,
      if (_aadhaarFile != null) 'aadhaarFile': _aadhaarFile,
      if (_resumeFile != null) 'resumeFile': _resumeFile,
    };

    final ok = _isEdit
        ? await ref
            .read(adminFreelancerProvider.notifier)
            .update(widget.freelancerId!, data)
        : await ref.read(adminFreelancerProvider.notifier).create(data);

    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? (_isEdit ? 'Freelancer updated' : 'Freelancer created')
            : 'Failed to save freelancer')));
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }
    return Scaffold(
      
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Freelancer' : 'Create Freelancer'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_nameCtrl, 'Full Name *', Icons.person_rounded,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Name is required' : null),
            _field(_emailCtrl, 'Email *', Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || v.isEmpty || !v.contains('@'))
                    ? 'Valid email required'
                    : null),
            _field(_mobileCtrl, 'Mobile No *', Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Mobile required' : null),
            _field(_yearPassingCtrl, 'Year of Passing *', Icons.school_rounded,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null),
            _field(_experienceCtrl, 'Experience (years)', Icons.work_rounded,
                keyboardType: TextInputType.number),
            _field(_districtCtrl, 'District', Icons.location_city_rounded),
            _field(_addressCtrl, 'Address', Icons.home_rounded),
            if (!_isEdit)
              _passwordField(
                validator: (v) => (v == null || v.length < 6)
                    ? 'Min 6 characters'
                    : null,
              ),
            _field(_techStackCtrl, 'Tech Stacks (comma separated)',
                Icons.code_rounded,
                hint: 'e.g. Java, Spring Boot, Flutter'),
            const SizedBox(height: 16),

            // ─── FILE UPLOAD SECTION ─────────────────────────────
            Text('Files',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPri(context))),
            const SizedBox(height: 12),

            // Profile Photo
            _filePickerTile(
              label: 'Profile Photo',
              icon: Icons.camera_alt_rounded,
              pickedFile: _profileFile,
              existingUrl: _existingProfileUrl,
              onTap: _pickProfile,
            ),
            const SizedBox(height: 10),

            // Aadhaar
            _filePickerTile(
              label: 'Aadhaar Document',
              icon: Icons.badge_rounded,
              pickedFile: _aadhaarFile,
              existingUrl: _existingAadhaarUrl,
              onTap: _pickAadhaar,
            ),
            const SizedBox(height: 10),

            // Resume
            _filePickerTile(
              label: 'Resume',
              icon: Icons.description_rounded,
              pickedFile: _resumeFile,
              existingUrl: _existingResumeUrl,
              onTap: _pickResume,
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

  Widget _filePickerTile({
    required String label,
    required IconData icon,
    required File? pickedFile,
    required String? existingUrl,
    required VoidCallback onTap,
  }) {
    final hasPicked = pickedFile != null;
    final hasExisting = existingUrl != null && existingUrl.isNotEmpty;
    final displayName = hasPicked
        ? pickedFile.path.split(Platform.pathSeparator).last
        : hasExisting
            ? existingUrl.split('/').last
            : 'No file selected';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasPicked
                ? AppColors.accent.withOpacity(0.5)
                : AppColors.textHi(context).withOpacity(0.2),
          ),
        ),
        child: Row(children: [
          Icon(icon, color: AppColors.textHi(context), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPri(context))),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 11,
                    color: hasPicked ? AppColors.accent : AppColors.textHi(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            hasPicked ? Icons.check_circle_rounded : Icons.upload_rounded,
            color: hasPicked ? AppColors.success : AppColors.textHi(context),
            size: 18,
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType,
      bool obscure = false,
      String? hint,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.textHi(context), size: 20),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _passwordField({String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _passwordCtrl,
        obscureText: _obscurePassword,
        validator: validator,
        decoration: InputDecoration(
          labelText: 'Password *',
          prefixIcon:
              Icon(Icons.lock_rounded, color: AppColors.textHi(context), size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: AppColors.textHi(context),
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}
