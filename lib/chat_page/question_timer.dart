import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class QuestionTimer extends StatefulWidget {
  // The range for color transition (values between 0 and 1)
  final RangeValues colorTransitionRange;

  const QuestionTimer({
    super.key,
    this.colorTransitionRange = const RangeValues(0.4, 0.6),
  });

  @override
  State<QuestionTimer> createState() => _QuestionTimerState();
}

class _QuestionTimerState extends State<QuestionTimer> {
  Map<String, dynamic>? _lastMessage;
  Timer? _timer;
  int _remainingSeconds = 0;
  int _remainingMilliseconds = 0;
  final DatabaseReference _messagesRef = FirebaseDatabase.instance.ref().child('trivia_messages');

  @override
  void initState() {
    super.initState();
    _setupMessageListener();
  }

  void _setupMessageListener() {
    _messagesRef.limitToLast(1).onChildAdded.listen((event) {
      if (event.snapshot.value == null) return;

      try {
        final message = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        // Check if this is a question message with timing information
        if (message['isBot'] == true && 
            message['messageType'] == 'question' &&
            message['questionStartTime'] != null && 
            message['questionEndTime'] != null) {
          setState(() {
            _lastMessage = message;
          });
          _startTimer();
        }
      } catch (e) {
        debugPrint('Error parsing last message: $e');
      }
    });
  }

  void _startTimer() {
    // Cancel existing timer if any
    _timer?.cancel();

    // Update timer every 50ms for smooth display
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final endTime = _lastMessage!['questionEndTime'] as int;
      
      // Calculate milliseconds remaining
      int remainingMs = (endTime - currentTime).clamp(0, double.infinity).toInt();
      
      setState(() {
        _remainingSeconds = remainingMs ~/ 1000;
        _remainingMilliseconds = remainingMs % 1000;
      });

      // Stop timer when time is up
      if (remainingMs <= 0) {
        _timer?.cancel();
        setState(() {
          _lastMessage = null;
        });
      }
    });
  }

  // Convert hex to RGB
  Color _hexToColor(String hexCode) {
    try {
      final hexString = hexCode.replaceAll('#', '');
      if (hexString.length == 6) {
        final int r = int.parse(hexString.substring(0, 2), radix: 16);
        final int g = int.parse(hexString.substring(2, 4), radix: 16);
        final int b = int.parse(hexString.substring(4, 6), radix: 16);
        return Color.fromRGBO(r, g, b, 1);
      }
      return Colors.white; // Default
    } catch (e) {
      return Colors.white; // Default on error
    }
  }

  // Interpolate between two colors
  Color _interpolateColor(Color color1, Color color2, double factor) {
    int r = (color1.red + (color2.red - color1.red) * factor).round();
    int g = (color1.green + (color2.green - color1.green) * factor).round();
    int b = (color1.blue + (color2.blue - color1.blue) * factor).round();
    return Color.fromRGBO(r, g, b, 1);
  }

  // Calculate progress data for rendering
  Map<String, dynamic> _getProgressData() {
    if (_lastMessage == null) {
      return {'progress': 0.0, 'showGradient': false};
    }

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final startTime = _lastMessage!['questionStartTime'] as int;
    final endTime = _lastMessage!['questionEndTime'] as int;
    final totalDuration = endTime - startTime;
    final elapsed = currentTime - startTime;

    // Invert progress to go from filled to empty
    final progress = (1.0 - (elapsed / totalDuration)).clamp(0.0, 1.0);
    
    // Show gradient when less than 50% time remains
    final showGradient = progress <= 0.5;

    return {'progress': progress, 'showGradient': showGradient};
  }

  // Get text color based on progress with gradual transition
  Color _getTextColor(ColorScheme colorScheme) {
    if (_lastMessage == null) return colorScheme.onPrimary;
    
    final progressData = _getProgressData();
    final progress = progressData['progress'] as double;
    
    final min = widget.colorTransitionRange.start;
    final max = widget.colorTransitionRange.end;
    
    // Before transition range: use onPrimary
    if (progress > max) {
      return colorScheme.onPrimary;
    }
    
    // After transition range: use onPrimaryContainer
    if (progress < min) {
      return colorScheme.onPrimaryContainer;
    }
    
    // During transition: smoothly interpolate between colors
    final transitionProgress = (progress - min) / (max - min);
    return _interpolateColor(
      colorScheme.onPrimaryContainer, 
      colorScheme.onPrimary, 
      transitionProgress
    );
  }

  // Format milliseconds to display only specified places
  String _formatMilliseconds(int ms, [int places = 1]) {
    final padded = ms.toString().padLeft(3, '0');
    return padded.substring(0, places);
  }

  @override
  Widget build(BuildContext context) {
    // If no question message is available, return an empty container
    if (_lastMessage == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final progressData = _getProgressData();
    final progress = progressData['progress'] as double;
    final showGradient = progressData['showGradient'] as bool;

    return Stack(
        children: [
          // Progress bar container
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
            ),
          ),
          
          // Progress fill
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * progress,
            child: Container(
              decoration: BoxDecoration(
                color: showGradient 
                  ? Colors.transparent
                  : colorScheme.onTertiaryContainer,
              ),
              child: showGradient
                  ? Stack(
                      children: [
                        // Base gradient color
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: colorScheme.onTertiaryContainer,
                        ),
                        // Gradient overlay
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: MediaQuery.of(context).size.width,
                          child: Opacity(
                            opacity: (0.5 - progress) * 2.0,
                            child: Container(
                              color: colorScheme.tertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
          
          /*
          // Time text
          Positioned.fill(
            child: Center(
              child: Text(
                '${_remainingSeconds.toString().padLeft(2, '0')}.${_formatMilliseconds(_remainingMilliseconds, 2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: _getTextColor(colorScheme),
                ),
              ),
            ),
          ),
*/
        ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}