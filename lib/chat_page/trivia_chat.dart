import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:operation_veritas/audio/audio_controller.dart';
import 'package:operation_veritas/chat_page/connection_status_icon.dart';
import 'package:operation_veritas/chat_page/message_input.dart';
import 'package:operation_veritas/chat_page/message_list_view.dart';
import 'package:operation_veritas/chat_page/question_timer.dart';
import 'package:operation_veritas/settings_menu.dart';
import 'package:operation_veritas/trivia_service/message_visibility.dart';
import 'package:operation_veritas/trivia_service/trivia_service.dart';
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

    // Set the username in the service directly
    context.read<TriviaService>().setUserName(widget.name);

    // Set up scroll controller listener to auto-scroll for new messages
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    // This function can be used if you need specific scroll behavior tracking
  }

  void _checkAndScrollToBottom() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
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
    final audioController = context.read<AudioController>();
    return SafeArea(child: Scaffold(
      /*
      appBar: AppBar(
        title: Consumer<TriviaService>(
          builder: (context, service, child) {
            return Text(
              'Players: ${service.playerCount}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'WorkSans', fontSize: 18),
            );
          },
        ),
        actions: [
          const SettingsMenu(),
          Consumer<TriviaService>(
            builder: (context, service, child) {
              return ConnectionStatusIcon(connected: service.connected);
            },
          ),
        ],
      ),
      */
      body: Column(
        children: [
          Consumer2<TriviaService, BannerMessageVisibility>(
            builder: (context, triviaService, visibility, child) {
              final colorScheme = Theme.of(context).colorScheme;
              return AnimatedSize(
                  duration: Durations.medium1,
                  reverseDuration: Durations.short1,
                  curve: Curves.linearToEaseOut,
                  clipBehavior: Clip.none,
                  child: Visibility(
                    visible: visibility.isVisible() &&
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
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ));
            },
          ),
          QuestionTimer(),
          Expanded(
            child: Consumer<TriviaService>(
              builder: (context, service, child) {
                // Check if we need to scroll when messages change
                /*
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _checkAndScrollToBottom());
                    */

                WidgetsBinding.instance.addPostFrameCallback((_) => {
                      if (service.currentUserId ==
                          service.messages.lastOrNull?.playerUid)
                        {
                          _scrollController.animateTo(
                            _scrollController.position.minScrollExtent,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          )
                        }
                    });

                return service.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : service.messages.isEmpty
                        ? const Center(child: Text('No messages yet'))
                        : MessageListView(
                            messages: service.messages,
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
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
}
