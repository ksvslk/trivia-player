import 'package:flutter/material.dart';
import 'package:operation_veritas/change_notifier/blocked_players.dart';
import 'package:operation_veritas/chat_page/message.dart';
import 'package:operation_veritas/chat_page/message_bubble.dart';
import 'package:operation_veritas/change_notifier/banner_message_visibility.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MessageListView extends StatefulWidget {
  final List<Message> originalMessages;
  final ScrollController scrollController;
  final String? currentUserId;
  final Message? activeQuestion;
  final String Function(int) formatTimestamp;

  const MessageListView({
    super.key,
    required this.originalMessages,
    required this.scrollController,
    required this.currentUserId,
    required this.activeQuestion,
    required this.formatTimestamp,
  });

  @override
  State<MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends State<MessageListView>
    with TickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  // This now tracks the ID of the message that is intended to be animated.
  String? _lastMessageIdToAnimate;
  // No longer need _hasAnimated, the controller's state is sufficient.

  @override
  void initState() {
    super.initState();
    
    // Initialize _lastMessageIdToAnimate with the last message on initial build.
    // This prevents the first message from animating when the view appears.
    if (widget.originalMessages.isNotEmpty) {
      _lastMessageIdToAnimate = widget.originalMessages.last.id;
    }
    
    _initializeAnimation();
  }

  void _initializeAnimation() {
    _animationController?.dispose();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(MessageListView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newMessages = widget.originalMessages;
    final oldMessages = oldWidget.originalMessages;

    // We only care about one condition for animation: a new message has been added.
    // This is determined by the list growing.
    if (newMessages.isNotEmpty && newMessages.length > oldMessages.length) {
      final newLastMessage = newMessages.last;

      // Update the ID of the message we intend to animate and play the animation.
      _lastMessageIdToAnimate = newLastMessage.id;
      _animationController?.forward(from: 0.0); // Reset and play
    }
    
    // The problematic `else if` block has been removed.
    // The widget's internal state (_lastMessageIdToAnimate) is no longer
    // incorrectly modified when the list shrinks or changes in other ways.
  }

  Widget _buildMessageBubble({
    required Message message,
    required Message messageBefore,
    required bool isCurrentUser,
    required bool isLastQuestion,
    required ColorScheme colorScheme,
  }) {
    Widget messageBubble = MessageBubble(
      message: message,
      messageBefore: messageBefore,
      isCurrentUser: isCurrentUser,
      playerId: widget.currentUserId,
      formatTimestamp: widget.formatTimestamp,
    );
    
    // Determine if this specific message bubble should be animated.
    // It should only animate if its ID matches the target ID and the animation is running.
    final bool shouldAnimate = message.id == _lastMessageIdToAnimate;

    // Apply animation only to the newest message that hasn't been animated yet
    if (shouldAnimate &&
        _animationController != null &&
        _fadeAnimation != null) {
      messageBubble = AnimatedBuilder(
        animation: _animationController!,
        builder: (context, child) {
          // Check if controller is still active before building transform
          if (!_animationController!.isAnimating && !_animationController!.isCompleted) {
            return child!;
          }
          return Transform.scale(
            scale: 0.8 + (0.2 * _fadeAnimation!.value),
            child: Opacity(opacity: _fadeAnimation!.value, child: child),
          );
        },
        child: messageBubble,
      );
    }

    // Apply shader mask for last question (no changes here)
    if (isLastQuestion) {
      messageBubble = VisibilityDetector(
        key: Key('last-question-${message.id}'),
        onVisibilityChanged: (visibilityInfo) {
          if (mounted) {
            final visiblePercentage = visibilityInfo.visibleFraction * 100;
            final isVisible = visiblePercentage > 75;
            context
                .read<BannerMessageVisibility>()
                .setQuestionVisibilityOnScreen(isVisible);
          }
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
          child: messageBubble,
        ),
      );
    }

    return messageBubble;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BlockedPlayers>(
      builder:
          (BuildContext context, BlockedPlayers blockedPlayers, Widget? child) {
        final messages = widget.originalMessages
            .where(
              (el) =>
                  !blockedPlayers.blockedPlayers.containsKey(el.playerUid),
            )
            .toList();
        final colorScheme = Theme.of(context).colorScheme;

        return ListView.builder(
          controller: widget.scrollController,
          reverse: true,
          shrinkWrap: true,
          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[messages.length - index - 1];
            final messageBefore = messages.length - index - 2 >= 0
                ? messages.elementAt(messages.length - index - 2)
                : message;
            final isCurrentUser = message.playerUid == widget.currentUserId;
            final isLastQuestion = widget.activeQuestion?.id == message.id;
            
            // The `isNewestMessage` flag is no longer needed here for animation logic.

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.read<BannerMessageVisibility>().setIsRoundBreak(
                      widget.activeQuestion == null,
                    );
              }
            });

            return _buildMessageBubble(
              message: message,
              messageBefore: messageBefore,
              isCurrentUser: isCurrentUser,
              isLastQuestion: isLastQuestion,
              colorScheme: colorScheme,
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }
}