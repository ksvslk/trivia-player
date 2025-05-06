import 'package:flutter/material.dart';

class SoundDialog extends StatelessWidget {
  const SoundDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Sound Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add your sound settings widgets here
          Text('Sound settings go here'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }
}