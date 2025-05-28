
import 'package:flutter/material.dart';
import 'package:operation_veritas/l10n/app_localizations.dart';

class CreditsDialog extends StatelessWidget {
  const CreditsDialog({super.key});

  @override
  Widget build(BuildContext context) {

    final local = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(local.credits),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Indest'),
          SizedBox(height: 8),
          Text('Version 1.0.0'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(local.close),
        ),
      ],
    );
  }
}