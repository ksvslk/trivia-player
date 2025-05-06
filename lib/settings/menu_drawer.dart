import 'package:flutter/material.dart';
import 'package:operation_veritas/settings/blocked_players_dialog.dart';
import 'package:operation_veritas/settings/credits_dialog.dart';
import 'package:operation_veritas/settings/sound_dialog.dart';

class MenuDrawer extends StatelessWidget {
  final GlobalKey<NavigatorState> parentNavigatorKey;

  const MenuDrawer({
    super.key,
    required this.parentNavigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ListTile(
              title: const Text('Blocked Users'),
              onTap: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (_) => const BlockedPlayersDialog(),
                );
              },
            ),
            ListTile(
              title: const Text('Sound'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: parentNavigatorKey.currentContext!,
                  builder: (_) => const SoundDialog(),
                );
              },
            ),
            ListTile(
              title: const Text('Credits'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: parentNavigatorKey.currentContext!,
                  builder: (_) => const CreditsDialog(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
