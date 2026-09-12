import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';

/// Splash screen for ASKESIS — Art Fest '26
/// Drop this file into lib/screens/splash_screen.dart
/// and set it as the `home:` of your MaterialApp (or push it first,
/// then navigate to your real home screen after init is done).
class SplashScreen extends StatefulWidget {
  final Widget? nextScreen;
  final Duration minDisplayDuration;

  const SplashScreen({
    super.key,
    this.nextScreen,
    this.minDisplayDuration = const Duration(seconds: 2),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ---- Brand palette (pulled from the Askesis logo/theme) ----
  static const Color bgCream = Color(0xFFF3EBDD);
  static const Color maroon = Color(0xFF8C2A2A);
  static const Color darkWood = Color(0xFF2E2A26);
  static const Color mustard = Color(0xFFD9A62E);
  static const Color olive = Color(0xFF7A8B3F);
  static const Color forest = Color(0xFF3F5A3D);

  late final AnimationController _fadeController;
  late final AnimationController _dotsController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(widget.minDisplayDuration);
    if (!mounted) return;
    if (widget.nextScreen != null) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, anim, secondaryAnimation) => widget.nextScreen!,
          transitionsBuilder: (context, anim, secondaryAnimation, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } else {
      context.go('/public');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Small gem accent above wordmark
                  const _GemAccent(color: maroon),
                  const SizedBox(height: 12),

                  // Wordmark: ASK (maroon) + ESIS (dark wood tone)
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.w900,
                        fontSize: 52,
                        letterSpacing: 1,
                        height: 1,
                      ),
                      children: [
                        TextSpan(text: 'ASK', style: TextStyle(color: maroon)),
                        TextSpan(text: 'ESIS', style: TextStyle(color: darkWood)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'A R T   F E S T   \u201826',
                    style: TextStyle(
                      color: darkWood.withValues(alpha: 0.75),
                      fontSize: 13,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Loading animation: 4 brand-colored dots cycling
                  AnimatedBuilder(
                    animation: _dotsController,
                    builder: (context, _) {
                      const colors = [maroon, mustard, olive, forest];
                      return SizedBox(
                        width: 72,
                        height: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(colors.length, (i) {
                            final t = (_dotsController.value - (i * 0.15)) % 1.0;
                            final bounce = math.sin(t * math.pi).clamp(0.0, 1.0);
                            return Transform.translate(
                              offset: Offset(0, -6 * bounce),
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: colors[i],
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small diamond/gem shape echoing the accent above the "i" in the logo.
class _GemAccent extends StatelessWidget {
  final Color color;
  const _GemAccent({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 26),
      painter: _GemPainter(color: color),
    );
  }
}

class _GemPainter extends CustomPainter {
  final Color color;
  _GemPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height * 0.55)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height * 0.55)
      ..close();
    canvas.drawPath(path, paint);

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.15),
      Offset(size.width / 2, size.height * 0.85),
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant _GemPainter oldDelegate) => false;
}
