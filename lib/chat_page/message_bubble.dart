import 'package:flutter/material.dart';
import 'package:operation_veritas/chat_page/message.dart';
import 'package:operation_veritas/chat_page/message_avatar.dart';
import 'package:operation_veritas/extensions.dart';
import 'package:operation_veritas/l10n/app_localizations.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final Message messageBefore;
  final bool isCurrentUser;
  final String? playerId;
  final String Function(int) formatTimestamp;

  const MessageBubble({
    super.key,
    required this.message,
    required this.messageBefore,
    required this.isCurrentUser,
    required this.playerId,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final local = AppLocalizations.of(context)!;

    final lastMessageWasSameUser = (message.isBot && messageBefore.isBot) ||
        (message.playerUid == messageBefore.playerUid);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16.0, lastMessageWasSameUser ? 1.0 : 4.0, 16.0, 1.0),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isCurrentUser
            ? _buildMessageWithAvatar(colorScheme, local)
            : _buildMessageWithAvatar(colorScheme, local).reversed.toList(),
      ),
    );
  }

  List<Widget> _buildMessageWithAvatar(ColorScheme colorScheme, AppLocalizations local) {
    // Determine text colors based on message type
    final textColor = (message.messageType == 'answer' &&
            message.questionWinnerUid == playerId)
        ? colorScheme.onSurface
        : (message.isBot
            ? colorScheme.onSurface
            : (isCurrentUser
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface));

    // Determine bubble background color
    final bubbleColor = (message.messageType == 'answer' &&
            message.questionWinnerUid == playerId)
        ? colorScheme.surfaceContainerLow
        : (message.isBot
            ? colorScheme.surfaceContainerHigh
            : (isCurrentUser
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerLow));

    // Determine avatar color
    final avatarColor = message.isBot
        ? colorScheme.tertiaryContainer
        : (isCurrentUser
            ? colorScheme.primary
            : colorScheme.secondary.pastelColorFromName(message.name));

    return [
      // Message bubble
      Flexible(
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 60,
            maxWidth: 290,
          ),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: textColor,
                ),
              ),
              _buildBottomContent(colorScheme, local),
            ],
          ),
        ),
      ),
      const SizedBox(width: 4),
      MessageAvatar(
          message: message,
          avatarColor: avatarColor,
          isCurrentUser: isCurrentUser,
          isWinnerMessage: message.questionWinnerUid == playerId &&
              message.questionWinnerUid.isNotEmpty)
    ];
  }

  // Helper method to build the bottom content (badge or name)
  Widget _buildBottomContent(ColorScheme colorScheme, AppLocalizations local) {
    if (message.isBot && message.badgeText.isNotEmpty) {
      // Badge for bot messages
      return Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: message.messageType == 'question'
              ? colorScheme.tertiary
              : colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          message.badgeText,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            fontFamily: 'WorkSans',
            color: message.messageType == 'question'
                ? colorScheme.onTertiary
                : colorScheme.onTertiaryContainer,
          ),
        ),
      );
    } else {
      // Name or host text
      return Text(
        !message.isBot
            ? message.name
            : (message.badgeText.isEmpty ? local.host : ""),
        style: TextStyle(
          fontSize: 10,
          color: (message.messageType == 'answer' &&
                  message.questionWinnerUid == playerId)
              ? colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
              : isCurrentUser
                  ? colorScheme.onPrimaryContainer.withValues(alpha: 0.3)
                  : colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      );
    }
  }
}
