import 'package:flutter/material.dart';
import 'package:operation_veritas/l10n/app_localizations.dart';

class FooterInfo extends StatefulWidget {
  final List<int> dotStates;
  final int currentQuestionNumber;
  final int playerCount;
  final double dotSize;

  const FooterInfo({
    super.key,
    required this.dotStates,
    required this.playerCount,
    this.dotSize = 12.0, 
    required this.currentQuestionNumber,
  }) : assert(dotStates.length == 10, 'dotStates must contain exactly 10 elements');

  @override
  State<FooterInfo> createState() => _FooterInfoState();
}

class _FooterInfoState extends State<FooterInfo> with TickerProviderStateMixin {
  late List<int> _previousStates;
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _previousStates = [...widget.dotStates];
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(10, (i) => AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
      value: widget.dotStates[i].toDouble(),
    ));
  }

  @override
  void didUpdateWidget(FooterInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.dotStates != _previousStates) {
      for (int i = 0; i < 10; i++) {
        if (widget.dotStates[i] != _previousStates[i]) {
          widget.dotStates[i] == 1 
            ? _controllers[i].forward()
            : _controllers[i].reverse();
        }
      }
      _previousStates = [...widget.dotStates];
    }
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
    final isActive = widget.dotStates[index] == 1;
    final questionIndex = index + 1; // Convert to 1-based indexing
    final isPassed = questionIndex < widget.currentQuestionNumber;
    final isCurrent = questionIndex == widget.currentQuestionNumber;
    
    return AnimatedBuilder(
      animation: _controllers[index],
      builder: (context, child) {
        // Determine color and icon based on question state
        Color dotColor;
        IconData iconData;
        dotColor = isActive ? colorScheme.tertiary : colorScheme.tertiary;
        if (isPassed) {
          iconData = isActive ? Icons.check_circle : Icons.close;
        } else if (isCurrent) {
          iconData = isActive ? Icons.circle : Icons.question_mark_sharp;
        } else {
          iconData = isActive ? Icons.check_circle : Icons.circle_outlined;
        }

        Widget dotWidget = Icon(
          iconData,
          size: widget.dotSize,
          color: dotColor,
        );

        return Transform.scale(
          scale: 0.7 + (_controllers[index].value * 0.3),
          child: dotWidget,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final local = AppLocalizations.of(context)!;
    
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16),
      child: Row(
        children: [
          Text('${local.round} ', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(10, (i) => Expanded(child: _buildDot(i))),
            ),
          ),
          Container(
            width: 1,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
          Text(
            "${local.players} ${widget.playerCount}",
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
          ),
        ],
      ),
    );
  }
}