import 'package:flutter/material.dart';
import 'package:operation_veritas/change_notifier/blocked_players.dart';
import 'package:operation_veritas/chat_page/message.dart';
import 'package:operation_veritas/extensions.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageAvatar extends StatefulWidget {
  final Color? avatarColor;
  final Message message;
  final bool isCurrentUser;

  const MessageAvatar(
      {super.key,
      required this.avatarColor,
      required this.message,
      required this.isCurrentUser});

  @override
  State<MessageAvatar> createState() => _MessageAvatarState();
}

class _MessageAvatarState extends State<MessageAvatar> {
  String _getAvatarText() {
    if (widget.message.name.isNotEmpty) {
      return widget.message.name.substring(0, 1).toUpperCase();
    } else {
      return "?";
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockedPlayers = context.read<BlockedPlayers>();

    return MenuAnchor(
      style: MenuStyle(
          visualDensity: VisualDensity.compact,
          elevation: WidgetStatePropertyAll(5.0)),
      menuChildren: <Widget>[
        MenuItemButton(
            onPressed: () {
              blockedPlayers.add(widget.message.playerUid, widget.message.name);
            },
            child: const Text('Block')),
        MenuItemButton(
          onPressed: () async {
            final subject =
                "Ref. ${widget.message.playerUid.characters.takeLast(10)}";
            final Uri emailUri = Uri(
              scheme: 'mailto',
              path: 'indrek@indest.ee',
              query:
                  'subject=$subject&body=Share your concerns about ${widget.message.name} below.',
            );
            if (await canLaunchUrl(emailUri)) {
              await launchUrl(emailUri);
            } else {}
          },
          child: const Text('Blow the whistle'),
        )
      ],
      builder: (_, MenuController controller, Widget? child) {
        return InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: widget.message.isBot || widget.isCurrentUser
              ? null
              : () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
          child: CircleAvatar(
            radius: 15,
            backgroundColor: widget.avatarColor,
            child: widget.message.isBot
                ? ImageIcon(
                    AssetImage(widget.message.messageType == 'question'
                        ? "assets/images/avatar_question.png"
                        : "assets/images/avatar_question.png"),
                    color: widget.avatarColor?.contrastingTextColor,
                  )
                : (widget.message.photoUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          widget.message.photoUrl,
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        _getAvatarText(),
                        style: TextStyle(
                          fontFamily: 'WorkSans',
                          fontSize: widget.message.isBot ? 18 : 16,
                          color: widget.avatarColor?.contrastingTextColor,
                        ),
                      )),
          ),
        );
      },
    );
  }
}
