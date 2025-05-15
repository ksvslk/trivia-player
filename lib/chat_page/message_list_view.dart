import 'package:flutter/material.dart';
import 'package:operation_veritas/change_notifier/blocked_players.dart';
import 'package:operation_veritas/chat_page/message.dart';
import 'package:operation_veritas/chat_page/message_bubble.dart';
import 'package:operation_veritas/change_notifier/banner_message_visibility.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MessageListView extends StatelessWidget {
  final List<Message> originalMessages;
  final ScrollController scrollController;
  final String? currentUserId;
  final Message? activeQuestion;
  final String Function(int) formatTimestamp;

  const MessageListView(
      {super.key,
      required this.originalMessages,
      required this.scrollController,
      required this.currentUserId,
      required this.activeQuestion,
      required this.formatTimestamp});

  @override
  Widget build(BuildContext context) {
    return Consumer<BlockedPlayers>(builder:
        (BuildContext context, BlockedPlayers blockedPlayers, Widget? child) {
      final messages = originalMessages
          .where(
              (el) => !blockedPlayers.blockedPlayers.containsKey(el.playerUid))
          .toList();
      final colorScheme = Theme.of(context).colorScheme;
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
                  final visiblePercentage =
                      visibilityInfo.visibleFraction * 100;
                  final isVisible = visiblePercentage > 75;
                  context
                      .read<BannerMessageVisibility>()
                      .setQuestionVisibilityOnScreen(isVisible);
                },
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      colorScheme.tertiaryContainer.withValues(alpha: 0.1),
                      colorScheme.primary.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  blendMode: BlendMode.srcATop,
                  child: MessageBubble(
                    message: message,
                    messageBefore: messageBefore,
                    isCurrentUser: isCurrentUser,
                    playerId: currentUserId,
                    formatTimestamp: formatTimestamp,
                  ),
                ));
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            context
                .read<BannerMessageVisibility>()
                .setIsRoundBreak(activeQuestion == null);
          });

          return MessageBubble(
            message: message,
            messageBefore: messageBefore,
            isCurrentUser: isCurrentUser,
            playerId: currentUserId,
            formatTimestamp: formatTimestamp,
          );
        },
      );
    });
  }
}
