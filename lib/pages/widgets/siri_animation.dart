import 'package:flutter/material.dart';

class SiriCircleAnimation extends StatefulWidget {
  const SiriCircleAnimation({Key? key}) : super(key: key);

  @override
  _SiriCircleAnimationState createState() => _SiriCircleAnimationState();
}

class _SiriCircleAnimationState extends State<SiriCircleAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SiriCirclePainter(_controller, _pulseAnimation),
      child: Container(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class SiriCirclePainter extends CustomPainter {
  final Animation<double> animation;
  final Animation<double> pulseAnimation;

  SiriCirclePainter(this.animation, this.pulseAnimation)
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    double radius = size.width / 2;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius * animation.value * pulseAnimation.value,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
