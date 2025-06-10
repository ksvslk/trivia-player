import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:operation_veritas/audio/audio_controller.dart';
import 'package:operation_veritas/audio/sounds.dart';
import 'package:operation_veritas/change_notifier/stats_service.dart';
import 'package:operation_veritas/chat_page/footer_info.dart';
import 'package:operation_veritas/chat_page/message_input.dart';
import 'package:operation_veritas/chat_page/message_list_view.dart';
import 'package:operation_veritas/chat_page/question_time_progress.dart';
import 'package:operation_veritas/change_notifier/banner_message_visibility.dart';
import 'package:operation_veritas/change_notifier/trivia_service.dart';
import 'package:operation_veritas/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class TriviaChat extends StatefulWidget {
  const TriviaChat({super.key});

  @override
  State<TriviaChat> createState() => _TriviaChatState();
}

class _TriviaChatState extends State<TriviaChat> {
  final Logger _log = Logger('TriviaChat');

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(
    TriviaService triviaService,
    AppLocalizations local,
  ) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      await triviaService.sendMessage(text);
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(local.failedToSend)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final audioController = context.read<AudioController>();

    return Consumer<TriviaService>(
      builder: (context, triviaService, child) {
        // Check if we need to scroll when messages change
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (triviaService.currentUserId ==
              triviaService.messages.lastOrNull?.playerUid) {
            _scrollController.animateTo(
              _scrollController.position.minScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });

        // Check if we need to show loading state
        final bool isLoading =
            triviaService.isLoading ||
            triviaService.messages.isEmpty ||
            !triviaService.connected;

        return SafeArea(
          child: Scaffold(
            body: isLoading
                // Show loading indicator when data is not ready
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!.loading,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                    ),
                  )
                // Show full chat UI when data is ready
                : Column(
                    children: [
                      // Question banner
                      Consumer<BannerMessageVisibility>(
                        builder: (context, visibility, child) {
                          final colorScheme = Theme.of(context).colorScheme;
                          return Visibility(
                            visible:
                                !visibility.isQuestionVisibleOnScreen() &&
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
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Question time progress
                      if (triviaService.getActiveQuestion != null &&
                          triviaService.getActiveQuestion!.messageType ==
                              'question')
                        QuestionTimeProgress(
                          message: triviaService.getActiveQuestion!,
                        ),

                      // Messages list
                      Expanded(
                        child: MessageListView(
                          originalMessages: triviaService.messages,
                          scrollController: _scrollController,
                          currentUserId: triviaService.currentUserId,
                          formatTimestamp: triviaService.formatTimestamp,
                          activeQuestion: triviaService.getActiveQuestion,
                        ),
                      ),

                      // Message input
                      MessageInput(
                        controller: _controller,
                        onSend: () {
                          if (_controller.text.isNotEmpty) {
                            // Optionally play sound effect
                            // audioController.playSfx(SfxType.rotate);
                            audioController.playSfx(SfxType.send);
                            _sendMessage(triviaService, local);
                          }
                        },
                      ),
                      Consumer<StatsService>(
                        builder: (context, stats, child) {
                          return FooterInfo(
                                dotStates: stats.getQuestionsWon(),
                                playerCount: stats.getPlayersCount(),
                                currentQuestionNumber: stats.getQuestionNumber(),
                          );
                        },
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
