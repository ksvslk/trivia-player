import 'package:flutter/material.dart';
import 'package:operation_veritas/change_notifier/blocked_players.dart';
import 'package:provider/provider.dart';

class BlockedPlayersDialog extends StatelessWidget {
  const BlockedPlayersDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BlockedPlayers>(
      builder: (context, blockedPlayers, child) {
        return AlertDialog(
          title: const Text('Blocked Players'),
          content: blockedPlayers.blockedPlayers.isEmpty
              ? const Text('No players are currently blocked.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: blockedPlayers.blockedPlayers.length,
                  itemBuilder: (context, index) {
                    String uid =
                        blockedPlayers.blockedPlayers.keys.elementAt(index);
                    String name =
                        blockedPlayers.blockedPlayers[uid] ?? "Player";
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
                      title: Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                        ),
                      ),
                      trailing: IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          blockedPlayers.remove(uid);
                        },
                      ),
                    );
                  },
                ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
