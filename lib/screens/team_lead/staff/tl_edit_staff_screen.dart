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

class TlEditStaffScreen extends ConsumerStatefulWidget {
  final String staffId;
  const TlEditStaffScreen({super.key, required this.staffId});

  @override
  ConsumerState<TlEditStaffScreen> createState() => _TlEditStaffScreenState();
}

class _TlEditStaffScreenState extends ConsumerState<TlEditStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _c = <String, TextEditingController>{};

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
  String? _existingProfile;
  String? _existingResume;
  String? _existingAadhar;
  bool _isLoading = false;
  bool _loaded = false;

  final _roles = [
    'DEVELOPER',
    'DEVELOPER_TRAINER',
    'TELECOM_SERVICE',
    'DESIGNER',
  ];
  final _branches = ['TIRUNELVELI', 'THISAYANVILAI', 'NAGERCOIL', 'COIMBATORE'];
  final _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStaff());
  }

  Future<void> _loadStaff() async {
    if (!mounted) return;
    final prov = ref.read(staffProvider.notifier);
    await prov.fetchById(widget.staffId);
    if (!mounted) return;

    final staff = ref.read(staffProvider).selected;
    if (staff == null) return;

    _c['name'] = TextEditingController(text: staff.name);
    _c['email'] = TextEditingController(text: staff.email);
    _c['mobileNumber'] = TextEditingController(text: staff.mobileNumber);
    _c['degree'] = TextEditingController(text: staff.degree);
    _c['experience'] = TextEditingController(text: staff.experience ?? '');
    _c['previousCompany'] =
        TextEditingController(text: staff.previousCompany ?? '');
    _c['bloodGroup'] = TextEditingController(text: staff.bloodGroup ?? '');
    _c['skills'] = TextEditingController(text: staff.skills.join(', '));
    _c['nativePlace'] = TextEditingController(text: staff.nativePlace);
    _c['yearPassedOut'] = TextEditingController(
        text: staff.yearPassedOut != null ? staff.yearPassedOut.toString() : '');

    _role = staff.role;
    _category = staff.category.isNotEmpty ? staff.category : staff.role;
    _gender = staff.gender.isNotEmpty ? staff.gender : 'Male';
    _branch = staff.branch;

    if (staff.joiningDate.isNotEmpty) {
      try {
        _joiningDate = DateTime.parse(staff.joiningDate);
      } catch (_) {
        _joiningDate = null;
      }
    }

    _shiftStart = _parseTime(staff.shiftStartTime);
    _shiftEnd = _parseTime(staff.shiftEndTime);

    _existingProfile = staff.profilePhoto;
    _existingResume = staff.resume;
    _existingAadhar = staff.aadhar;

    setState(() => _loaded = true);
  }

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
      builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final data = {
      'name': _c['name']!.text.trim(),
      'email': _c['email']!.text.trim().toLowerCase(),
      'mobileNumber': _c['mobileNumber']!.text.trim(),
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

    final ok = await ref.read(staffProvider.notifier).updateWithFiles(
          widget.staffId,
          data,
          profile: _profileFile,
          aadhaar: _aadharFile,
          resume: _resumeFile,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      _showSnack('Staff updated successfully!', AppColors.success);
      Navigator.pop(context);
    } else {
      _showSnack(ref.read(staffProvider).error ?? 'Failed to update',
          AppColors.error);
    }
  }

  void _showSnack(String msg, Color color) {
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
    if (!_loaded) {
      return const Scaffold(
        
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

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
                  Text('Edit Staff',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  Text('Update staff details',
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
                      existingUrl: _existingProfile,
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
                      existingUrl: _existingResume,
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
                      existingUrl: _existingAadhar,
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
                                'Changes will be applied immediately. Staff will be notified.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.info,
                                    fontWeight: FontWeight.w500))),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                        text: 'Update Staff',
                        onPressed: _isLoading ? null : _submit,
                        isLoading: _isLoading,
                        icon: Icons.save_rounded),
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
              value == null ? 'Select' : _fmtTime(value),
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
                        : (hasExisting
                            ? 'Tap to replace'
                            : 'Tap to select'),
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
