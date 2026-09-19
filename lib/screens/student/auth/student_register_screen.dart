import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/student_service.dart';

class StudentRegisterScreen extends ConsumerStatefulWidget {
  const StudentRegisterScreen({super.key});

  @override
  ConsumerState<StudentRegisterScreen> createState() =>
      _StudentRegisterScreenState();
}

class _StudentRegisterScreenState
    extends ConsumerState<StudentRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _collegeCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String _gender = 'Male';

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final result = await StudentService.register({
        'name': _nameCtrl.text.trim(),
        'gender': _gender,
        'collegeName': _collegeCtrl.text.trim(),
        'department': _deptCtrl.text.trim(),
        'mobileNumber': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'skills': _skillsCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['success'] == true
                ? 'Registered successfully! Please login.'
                : result['message'] ?? 'Registration failed'),
            backgroundColor: result['success'] == true
                ? AppColors.success
                : AppColors.error,
          ),
        );
        if (result['success'] == true) {
          Navigator.pop(context);
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _collegeCtrl.dispose();
    _deptCtrl.dispose();
    _skillsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Register',
            style: TextStyle(
                color: AppColors.textPri(context),
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPri(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ]),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _Field('Full Name', _nameCtrl, 'Enter your full name',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Name required' : null),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: _fieldDecoration('Gender', 'Select gender'),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                ),
                const SizedBox(height: 14),
                _Field('College Name', _collegeCtrl, 'Enter college name'),
                const SizedBox(height: 14),
                _Field('Department', _deptCtrl, 'Enter department'),
                const SizedBox(height: 14),
                _Field('Email', _emailCtrl, 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Email required' : null),
                const SizedBox(height: 14),
                _Field('Phone', _phoneCtrl, 'Enter your phone',
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                _Field('Skills', _skillsCtrl, 'Enter skills (comma separated)'),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Create a password',
                    hintStyle: TextStyle(color: AppColors.textHi(context)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.accent, width: 1.5),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  validator: (v) =>
                      (v != _passwordCtrl.text) ? 'Passwords do not match' : null,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter password',
                    hintStyle: TextStyle(color: AppColors.textHi(context)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.accent, width: 1.5),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Create Account',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Already have an account? ',
                  style: TextStyle(color: AppColors.textSec(context))),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text('Login',
                    style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textHi(context)),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  const _Field(this.label, this.controller, this.hint,
      {this.keyboardType, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textHi(context)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }
}
