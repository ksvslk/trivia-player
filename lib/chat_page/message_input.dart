import 'dart:ui';

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
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> with WidgetsBindingObserver {

   @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = PlatformDispatcher.instance.views.first.viewInsets.bottom;
    if (bottomInset <= 0) FocusScope.of(context).nextFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

 
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Expanded(child:
             TextFormField(
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
              onFieldSubmitted: (_) => widget.onSend(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            elevation: 4.0,
            focusElevation: 4.0,
            hoverElevation: 4.0,
            highlightElevation: 4.0,
            onPressed: widget.onSend,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
