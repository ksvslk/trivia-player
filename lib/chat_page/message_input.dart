import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:operation_veritas/chat_page/sending_button.dart';
import 'package:operation_veritas/l10n/app_localizations.dart';

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
    final local = AppLocalizations.of(context)!;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
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
                hintText: local.typeYourAnswer,
                counterText: "",
                isDense: true,
                border: const OutlineInputBorder(),
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              onFieldSubmitted: (_) => widget.onSend,
            ),
          ),
          const SizedBox(width: 8),
          SendingButton(onSend: widget.onSend)
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
