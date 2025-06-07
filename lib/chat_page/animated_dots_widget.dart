import 'package:flutter/material.dart';

class AnimatedDotsWidget extends StatefulWidget {
  // Change activedots to dotStates, which is a list of integers
  final List<int> dotStates; // e.g., [1, 0, 1, 0, 0, 0, 0, 0, 0, 0]
  final double dotSize;

  const AnimatedDotsWidget({
    super.key,
    required this.dotStates,
    this.dotSize = 12.0,
  }) : assert(dotStates.length == 10, 'dotStates must contain exactly 10 elements');
      // We no longer need the activedots >= 0 check, as it's an array now.
      // We can add more specific assertions if needed for the content of the array (e.g., all 0s or 1s).

  @override
  State<AnimatedDotsWidget> createState() => _AnimatedDotsWidgetState();
}

class _AnimatedDotsWidgetState extends State<AnimatedDotsWidget>
    with TickerProviderStateMixin {
  // Store the previous state to compare in didUpdateWidget
  late List<int> _previousDotStates;
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _previousDotStates = List.from(widget.dotStates); // Make a mutable copy
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      10,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      ),
    );

    _scaleAnimations = _controllers
        .map(
          (controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.elasticOut),
          ),
        )
        .toList();

    // Initialize dot states based on the initial dotStates array
    // Set controller value to 1.0 for initially active dots (state 1)
    for (int i = 0; i < widget.dotStates.length; i++) {
      if (widget.dotStates[i] == 1) {
        _controllers[i].value = 1.0;
      } else {
        _controllers[i].value = 0.0; // Ensure inactive dots start at 0
      }
    }
  }

  @override
  void didUpdateWidget(AnimatedDotsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only proceed if the new dotStates list is actually different
    if (!_listEquals(widget.dotStates, _previousDotStates)) {
      int? lastActivatedIndex;

      // Iterate through the dotStates to find changes and identify the last activated dot
      for (int i = 0; i < widget.dotStates.length; i++) {
        // If a dot was off (0) and is now on (1)
        if (_previousDotStates[i] == 0 && widget.dotStates[i] == 1) {
          lastActivatedIndex = i; // This is a candidate for the last activated dot
          // No immediate animation here; we'll animate after the loop to get the *last* one
        }
        // If a dot was on (1) and is now off (0)
        else if (_previousDotStates[i] == 1 && widget.dotStates[i] == 0) {
          _animatedotOff(i);
        }
        // If a dot was already on (1) and remains on (1)
        // Ensure its animation is complete (forward) in case it was reversed for some reason
        else if (widget.dotStates[i] == 1 && _controllers[i].value < 1.0) {
          _controllers[i].forward(); // Ensure it's fully "on"
        }
      }

      // Animate only the very last dot that turned on
      if (lastActivatedIndex != null) {
        _animatedotOn(lastActivatedIndex);
      }

      // Update the previous state for the next comparison
      _previousDotStates = List.from(widget.dotStates);
    }
  }

  // Helper to compare lists by value
  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }


  void _animatedotOn(int index) {
    _controllers[index].forward();
  }

  void _animatedotOff(int index) {
    _controllers[index].reverse();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildDot(int index) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controllers[index],
      builder: (context, child) {
        // The scale logic remains the same
        return Transform.scale(
          scale: 0.7 + (_scaleAnimations[index].value * 0.3),
          child: Icon(
            // Now, we check widget.dotStates[index] to determine the icon
            widget.dotStates[index] == 1 ? Icons.circle : Icons.circle_outlined,
            size: widget.dotSize,
            color: widget.dotStates[index] == 1
                ? colorScheme.onSecondaryContainer
                : colorScheme.secondaryContainer,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          10,
          (index) => Expanded(child: _buildDot(index)),
        ),
      ),
    );
  }
}