import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_button.dart';

// ✅ FIX: Complete 3-step forgot password flow.
// Old screen only called sendOtp() and stopped — verifyOtp() and
// resetPassword() were never called from any UI. Now implements all 3 steps:
//   Step 1: Enter email -> send OTP
//   Step 2: Enter OTP -> verify
//   Step 3: Enter new password -> reset
class ForgotPasswordScreen extends StatefulWidget {
  final String role;
  const ForgotPasswordScreen({super.key, this.role = ''});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Step { email, otp, newPassword, success }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  _Step _step = _Step.email;
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── STEP 1: Send OTP ────────────────────────────────────────
  Future<void> _sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final r = await AuthService.forgotPassword(_emailCtrl.text.trim(),
        role: widget.role);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (r['success'] == true) {
      setState(() => _step = _Step.otp);
    } else {
      _showError(r['message'] ?? 'Failed to send OTP. Please try again.');
    }
  }

  // ── STEP 2: Verify OTP ──────────────────────────────────────
  Future<void> _verifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final r = await AuthService.verifyOtp(
      _emailCtrl.text.trim(),
      _otpCtrl.text.trim(),
      role: widget.role,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (r['success'] == true) {
      setState(() => _step = _Step.newPassword);
    } else {
      _showError(r['message'] ?? 'Invalid OTP. Please try again.');
    }
  }

  // ── STEP 3: Reset Password ──────────────────────────────────
  Future<void> _resetPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final r = await AuthService.resetPassword(
      _emailCtrl.text.trim(),
      _otpCtrl.text.trim(),
      _newPasswordCtrl.text.trim(),
      role: widget.role,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (r['success'] == true) {
      setState(() => _step = _Step.success);
    } else {
      _showError(r['message'] ?? 'Failed to reset password. Please try again.');
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    final r = await AuthService.forgotPassword(_emailCtrl.text.trim(),
        role: widget.role);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (r['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('OTP resent to your email'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } else {
      _showError(r['message'] ?? 'Failed to resend OTP');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text(
          _step == _Step.success ? 'Done' : 'Forgot Password',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: switch (_step) {
            _Step.email => _emailView(),
            _Step.otp => _otpView(),
            _Step.newPassword => _newPasswordView(),
            _Step.success => _successView(),
          },
        ),
      ),
    );
  }

  // ── STEP 1 UI: Email ─────────────────────────────────────────
  Widget _emailView() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _iconHeader(Icons.lock_reset_rounded),
          const SizedBox(height: 20),
          Text('Reset Password',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPri(context))),
          const SizedBox(height: 6),
          Text(
            'Enter your registered email address. We will send you an OTP.',
            style: TextStyle(fontSize: 14, color: AppColors.textSec(context)),
          ),
          const SizedBox(height: 32),
          Form(
            key: _emailFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Email Address'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    hint: 'you@example.com',
                    icon: Icons.alternate_email_rounded,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}$')
                        .hasMatch(v)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                AppButton(
                  text: 'Send OTP',
                  onPressed: _sendOtp,
                  isLoading: _isLoading,
                  icon: Icons.send_rounded,
                ),
              ],
            ),
          ),
        ],
      );

  // ── STEP 2 UI: OTP ───────────────────────────────────────────
  Widget _otpView() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _iconHeader(Icons.mark_email_unread_rounded),
          const SizedBox(height: 20),
          Text('Enter OTP',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPri(context))),
          const SizedBox(height: 6),
          Text(
            'We sent a verification code to\n${_emailCtrl.text.trim()}',
            style:
                TextStyle(fontSize: 14, color: AppColors.textSec(context)),
          ),
          const SizedBox(height: 32),
          Form(
            key: _otpFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('OTP Code'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6),
                  decoration: _inputDecoration(
                    hint: '------',
                    icon: Icons.pin_rounded,
                  ).copyWith(counterText: ''),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'OTP is required';
                    if (v.length < 4) return 'Enter a valid OTP';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _resendOtp,
                    child: const Text('Resend OTP',
                        style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  text: 'Verify OTP',
                  onPressed: _verifyOtp,
                  isLoading: _isLoading,
                  icon: Icons.check_circle_outline_rounded,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _step = _Step.email),
                    child: Text('Change Email',
                        style: TextStyle(color: AppColors.textSec(context))),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  // ── STEP 3 UI: New Password ──────────────────────────────────
  Widget _newPasswordView() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _iconHeader(Icons.password_rounded),
          const SizedBox(height: 20),
          Text('Set New Password',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPri(context))),
          const SizedBox(height: 6),
          Text(
            'Create a new password for your account.',
            style: TextStyle(fontSize: 14, color: AppColors.textSec(context)),
          ),
          const SizedBox(height: 32),
          Form(
            key: _passwordFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('New Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newPasswordCtrl,
                  obscureText: _obscureNew,
                  decoration: _inputDecoration(
                    hint: 'Enter new password',
                    icon: Icons.lock_outline_rounded,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppColors.textHi(context),
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _fieldLabel('Confirm Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordCtrl,
                  obscureText: _obscureConfirm,
                  decoration: _inputDecoration(
                    hint: 'Re-enter new password',
                    icon: Icons.lock_outline_rounded,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppColors.textHi(context),
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (v != _newPasswordCtrl.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                AppButton(
                  text: 'Reset Password',
                  onPressed: _resetPassword,
                  isLoading: _isLoading,
                  icon: Icons.check_rounded,
                ),
              ],
            ),
          ),
        ],
      );

  // ── STEP 4 UI: Success ───────────────────────────────────────
  Widget _successView() => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 40),
          ),
          const SizedBox(height: 24),
          Text('Password Reset!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPri(context))),
          const SizedBox(height: 10),
          Text(
            'Your password has been reset successfully.\nYou can now login with your new password.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSec(context)),
          ),
          const SizedBox(height: 36),
          AppButton(
            text: 'Back to Login',
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
            icon: Icons.arrow_back_rounded,
          ),
        ],
      );

  // ── Shared helpers ───────────────────────────────────────────
  Widget _iconHeader(IconData icon) => Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: AppColors.accent, size: 28),
      );

  Widget _fieldLabel(String text) => Text(
        text,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPri(context)),
      );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textHi(context)),
        prefixIcon: Icon(icon, color: AppColors.textHi(context), size: 20),
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
      );
}
