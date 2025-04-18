import 'package:flutter/material.dart';

class MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const MessageComposer({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type your answer...',
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
          FloatingActionButton(
            elevation: 0,
            onPressed: onSend,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}