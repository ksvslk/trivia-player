import 'package:flutter/material.dart';
import 'package:operation_veritas/chat_page/message_input.dart';
import 'package:operation_veritas/chat_page/message_list_view.dart';
import 'package:operation_veritas/chat_page/question_time_progress.dart';
import 'package:operation_veritas/change_notifier/banner_message_visibility.dart';
import 'package:operation_veritas/change_notifier/trivia_service.dart';
import 'package:provider/provider.dart';

class TriviaChat extends StatefulWidget {
  const TriviaChat({super.key, required this.name, required this.userColor});

  final String name;
  final Color userColor;

  @override
  State<TriviaChat> createState() => _TriviaChatState();
}

class _TriviaChatState extends State<TriviaChat> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<TriviaService>().setUserName(widget.name);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final triviaService = context.read<TriviaService>();

    try {
      await triviaService.sendMessage(text);
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Consumer2<TriviaService, BannerMessageVisibility>(
              builder: (context, triviaService, visibility, child) {
                final colorScheme = Theme.of(context).colorScheme;
                return Visibility(
                      visible: !visibility.isQuestionVisibleOnScreen() &&
                          triviaService.getActiveQuestion != null,
                      maintainSize: false,
                      maintainAnimation: false,
                      maintainState: false,
                      child: Container(
                        width: double.infinity,
                        key: ValueKey<String>('active-question-banner'),
                        color: colorScheme.surfaceContainerLow,
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          triviaService.getActiveQuestion != null
                              ? triviaService.getActiveQuestion!.text
                              : '',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontFamily: 'Inter',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
              },
            ),
            Consumer<TriviaService>(
              builder: (context, triviaService, child) {
                final activeQuestion = triviaService.getActiveQuestion;
                if (activeQuestion == null ||
                    activeQuestion.messageType != 'question') {
                  return const SizedBox.shrink();
                }
                return QuestionTimeProgress(message: activeQuestion);
              },
            ),
            Expanded(
              child: Consumer<TriviaService>(
                builder: (context, service, child) {
                  // Check if we need to scroll when messages change
                  /*
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _checkAndScrollToBottom());
                    */

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (service.currentUserId ==
                        service.messages.lastOrNull?.playerUid) {
                      _scrollController.animateTo(
                        _scrollController.position.minScrollExtent,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  return service.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : service.messages.isEmpty
                          ? const Center(child: Text('No messages yet'))
                          : MessageListView(
                              originalMessages: service.messages,
                              scrollController: _scrollController,
                              currentUserId: service.currentUserId,
                              formatTimestamp: service.formatTimestamp,
                              activeQuestion: service.getActiveQuestion);
                },
              ),
            ),
             MessageInput(
              controller: _controller,
              onSend: () {
                if (_controller.text.isNotEmpty) {
                  // Optionally play sound effect
                  // audioController.playSfx(SfxType.rotate);
                  _sendMessage();
                }
              },
          
             ),
            
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
