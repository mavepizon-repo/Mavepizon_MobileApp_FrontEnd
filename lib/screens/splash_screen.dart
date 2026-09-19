import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _textCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _dotsCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _logoRotate;

  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleFade;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _taglineFade;

  late Animation<double> _ring1;
  late Animation<double> _ring2;
  late Animation<double> _ring3;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();

    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();

    _dotsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat();

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.15)
              .chain(CurveTween(curve: Curves.easeOutQuart)),
          weight: 60),
      TweenSequenceItem(
          tween: Tween(begin: 1.15, end: 0.95)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: 0.95, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 20),
    ]).animate(_logoCtrl);

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));

    _logoRotate = Tween<double>(begin: -0.06, end: 0.0).animate(
        CurvedAnimation(
            parent: _logoCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));

    _ring1 = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut)));
    _ring2 = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOut)));
    _ring3 = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut)));

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));

    _titleSlide = Tween<Offset>(
            begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _textCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)));

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _textCtrl,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOut)));

    _subtitleSlide = Tween<Offset>(
            begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _textCtrl,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic)));

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn)));

    _run();
  }

  void _run() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _ringCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1600));

    // Always start from a fresh login screen on every app launch / refresh,
    // regardless of any previously saved session, so the user always lands
    // back on the login screen instead of being auto-routed elsewhere.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _logoCtrl.dispose();
    _pulseCtrl.dispose();
    _textCtrl.dispose();
    _ringCtrl.dispose();
    _shimmerCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0EA5E9),
              Color(0xFF0284C7),
              Color(0xFF0369A1),
              Color(0xFF0EA5E9),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: Stack(children: [
          ...List.generate(18, (i) => _FloatingParticle(index: i, size: size)),

          CustomPaint(size: size, painter: _GridPainter()),

          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  Color(0xFF38BDF8),
                  Color(0xFF0EA5E9),
                  Color(0xFF06B6D4),
                  Color(0xFF38BDF8),
                ]),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge(
                      [_logoCtrl, _ringCtrl, _pulseCtrl, _shimmerCtrl]),
                  builder: (_, __) {
                    return SizedBox(
                      width: 260,
                      height: 260,
                      child: Stack(alignment: Alignment.center, children: [
                        Opacity(
                          opacity: _ring3.value * 0.2,
                          child: Transform.scale(
                            scale: 0.5 + _ring3.value * 0.5,
                            child: Container(
                              width: 260,
                              height: 260,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF38BDF8), width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: _ring2.value * 0.3,
                          child: Transform.scale(
                            scale: 0.5 + _ring2.value * 0.5,
                            child: Container(
                              width: 210,
                              height: 210,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF06B6D4), width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: _ring1.value * 0.4,
                          child: Transform.scale(
                            scale: 0.5 + _ring1.value * 0.5,
                            child: Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF22D3EE), width: 1.5),
                              ),
                            ),
                          ),
                        ),

                        Opacity(
                          opacity: (1 - _pulseCtrl.value) * 0.35,
                          child: Transform.scale(
                            scale: 0.6 + _pulseCtrl.value * 0.6,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF38BDF8), width: 1),
                              ),
                            ),
                          ),
                        ),

                        FadeTransition(
                          opacity: _logoFade,
                          child: Transform.rotate(
                            angle: _logoRotate.value,
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(36),
                                  boxShadow: [
                                    BoxShadow(
                                        color: const Color(0xFF0EA5E9)
                                            .withOpacity(0.45),
                                        blurRadius: 60,
                                        spreadRadius: 10),
                                    BoxShadow(
                                        color: const Color(0xFF06B6D4)
                                            .withOpacity(0.2),
                                        blurRadius: 40,
                                        spreadRadius: 5,
                                        offset: const Offset(0, 10)),
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 30,
                                        offset: const Offset(0, 15)),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(36),
                                  child: Stack(children: [
                                    Image.asset(
                                      'assets/images/mavepizon_logo.jpeg',
                                      width: 140,
                                      height: 140,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned.fill(
                                      child: Transform.translate(
                                        offset: Offset(
                                            (_shimmerCtrl.value * 280) - 140,
                                            0),
                                        child: Container(
                                          width: 50,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.white.withOpacity(0.0),
                                                Colors.white.withOpacity(0.2),
                                                Colors.white.withOpacity(0.0),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    );
                  },
                ),

                const SizedBox(height: 36),

                AnimatedBuilder(
                  animation: _textCtrl,
                  builder: (_, __) {
                    return Column(children: [
                      FadeTransition(
                        opacity: _titleFade,
                        child: SlideTransition(
                          position: _titleSlide,
                          child: ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(colors: [
                              Color(0xFFFFFFFF),
                              Color(0xFFE0F2FE),
                              Color(0xFFFFFFFF),
                            ]).createShader(bounds),
                            child: const Text(
                              'MAVEPIZON',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 6,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      FadeTransition(
                        opacity: _subtitleFade,
                        child: SlideTransition(
                          position: _subtitleSlide,
                          child: Text(
                            'TECHNOLOGIES PVT LTD',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 4.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      FadeTransition(
                        opacity: _taglineFade,
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _GlowDivider(),
                              const SizedBox(width: 14),
                              Text(
                                'Put Efforts. Get More Benefits.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 11,
                                  letterSpacing: 0.8,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(width: 14),
                              _GlowDivider(),
                            ]),
                      ),
                    ]);
                  },
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 56, left: 0, right: 0,
            child: Column(children: [
              _BouncingDots(controller: _dotsCtrl),
              const SizedBox(height: 10),
              Text(
                'Initializing...',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    letterSpacing: 1.5),
              ),
            ]),
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  Color(0xFF0369A1),
                  Color(0xFF38BDF8),
                  Color(0xFF06B6D4),
                  Color(0xFF0369A1),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _GlowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.5),
          Colors.transparent,
        ]),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

class _FloatingParticle extends StatefulWidget {
  final int index;
  final Size size;
  const _FloatingParticle({required this.index, required this.size});

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late double _x, _y, _r, _dur;
  final _rng = math.Random();
  late List<Color> _colors;

  @override
  void initState() {
    super.initState();
    _colors = const [
      Color(0xFF38BDF8),
      Color(0xFF06B6D4),
      Color(0xFF22D3EE),
      Color(0xFF7DD3FC),
    ];
    _x = _rng.nextDouble();
    _y = _rng.nextDouble();
    _r = _rng.nextDouble() * 3 + 1.5;
    _dur = _rng.nextDouble() * 3000 + 2000;
    _ctrl = AnimationController(
        vsync: this, duration: Duration(milliseconds: _dur.toInt()))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _colors[widget.index % _colors.length];
    return Positioned(
      left: _x * widget.size.width,
      top: _y * widget.size.height,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Opacity(
          opacity: _ctrl.value * 0.6,
          child: Container(
            width: _r * 2,
            height: _r * 2,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.8), blurRadius: _r * 3)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _BouncingDots extends StatelessWidget {
  final AnimationController controller;
  const _BouncingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i * 0.33;
            final t = ((controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final bounce = math.sin(t * math.pi);
            return Transform.translate(
              offset: Offset(0, -bounce * 6),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2 + bounce * 0.7),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF38BDF8)
                            .withOpacity(bounce * 0.8),
                        blurRadius: 6)
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
