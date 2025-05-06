import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  MessageInputState createState() => MessageInputState();
}

class MessageInputState extends State<MessageInput> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    // Listen to focus changes
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        primaryFocus?.unfocus();
      }
    });
  }

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
              focusNode:
                  _focusNode, // Use the focus node to listen for focus changes
              autofocus: false,
              maxLength: 100,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              controller: widget.controller,
              decoration: InputDecoration(
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                hintText: 'Type your answer...',
                counterText: "",
                isDense: true,
                border: const OutlineInputBorder(),
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              onSubmitted: (_) => widget.onSend(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            elevation: 4.0,
            focusElevation: 4.0,
            hoverElevation: 4.0,
            highlightElevation: 4.0,
            onPressed: () {
              widget.onSend(); // Call the provided onSend callback
            },
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}
