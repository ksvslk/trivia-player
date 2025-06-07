import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SendingButton extends StatefulWidget {
  final VoidCallback onSend;

  const SendingButton({
    super.key,
    required this.onSend,
  });

  @override
  _SendingButtonState createState() => _SendingButtonState();
}

class _SendingButtonState extends State<SendingButton> {
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {

    return FloatingActionButton.small(
      elevation: 1.0,
      focusElevation: 1.0,
      hoverElevation: 1.0,
      highlightElevation: 1.0,
      onPressed: _isSending
          ? null
          : () async {
              setState(() {
                _isSending = true;
              });
              widget.onSend();
              await Future.delayed(const Duration(milliseconds: 500));
              setState(() {
                _isSending = false; // Reset to the send icon
              });
            },
      child: _isSending
          ? const Icon(FontAwesomeIcons.hand)
          : const Icon(Icons.send),
    );
  }
}