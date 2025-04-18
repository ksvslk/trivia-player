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
      itemCount: messages.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final message = messages[messages.length - index - 1];
        final isCurrentUser = message.playerUid == currentUserId;

        return MessageBubble(
          message: message,
          isCurrentUser: isCurrentUser,
          formatTimestamp: formatTimestamp,
        );
      },
    );
  }
}