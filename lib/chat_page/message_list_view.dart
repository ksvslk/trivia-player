import 'package:flutter/material.dart';
import 'package:operation_veritas/chat_page/message.dart';
import 'package:operation_veritas/chat_page/message_bubble.dart';

class MessageListView extends StatelessWidget {
  final List<Message> messages;
  final ScrollController scrollController;
  final String? currentUserId;
  final String Function(int) formatTimestamp;

  const MessageListView({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.currentUserId,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      reverse: true,
      shrinkWrap: true,
      padding: EdgeInsets.only(top: 8.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - index - 1];
        final messageBefore = messages.length - index - 2 >= 0 ? messages.elementAt(messages.length - index - 2) : message;
        final isCurrentUser = message.playerUid == currentUserId;

        return MessageBubble(
          message: message,
          messageBefore: messageBefore,
          isCurrentUser: isCurrentUser,
          playerId: currentUserId,
          formatTimestamp: formatTimestamp,
        );
      },
    );
  }
}