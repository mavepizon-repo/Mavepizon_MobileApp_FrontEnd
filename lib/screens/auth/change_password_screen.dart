import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _conCtrl = TextEditingController();
  bool _o1 = true, _o2 = true, _o3 = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _conCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final r = await AuthService.changePassword(
      _oldCtrl.text.trim(),
      _newCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (r['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(r['message'] ?? 'Something went wrong'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.accent,
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Change Password',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPri(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your current password and set a new one.',
              style: TextStyle(fontSize: 14, color: AppColors.textSec(context)),
            ),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _passField(
                    'Current Password',
                    _oldCtrl,
                    _o1,
                    () => setState(() => _o1 = !_o1),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  _passField(
                    'New Password',
                    _newCtrl,
                    _o2,
                    () => setState(() => _o2 = !_o2),
                    validator: (v) =>
                        v!.length < 6 ? 'Minimum 6 characters' : null,
                  ),
                  _passField(
                    'Confirm New Password',
                    _conCtrl,
                    _o3,
                    () => setState(() => _o3 = !_o3),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v != _newCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    text: 'Update Password',
                    onPressed: _submit,
                    isLoading: _isLoading,
                    icon: Icons.check_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passField(
    String label,
    TextEditingController ctrl,
    bool obscure,
    VoidCallback toggle, {
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPri(context),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          obscureText: obscure,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(color: AppColors.textHi(context)),
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textHi(context),
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textHi(context),
                size: 20,
              ),
              onPressed: toggle,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.borderC(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.borderC(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.accent, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
          validator: validator,
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}
