import 'package:flutter/material.dart';
import 'package:operation_veritas/chat_page/message.dart';
import 'package:operation_veritas/chat_page/message_bubble.dart';
import 'package:operation_veritas/trivia_service/message_visibility.dart';
import 'package:operation_veritas/trivia_service/trivia_service.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MessageListView extends StatelessWidget {
  final List<Message> messages;
  final ScrollController scrollController;
  final String? currentUserId;
  final Message? activeQuestion;
  final String Function(int) formatTimestamp;

  const MessageListView(
      {super.key,
      required this.messages,
      required this.scrollController,
      required this.currentUserId,
      required this.activeQuestion,
      required this.formatTimestamp});

  @override
  Widget build(BuildContext context) {

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - index - 1];
        final messageBefore = messages.length - index - 2 >= 0
            ? messages.elementAt(messages.length - index - 2)
            : message;
        final isCurrentUser = message.playerUid == currentUserId;
        final isLastQuestion = activeQuestion?.id == message.id;

        if (isLastQuestion) {
          return VisibilityDetector(
            key: Key('last-question-${message.id}'),
            onVisibilityChanged: (visibilityInfo) {
              final visiblePercentage = visibilityInfo.visibleFraction * 100;
              // Consider visible if at least 10% of the message is in view
              final isVisible = visiblePercentage > 75;
              context.read<BannerMessageVisibility>().setVisibility(isVisible);
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
