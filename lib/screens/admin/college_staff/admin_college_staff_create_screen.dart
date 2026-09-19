import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/admin_college_staff_provider.dart';

class AdminCollegeStaffCreateScreen extends ConsumerStatefulWidget {
  const AdminCollegeStaffCreateScreen({super.key});
  @override
  ConsumerState<AdminCollegeStaffCreateScreen> createState() =>
      _AdminCollegeStaffCreateScreenState();
}

class _AdminCollegeStaffCreateScreenState
    extends ConsumerState<AdminCollegeStaffCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _collegeNameCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  String _selectedGender = 'Male';
  bool _saving = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _collegeNameCtrl.dispose();
    _departmentCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'name': _nameCtrl.text,
      'collegeName': _collegeNameCtrl.text,
      'department': _departmentCtrl.text,
      'email': _emailCtrl.text,
      'password': _passwordCtrl.text,
      'mobileNumber': _mobileCtrl.text,
      'gender': _selectedGender,
    };

    final ok = await ref.read(adminCollegeStaffProvider.notifier).create(data);
    if (mounted) {
      setState(() => _saving = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('College Staff created successfully')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                ref.read(adminCollegeStaffProvider).error ?? 'Failed')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Create College Staff'),
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
          _Field(label: 'College Name', controller: _collegeNameCtrl, required: true),
          const SizedBox(height: 14),
          _Field(label: 'Department', controller: _departmentCtrl, required: true),
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
          _Field(label: 'Email', controller: _emailCtrl, keyboardType: TextInputType.emailAddress, required: true),
          const SizedBox(height: 14),
          _Field(label: 'Mobile Number', controller: _mobileCtrl, keyboardType: TextInputType.phone),
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
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Create',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
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
