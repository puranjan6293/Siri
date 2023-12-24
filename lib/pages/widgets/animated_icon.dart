import 'package:flutter/material.dart';

class AnimatedMicIcon extends StatefulWidget {
  final bool isListening;

  const AnimatedMicIcon({Key? key, required this.isListening})
      : super(key: key);

  @override
  _AnimatedMicIconState createState() => _AnimatedMicIconState();
}

class _AnimatedMicIconState extends State<AnimatedMicIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = Tween<double>(begin: 1.0, end: 1.9).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant AnimatedMicIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(0.2), // Adjust opacity as needed
            ),
            child: const Icon(
              Icons.mic,
              size: 30.0,
              color: Colors.cyan,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
