import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              maxLength: 100,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              controller: controller,
              decoration: InputDecoration(
                  filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest, // Use the color from the current theme's ColorScheme
                hintText: 'Type your answer...',
                counterText: "",
                isDense: true,  // Add this line
                border: const OutlineInputBorder(),
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            elevation: 0,
            onPressed: onSend,
            child: const Icon(
              Icons.send
              ),
          ),
        ],
      ),
    );
  }
}