import 'package:flutter/material.dart';
import 'package:operation_veritas/chat_page/message.dart';
import 'package:operation_veritas/chat_page/message_bubble.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MessageListView extends StatelessWidget {
  final List<Message> messages;
  final ScrollController scrollController;
  final String? currentUserId;
  final String Function(int) formatTimestamp;
  final Function(bool isVisible)? onLastQuestionVisibilityChanged;

  const MessageListView({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.currentUserId,
    required this.formatTimestamp,
    this.onLastQuestionVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    Message? lastQuestionMessage =
        messages.lastWhere((m) => m.messageType == "question");
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: 8.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - index - 1];
        final messageBefore = messages.length - index - 2 >= 0
            ? messages.elementAt(messages.length - index - 2)
            : message;
        final isCurrentUser = message.playerUid == currentUserId;

        // Check if this is the last question message
        final isLastQuestion = message.id == lastQuestionMessage.id;

        if (isLastQuestion) {
          return VisibilityDetector(
            key: Key('last-question-${message.id}'),
            onVisibilityChanged: (visibilityInfo) {
              final visiblePercentage = visibilityInfo.visibleFraction * 100;
              // Consider visible if at least 10% of the message is in view
              final isVisible = visiblePercentage > 10;
              print("isVisible for (${message.text}): $isVisible");
              if (!isVisible) {
                ScaffoldMessenger.of(context).showMaterialBanner(
                  MaterialBanner(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    content: Text(
                      message.text,
                      style: TextStyle(
                          color: colorScheme.onSurface,
                          fontFamily: 'Inter',
                          fontSize: 12),
                    ),
                    backgroundColor: colorScheme.surfaceContainerLow,
                    actions: const <Widget>[
                      SizedBox.shrink(), // No dismiss button
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              }
            },
            child: MessageBubble(
              message: message,
              messageBefore: messageBefore,
              isCurrentUser: isCurrentUser,
              playerId: currentUserId,
              formatTimestamp: formatTimestamp,
            ),
          );
        }

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
