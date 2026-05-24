import 'package:flutter/material.dart';
import 'dart:async';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.8,
          curve: Curves.easeOut),
    ));

    _scaleAnim =
        Tween<double>(begin: 0.88, end: 1.0)
            .animate(CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.8,
              curve: Curves.easeOut),
        ));

    // Start fade in
    _ctrl.forward();

    // Navigate after logo has settled
    Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
          const AuthWrapper(),
          transitionsBuilder:
              (_, anim, __, child) =>
              FadeTransition(
                  opacity: anim, child: child),
          transitionDuration:
          const Duration(milliseconds: 700),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(children: [

        // ── Full screen grid ─────────────────
        Positioned.fill(
          child:
          CustomPaint(painter: _GridPainter()),
        ),

        // ── Lime glow top right ───────────────
        Positioned(
          top: -140, right: -140,
          child: Container(
            width: 420, height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFFDEFF6E)
                    .withOpacity(0.12),
                Colors.transparent,
              ]),
            ),
          ),
        ),

        // ── Lime glow bottom left ─────────────
        Positioned(
          bottom: -80, left: -100,
          child: Container(
            width: 300, height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFFDEFF6E)
                    .withOpacity(0.06),
                Colors.transparent,
              ]),
            ),
          ),
        ),

        // ── Animated logo ─────────────────────
        Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Opacity(
              opacity: _fadeAnim.value,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: Padding(
                  padding: const EdgeInsets
                      .symmetric(horizontal: 48),
                  child: Image.asset(
                    'assets/splash/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Subtle version tag ────────────────
        Positioned(
          bottom:
          MediaQuery.of(context).padding.bottom +
              28,
          left: 0, right: 0,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Opacity(
              opacity: (_fadeAnim.value * 0.4)
                  .clamp(0.0, 0.4),
              child: Center(
                child: Text(
                  'Find your perfect space.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white
                        .withOpacity(0.3),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
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

// ── Grid painter ──────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
      const Color(0xFFDEFF6E).withOpacity(0.04)
      ..strokeWidth = 1;
    const spacing = 40.0;
    for (double x = 0;
    x < size.width;
    x += spacing) {
      canvas.drawLine(
          Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0;
    y < size.height;
    y += spacing) {
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) =>
      false;
}