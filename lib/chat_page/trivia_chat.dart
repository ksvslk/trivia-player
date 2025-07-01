import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:operation_veritas/audio/audio_controller.dart';
import 'package:operation_veritas/audio/sounds.dart';
import 'package:operation_veritas/change_notifier/stats_service.dart';
import 'package:operation_veritas/chat_page/eula_bottomsheet.dart';
import 'package:operation_veritas/chat_page/footer_info.dart';
import 'package:operation_veritas/chat_page/message_input.dart';
import 'package:operation_veritas/chat_page/message_list_view.dart';
import 'package:operation_veritas/chat_page/question_time_progress.dart';
import 'package:operation_veritas/change_notifier/banner_message_visibility.dart';
import 'package:operation_veritas/change_notifier/trivia_service.dart';
import 'package:operation_veritas/l10n/app_localizations.dart';
import 'package:operation_veritas/persistence/settings_controller.dart';
import 'package:provider/provider.dart';

class TriviaChat extends StatefulWidget {
  const TriviaChat({super.key});

  @override
  State<TriviaChat> createState() => _TriviaChatState();
}

class _TriviaChatState extends State<TriviaChat> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    final settingsController = context.read<SettingsController>();
    if (!settingsController.isEulaAccepted) {
      EulaBottomSheet.show(
        context,
        onAccept: () {
          Navigator.pop(context);
          settingsController.setEulaAccepted();
        },
      );
    }
  });
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

        return SafeArea(
          child: Scaffold(
            body: Column(
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
                    triviaService.getActiveQuestion!.messageType == 'question')
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
