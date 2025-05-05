import 'dart:async';

import 'package:flutter/material.dart';
import 'package:operation_veritas/chat_page/message.dart';

class QuestionTimeProgress extends StatefulWidget {
  final Message message;

  const QuestionTimeProgress({
    super.key,
    required this.message,
  });

  @override
  State<QuestionTimeProgress> createState() => _QuestionTimeProgressState();
}

class _QuestionTimeProgressState extends State<QuestionTimeProgress> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
  }

  @override
  void didUpdateWidget(covariant QuestionTimeProgress oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.message != oldWidget.message) {
      _controller.dispose();
      _timer?.cancel();
      _timer = null;

      _initializeTimer();
    }
  }

  void _initializeTimer() {
    final totalDuration = widget.message.questionEndTime - widget.message.questionStartTime;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final elapsedTime = currentTime - widget.message.questionStartTime;
    final remainingTime = (totalDuration - elapsedTime).clamp(0, totalDuration);

    if (remainingTime <= 0) {
         _controller = AnimationController(
             vsync: this,
             duration: const Duration(milliseconds: 1),
         );
          _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);
         return;
    }

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: remainingTime.toInt()),
    );

     final startValue = totalDuration > 0 ? (remainingTime / totalDuration).clamp(0.0, 1.0) : 0.0;

    _animation = Tween<double>(
      begin: startValue,
      end: 0.0,
    ).animate(_controller);

    _controller.forward();

    _timer = Timer(Duration(milliseconds: remainingTime.toInt() + 500), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isDarkTheme = colorScheme.brightness == Brightness.dark;
    final progressColor = isDarkTheme ? colorScheme.primary : colorScheme.primaryContainer;
    final progressBackgroundColor = isDarkTheme ? colorScheme.surfaceContainerHighest : colorScheme.inverseSurface;

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final isExpired = currentTime > widget.message.questionEndTime;

    if (isExpired) {
      return LinearProgressIndicator(
        value: 0.0,
        backgroundColor: progressBackgroundColor,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
        minHeight: 5,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value;
        final displayValue = value.isFinite ? value : 0.0;
        final color = displayValue > 0.5 ? progressColor : displayValue > 0.25 ? Colors.orange : Colors.red;

        return LinearProgressIndicator(
          value: displayValue,
          backgroundColor: progressBackgroundColor,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 5,
        );
      },
    );
  }
}