import 'package:flutter/material.dart';

class PulsingLogoAnimation extends StatefulWidget {
  final double size;
  final String imagePath;

  const PulsingLogoAnimation({
    Key? key,
    this.size = 150.0,
    required this.imagePath,
  }) : super(key: key);

  @override
  State<PulsingLogoAnimation> createState() => _PulsingLogoAnimationState();
}

class _PulsingLogoAnimationState extends State<PulsingLogoAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0, // Neutral start
      end: 1.05,  // Gentle pulse out
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.85, // Start slightly faded
      end: 1.0,   // End fully opaque
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut, // Use the same curve to stay in sync
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Image.asset(
          widget.imagePath,
          width: widget.size,
          height: widget.size,
        ),
      ),
    );
  }
}