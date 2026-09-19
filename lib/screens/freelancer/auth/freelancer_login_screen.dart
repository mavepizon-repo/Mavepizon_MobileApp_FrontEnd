import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/freelancer_service.dart';
import '../../../routes/app_routes.dart';

class FreelancerLoginScreen extends ConsumerStatefulWidget {
  const FreelancerLoginScreen({super.key});
  @override
  ConsumerState<FreelancerLoginScreen> createState() =>
      _FreelancerLoginScreenState();
}

class _FreelancerLoginScreenState extends ConsumerState<FreelancerLoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _emailFocused = false;
  bool _passFocused = false;

  late AnimationController _entryCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _bgCtrl;
  late AnimationController _bubbleCtrl;

  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _footerFade;
  late Animation<double> _floatY;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 8000))
      ..repeat(reverse: true);
    _bubbleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 6000))
      ..repeat();

    _logoFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
    _logoSlide =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _entryCtrl,
                curve:
                    const Interval(0.0, 0.6, curve: Curves.easeOutBack)));

    _cardFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.3, 0.75, curve: Curves.easeOut)));
    _cardSlide =
        Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _entryCtrl,
                curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic)));

    _footerFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn)));

    _floatY = Tween<double>(begin: -6, end: 6)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    Future.delayed(
        const Duration(milliseconds: 200), () => _entryCtrl.forward());
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    _bgCtrl.dispose();
    _bubbleCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() {});
    final result = await FreelancerService.login(
        _emailCtrl.text.trim(), _passCtrl.text.trim());
    setState(() {});

    if (!mounted) return;
    if (result['success'] == true) {
      final data = result['data'];
      if (data is Map) {
        await StorageHelper.saveLoginData(
          token: data['token']?.toString() ?? '',
          role: data['role']?.toString() ?? 'FREELANCER',
          userId: data['freelancerId']?.toString() ?? '',
          userName: data['name']?.toString() ?? '',
          userEmail: data['email']?.toString() ?? '',
          userProfile: data['profile']?.toString() ?? '',
        );
        await ref.read(authProvider.notifier).loadUser();
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.freelancerMain);
        }
        return;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(result['message'] ?? 'Invalid email or password')),
      ]),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(children: [
        // Animated gradient background
        AnimatedBuilder(
          animation: _bgCtrl,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF06B6D4),
                  const Color(0xFF0891B2),
                  Color.lerp(const Color(0xFF06B6D4),
                      const Color(0xFF22D3EE), _bgCtrl.value)!,
                  const Color(0xFF0891B2),
                ],
                stops: [
                  0.0,
                  0.3 + _bgCtrl.value * 0.15,
                  0.65 + _bgCtrl.value * 0.1,
                  1.0,
                ],
              ),
            ),
          ),
        ),

        // Floating bubbles
        AnimatedBuilder(
          animation: _bubbleCtrl,
          builder: (_, __) => CustomPaint(
            size: size,
            painter: _BubblePainter(_bubbleCtrl.value),
          ),
        ),

        // Top decorative circle
        Positioned(
          top: -size.width * 0.3,
          left: -size.width * 0.25,
          child: Container(
            width: size.width * 0.7,
            height: size.width * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.08), width: 1.5),
            ),
          ),
        ),

        // Bottom decorative circle
        Positioned(
          bottom: -size.width * 0.2,
          right: -size.width * 0.15,
          child: Container(
            width: size.width * 0.5,
            height: size.width * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.04),
            ),
          ),
        ),

        // Main content
        SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: size.height -
                      MediaQuery.of(context).viewPadding.top -
                      MediaQuery.of(context).viewPadding.bottom),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 50),

                      // Logo + Title
                      AnimatedBuilder(
                        animation:
                            Listenable.merge([_entryCtrl, _floatCtrl]),
                        builder: (_, __) {
                          return FadeTransition(
                            opacity: _logoFade,
                            child: SlideTransition(
                              position: _logoSlide,
                              child: Transform.translate(
                                offset: Offset(0, _floatY.value),
                                child: Column(children: [
                                  // Freelancer icon in circle
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.white
                                                .withOpacity(0.3),
                                            blurRadius: 40,
                                            spreadRadius: 8),
                                        BoxShadow(
                                            color: Colors.black
                                                .withOpacity(0.1),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10)),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.work_outline_rounded,
                                      color: Color(0xFF0891B2),
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Title
                                  Text(
                                    'FREELANCER',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 6,
                                      shadows: [
                                        Shadow(
                                            color: Colors.black
                                                .withOpacity(0.15),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'PORTAL LOGIN',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withOpacity(0.85),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 44),

                      // Login Card
                      AnimatedBuilder(
                        animation: _entryCtrl,
                        builder: (_, child) => FadeTransition(
                          opacity: _cardFade,
                          child: SlideTransition(
                              position: _cardSlide, child: child),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15)),
                              BoxShadow(
                                  color: const Color(0xFF06B6D4)
                                      .withOpacity(0.12),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome Back',
                                  style: TextStyle(
                                    color: AppColors.textPri(context),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sign in as Freelancer',
                                  style: TextStyle(
                                    color: AppColors.textSec(context)
                                        .withOpacity(0.8),
                                    fontSize: 13,
                                  ),
                                ),

                                const SizedBox(height: 28),

                                // Email
                                _AnimatedField(
                                  controller: _emailCtrl,
                                  label: 'Email Address',
                                  hint: 'you@example.com',
                                  icon: Icons.email_outlined,
                                  keyboardType:
                                      TextInputType.emailAddress,
                                  isFocused: _emailFocused,
                                  onFocusChange: (f) =>
                                      setState(() => _emailFocused = f),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Email is required';
                                    }
                                    if (!v.contains('@')) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 18),

                                // Password
                                _AnimatedField(
                                  controller: _passCtrl,
                                  label: 'Password',
                                  hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: _obscure,
                                  isFocused: _passFocused,
                                  onFocusChange: (f) =>
                                      setState(() => _passFocused = f),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                        () => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons
                                              .visibility_off_outlined
                                          : Icons
                                              .visibility_outlined,
                                      color: AppColors.textHi(context),
                                      size: 20,
                                    ),
                                    splashRadius: 20,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.length < 6) {
                                      return 'Min 6 characters';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 30),

                                // Sign In button
                                _LoginButton(
                                    isLoading: false,
                                    onTap: _login),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Back to main login
                      AnimatedBuilder(
                        animation: _entryCtrl,
                        builder: (_, __) => FadeTransition(
                          opacity: _footerFade,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: GestureDetector(
                              onTap: () => Navigator.pushReplacementNamed(
                                  context, AppRoutes.login),
                              child: RichText(
                                text: TextSpan(
                                  text: 'Not a freelancer? ',
                                  style: TextStyle(
                                    color:
                                        Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: 'Back to Login',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        decoration:
                                            TextDecoration.underline,
                                        decorationColor:
                                            Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// Animated Input Field
class _AnimatedField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool? obscure;
  final bool isFocused;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final void Function(bool) onFocusChange;
  final String? Function(String?) validator;

  const _AnimatedField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isFocused,
    required this.onFocusChange,
    required this.validator,
    this.obscure,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isFocused ? Colors.white : Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: onFocusChange,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isFocused
                    ? Colors.white.withOpacity(0.5)
                    : Colors.white.withOpacity(0.15),
                width: isFocused ? 1.5 : 1,
              ),
              color: isFocused
                  ? Colors.white.withOpacity(0.12)
                  : Colors.white.withOpacity(0.08),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 16,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: TextFormField(
              controller: controller,
              obscureText: obscure ?? false,
              keyboardType: keyboardType,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
              validator: validator,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.35), fontSize: 14),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(icon,
                      color: isFocused
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      size: 20),
                ),
                suffixIcon: suffixIcon,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                errorStyle: TextStyle(
                    color: Colors.red.shade200, fontSize: 11),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Sign In Button
class _LoginButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _LoginButton({required this.isLoading, required this.onTap});

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLoading ? null : (_) => _ctrl.forward(),
      onTapUp: widget.isLoading ? null : (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      onTap: widget.isLoading ? null : widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isLoading
                  ? [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.2),
                    ]
                  : [
                      Colors.white,
                      Colors.white.withOpacity(0.9),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Color(0xFF0891B2), strokeWidth: 2.5))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Color(0xFF0891B2),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06B6D4).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded,
                            color: Color(0xFF0891B2), size: 16),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// Floating Bubble Painter
class _BubblePainter extends CustomPainter {
  final double progress;
  _BubblePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint();

    for (int i = 0; i < 12; i++) {
      final x = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 20 + 8;
      final speed = (rng.nextDouble() * 0.3 + 0.7);
      final y = (baseY - progress * size.height * speed) % size.height;
      final adjustedY = y < 0 ? y + size.height : y;

      paint.color = Colors.white.withOpacity(0.04 + rng.nextDouble() * 0.04);
      canvas.drawCircle(Offset(x, adjustedY), r, paint);

      paint.color = Colors.white.withOpacity(0.08 + rng.nextDouble() * 0.05);
      canvas.drawCircle(Offset(x, adjustedY), r * 0.4, paint);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
