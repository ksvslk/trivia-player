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
  String? _lastMessageId;
  bool _hasAnimated = false; // Track if animation has completed

  @override
  void initState() {
    super.initState();
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
    
    // Add listener to track animation completion
    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _hasAnimated = true;
      }
    });
  }

  @override
  void didUpdateWidget(MessageListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if a new message was added
    if (widget.originalMessages.isNotEmpty && 
        oldWidget.originalMessages.isNotEmpty &&
        widget.originalMessages.length > oldWidget.originalMessages.length) {
      
      final newLastMessage = widget.originalMessages.last;
      if (_lastMessageId != newLastMessage.id) {
        _lastMessageId = newLastMessage.id;
        _hasAnimated = false; // Reset animation state
        _initializeAnimation();
        _animationController!.forward();
      }
    } else if (widget.originalMessages.isNotEmpty) {
      // Initialize with the current last message
      final currentLastMessage = widget.originalMessages.last;
      if (_lastMessageId != currentLastMessage.id) {
        _lastMessageId = currentLastMessage.id;
        // If this is just a theme change, mark as already animated
        if (oldWidget.originalMessages.isNotEmpty && 
            oldWidget.originalMessages.length == widget.originalMessages.length) {
          _hasAnimated = true;
        }
      }
    }
  }

  Widget _buildMessageBubble({
    required Message message,
    required Message messageBefore,
    required bool isCurrentUser,
    required bool isLastQuestion,
    required ColorScheme colorScheme,
    required bool isNewestMessage,
  }) {
    Widget messageBubble = MessageBubble(
      message: message,
      messageBefore: messageBefore,
      isCurrentUser: isCurrentUser,
      playerId: widget.currentUserId,
      formatTimestamp: widget.formatTimestamp,
    );

    // Apply animation only to the newest message that hasn't been animated yet
    if (isNewestMessage && 
        _animationController != null && 
        _fadeAnimation != null && 
        !_hasAnimated) {
      messageBubble = AnimatedBuilder(
        animation: _animationController!,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * _fadeAnimation!.value),
            child: Opacity(
              opacity: _fadeAnimation!.value,
              child: child,
            ),
          );
        },
        child: messageBubble,
      );
    }

    // Apply shader mask for last question
    if (isLastQuestion) {
      messageBubble = VisibilityDetector(
        key: Key('last-question-${message.id}'),
        onVisibilityChanged: (visibilityInfo) {
          final visiblePercentage = visibilityInfo.visibleFraction * 100;
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
          child: messageBubble,
        ),
      );
    }

    return messageBubble;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BlockedPlayers>(builder:
        (BuildContext context, BlockedPlayers blockedPlayers, Widget? child) {
      final messages = widget.originalMessages
          .where(
              (el) => !blockedPlayers.blockedPlayers.containsKey(el.playerUid))
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
          final isNewestMessage = message.id == _lastMessageId;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            context
                .read<BannerMessageVisibility>()
                .setIsRoundBreak(widget.activeQuestion == null);
          });

          return _buildMessageBubble(
            message: message,
            messageBefore: messageBefore,
            isCurrentUser: isCurrentUser,
            isLastQuestion: isLastQuestion,
            colorScheme: colorScheme,
            isNewestMessage: isNewestMessage,
          );
        },
      );
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }
}