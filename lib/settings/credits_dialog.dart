
import 'package:flutter/material.dart';

class CreditsDialog extends StatelessWidget {
  const CreditsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Credits'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('App developed by YourName'),
          SizedBox(height: 8),
          Text('Version 1.0.0'),
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