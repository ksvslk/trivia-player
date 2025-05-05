import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  // Add a flag to control keyboard behavior
  final bool keepKeyboardOpen;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.keepKeyboardOpen = true, // Default to keeping keyboard open
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  // Create the FocusNode as a class member so it persists across builds
  late final FocusNode _focusNode;
  bool _userActivatedKeyboard = false;
  
  @override
  void initState() {
    super.initState();
    // Configure the FocusNode to prevent auto-focus
    _focusNode = FocusNode();
    
    // Use a post-frame callback to ensure setup happens after initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start with keyboard hidden
      _focusNode.unfocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
  
  void _handleSend() {
    widget.onSend();
    
    // Only keep keyboard open if explicitly allowed AND user had activated it
    if (widget.keepKeyboardOpen && _userActivatedKeyboard) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
    }
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
            child: Focus(
              // This prevents the TextField from getting focus unless explicitly requested
              canRequestFocus: false,
              child: GestureDetector(
                // Handle tap explicitly to control when keyboard appears
                onTap: () {
                  _userActivatedKeyboard = true;
                  _focusNode.requestFocus();
                },
                child: TextField(
                  autofocus: false,
                  focusNode: _focusNode,
                  maxLength: 100,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  controller: widget.controller,
                  // Listen for focus changes to track user intent
                  onTap: () {
                    _userActivatedKeyboard = true;
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    hintText: 'Type your answer...',
                    counterText: "",
                    isDense: true,
                    border: const OutlineInputBorder(),
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            elevation: 0,
            onPressed: _handleSend,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}