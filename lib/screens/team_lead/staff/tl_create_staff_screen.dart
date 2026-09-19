import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/staff_provider.dart';
import '../../../widgets/app_button.dart';

class TlCreateStaffScreen extends ConsumerStatefulWidget {
  const TlCreateStaffScreen({super.key});
  @override
  ConsumerState<TlCreateStaffScreen> createState() => _TlCreateStaffScreenState();
}

class _TlCreateStaffScreenState extends ConsumerState<TlCreateStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _c = <String, TextEditingController>{
    'name': TextEditingController(),
    'email': TextEditingController(),
    'mobileNumber': TextEditingController(),
    'password': TextEditingController(),
    'degree': TextEditingController(),
    'experience': TextEditingController(),
    'previousCompany': TextEditingController(),
    'bloodGroup': TextEditingController(),
    'skills': TextEditingController(),
    'nativePlace': TextEditingController(),
    'yearPassedOut': TextEditingController(),
  };

  String _role = 'DEVELOPER';
  String _category = 'DEVELOPER';
  String _gender = 'Male';
  String _branch = 'TIRUNELVELI';
  DateTime? _joiningDate;
  TimeOfDay? _shiftStart;
  TimeOfDay? _shiftEnd;
  ({Uint8List bytes, String name})? _profileFile;
  ({Uint8List bytes, String name})? _resumeFile;
  ({Uint8List bytes, String name})? _aadharFile;
  String? _profilePath;
  String? _resumePath;
  String? _aadharPath;
  bool _obscure = true;
  bool _isSubmitting = false;

  final _roles = [
    'DEVELOPER',
    'DEVELOPER_TRAINER',
    'TELECOM_SERVICE',
    'DESIGNER',
  ];
  final _branches = ['TIRUNELVELI', 'THISAYANVILAI', 'NAGERCOIL', 'COIMBATORE'];
  final _genders = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    for (var c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickJoiningDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _joiningDate = picked);
    }
  }

  Future<void> _pickShiftStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _shiftStart ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
              colorScheme:
                  const ColorScheme.light(primary: AppColors.accent)),
          child: child!),
    );
    if (picked != null) setState(() => _shiftStart = picked);
  }

  Future<void> _pickShiftEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _shiftEnd ?? const TimeOfDay(hour: 18, minute: 0),
      builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
              colorScheme:
                  const ColorScheme.light(primary: AppColors.accent)),
          child: child!),
    );
    if (picked != null) setState(() => _shiftEnd = picked);
  }

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return '';
    final h = t.hour.toString().padLeft(2, '0');
    return '$h:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickProfile() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _profileFile = (bytes: bytes, name: picked.name);
          _profilePath = picked.name;
        });
      }
    } catch (e) {
      if (context.mounted) {
        _showSnack('Failed to pick image: $e', AppColors.error);
      }
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
      if (context.mounted) {
        _showSnack('Failed to pick resume: $e', AppColors.error);
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
      if (context.mounted) {
        _showSnack('Failed to pick aadhar: $e', AppColors.error);
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _doSubmit());
  }

  Future<void> _doSubmit() async {
    setState(() => _isSubmitting = true);

    final data = {
      'name': _c['name']!.text.trim(),
      'email': _c['email']!.text.trim().toLowerCase(),
      'mobileNumber': _c['mobileNumber']!.text.trim(),
      'password': _c['password']!.text.trim(),
      'degree': _c['degree']!.text.trim(),
      'experience': _c['experience']!.text.trim().isEmpty
          ? 0
          : int.tryParse(_c['experience']!.text.trim()) ?? 0,
      'previousCompany': _c['previousCompany']!.text.trim(),
      'bloodGroup': _c['bloodGroup']!.text.trim(),
      'role': _role,
      'category': _category,
      'gender': _gender,
      'branch': _branch,
      'skills': _c['skills']!.text.trim(),
      'nativePlace': _c['nativePlace']!.text.trim(),
      'yearPassedOut': _c['yearPassedOut']!.text.trim().isEmpty
          ? 0
          : int.tryParse(_c['yearPassedOut']!.text.trim()) ?? 0,
      'joiningDate': _joiningDate != null
          ? DateFormat('yyyy-MM-dd').format(_joiningDate!)
          : '',
      'shiftStartTime': _fmtTime(_shiftStart),
      'shiftEndTime': _fmtTime(_shiftEnd),
    };

    final ok = await ref.read(staffProvider.notifier).createWithFiles(
          data,
          profile: _profileFile,
          aadhaar: _aadharFile,
          resume: _resumeFile,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      _showSnack('Staff created successfully!', AppColors.success);
      Navigator.pop(context);
    } else {
      final errorMsg = ref.read(staffProvider).error ?? 'Failed';
      _showSnack(errorMsg, AppColors.error);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16)));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(staffProvider).isLoading;

    return Scaffold(
      
      body: Column(children: [
        Container(
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 8, 20, 20),
          decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28)),
          ),
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
                  Text('Add New Staff',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  Text('Request goes to admin for approval',
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
                    _section('Upload Documents'),
                    _fileUpload(
                      label: 'Profile Photo',
                      path: _profilePath,
                      icon: Icons.camera_alt_rounded,
                      onPick: _pickProfile,
                      onClear: () => setState(() {
                        _profileFile = null;
                        _profilePath = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                    _fileUpload(
                      label: 'Resume',
                      path: _resumePath,
                      icon: Icons.description_rounded,
                      onPick: _pickResume,
                      onClear: () => setState(() {
                        _resumeFile = null;
                        _resumePath = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                    _fileUpload(
                      label: 'Aadhar Card',
                      path: _aadharPath,
                      icon: Icons.badge_rounded,
                      onPick: _pickAadhar,
                      onClear: () => setState(() {
                        _aadharFile = null;
                        _aadharPath = null;
                      }),
                    ),
                    const SizedBox(height: 8),
                    _section('Personal Information'),
                    _field('Full Name', 'name',
                        icon: Icons.person_rounded,
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                    _field('Email Address', 'email',
                        icon: Icons.alternate_email_rounded,
                        type: TextInputType.emailAddress,
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                    _field('Phone Number', 'mobileNumber',
                        icon: Icons.phone_rounded,
                        type: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                    _field('Qualification', 'degree',
                        icon: Icons.school_rounded,
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                    _field('Experience', 'experience',
                        icon: Icons.work_history_rounded, hint: 'e.g. 2'),
                    _field('Previous Company', 'previousCompany',
                        icon: Icons.business_rounded),
                    _field('Blood Group', 'bloodGroup',
                        icon: Icons.bloodtype_rounded, hint: 'e.g. A+'),
                    _field('Native Place', 'nativePlace',
                        icon: Icons.home_rounded),
                    _field('Year Passed Out', 'yearPassedOut',
                        icon: Icons.school_outlined,
                        type: TextInputType.number,
                        hint: 'e.g. 2023'),
                    _field('Skills', 'skills',
                        icon: Icons.psychology_rounded,
                        hint: 'Comma separated: Flutter, Dart'),
                    _section('Account'),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Password',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPri(context))),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _c['password'],
                            obscureText: _obscure,
                            decoration: _deco('Enter password',
                                    Icons.lock_outline_rounded)
                                .copyWith(
                                    suffixIcon: GestureDetector(
                                        onTap: () => setState(
                                            () => _obscure = !_obscure),
                                        child: Icon(
                                            _obscure
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: AppColors.textHi(context),
                                            size: 20))),
                            validator: (v) =>
                                v!.length < 6 ? 'Minimum 6 characters' : null,
                          ),
                          const SizedBox(height: 16),
                        ]),
                    _section('Work Details'),
                    _joiningDatePicker(),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: _shiftTime(
                              'Shift Start', _shiftStart, _pickShiftStart)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _shiftTime(
                              'Shift End', _shiftEnd, _pickShiftEnd)),
                    ]),
                    const SizedBox(height: 16),
                    _dropdown('Gender', _gender, _genders, Icons.person_outline_rounded,
                        (v) => setState(() => _gender = v!)),
                    const SizedBox(height: 16),
                    _dropdown('Role', _role, _roles, Icons.badge_rounded,
                        (v) => setState(() => _role = v!)),
                    const SizedBox(height: 16),
                    _dropdown('Category', _category, _roles, Icons.category_rounded,
                        (v) => setState(() => _category = v!)),
                    const SizedBox(height: 16),
                    _dropdown(
                        'Branch',
                        _branch,
                        _branches,
                        Icons.location_on_rounded,
                        (v) => setState(() => _branch = v!)),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.info.withOpacity(0.2))),
                      child: const Row(children: [
                        Icon(Icons.info_rounded,
                            color: AppColors.info, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                            child: Text(
                                'Staff will receive login access only after admin approval.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.info,
                                    fontWeight: FontWeight.w500))),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                        text: 'Create Staff',
                        onPressed: _isSubmitting || isLoading ? null : _submit,
                        isLoading: _isSubmitting || isLoading,
                        icon: Icons.person_add_rounded),
                    const SizedBox(height: 24),
                  ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _section(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: Row(children: [
        Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(t,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPri(context))),
      ]));

  Widget _field(
    String label,
    String key, {
    String? hint,
    IconData? icon,
    TextInputType? type,
    String? Function(String?)? validator,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPri(context))),
      const SizedBox(height: 8),
      TextFormField(
          controller: _c[key],
          keyboardType: type,
          decoration: _deco(hint ?? 'Enter $label', icon ?? Icons.edit_rounded),
          validator: validator),
      const SizedBox(height: 16),
    ]);
  }

  Widget _joiningDatePicker() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Joining Date',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPri(context))),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _pickJoiningDate,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderC(context)),
          ),
          child: Row(children: [
            Icon(Icons.calendar_today_rounded,
                color: AppColors.textHi(context), size: 20),
            const SizedBox(width: 12),
            Text(
              _joiningDate != null
                  ? DateFormat('dd-MM-yyyy').format(_joiningDate!)
                  : 'Select joining date',
              style: TextStyle(
                fontSize: 14,
                color: _joiningDate != null
                    ? AppColors.textPri(context)
                    : AppColors.textHi(context),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 16),
    ]);
  }

  Widget _shiftTime(String label, TimeOfDay? value, VoidCallback onTap) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPri(context))),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderC(context)),
          ),
          child: Row(children: [
            Icon(Icons.schedule_rounded,
                color: AppColors.textHi(context), size: 20),
            const SizedBox(width: 12),
            Text(
              value == null
                  ? 'Select'
                  : _fmtTime(value),
              style: TextStyle(
                fontSize: 14,
                color: value != null
                    ? AppColors.textPri(context)
                    : AppColors.textHi(context),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _fileUpload({
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
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
      const SizedBox(height: 12),
    ]);
  }

  Widget _dropdown(String label, String value, List<String> items,
      IconData icon, void Function(String?) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPri(context))),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderC(context))),
        child: DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.textHi(context), size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
          items: items
              .map((i) => DropdownMenuItem(
                  value: i,
                  child: Text(i, style: const TextStyle(fontSize: 14))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    ]);
  }

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
