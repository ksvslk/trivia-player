import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:operation_veritas/ads/blocking_overlay_popup.dart';
import 'package:operation_veritas/audio/audio_controller.dart';
import 'package:operation_veritas/audio/sounds.dart';
import 'package:operation_veritas/auth_services/auth_controller.dart';
import 'package:operation_veritas/change_notifier/banner_message_visibility.dart';
import 'package:operation_veritas/change_notifier/money_controller.dart';
import 'package:operation_veritas/change_notifier/trivia_service.dart';
import 'package:operation_veritas/chat_page/trivia_chat.dart';
import 'package:operation_veritas/l10n/app_localizations.dart';
import 'package:operation_veritas/menus/menu_drawer.dart';
import 'package:operation_veritas/persistence/settings_controller.dart';
import 'package:operation_veritas/pulsing_logo_animation.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const HomeScreen({super.key, required this.navigatorKey});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Local state to handle the "Start" button loading state after click
  bool _isStartingGame = false;

  @override
  Widget build(BuildContext context) {
    // 1. WATCH PROVIDERS
    final triviaService = context.watch<TriviaService>();
    final authController = context.watch<AuthController>();
    // We keep banner in case you need it later, but removed from overlay logic as requested
    // final banner = context.watch<BannerMessageVisibility>(); 
    final audioController = context.read<AudioController>();

    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness; 
    final overlayBrightness =
        brightness == Brightness.dark ? Brightness.light : Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: colorScheme.surface,
        statusBarColor: colorScheme.surface,
        systemNavigationBarIconBrightness: overlayBrightness,
        statusBarIconBrightness: overlayBrightness,
      ),
    );

    // --- PURE STATE LOGIC ---

    // A. Technical Loading?
    final bool isTechnicalLoading = triviaService.isLoading ||
        !triviaService.connected ||
        authController.authState == AuthState.signingIntoFirebase;

    // B. Check for 'PAUSED' badge
    // This is the ONLY time we show the start round overlay (besides errors/loading)
    bool isGamePaused = false;
    if (triviaService.messages.isNotEmpty) {
      // Access the last message to check status
      final lastMsg = triviaService.messages.last;
      if (lastMsg.badgeText == 'PAUSED') {
        isGamePaused = true;
      }
    }

    // STATE CLEANUP
    // If we were "Starting", but the game is no longer "PAUSED" (meaning a new message arrived),
    // we reset the starting flag so the overlay disappears.
    if (_isStartingGame && !isGamePaused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isStartingGame) {
          setState(() {
            _isStartingGame = false;
          });
        }
      });
    }

    // C. Failed State?
    final bool isFailedState = authController.authState == AuthState.failed ||
        authController.authState == AuthState.waitingToRetry;

    // D. Should we show the Master Overlay?
    final bool showOverlay = isFailedState ||
        isTechnicalLoading ||
        _isStartingGame ||
        isGamePaused; // <--- STRICTLY PAUSED CHECK

    // E. Determine Background Type
    final bool useSolidBackground = isFailedState || isTechnicalLoading;

    final Color overlayBackgroundColor = useSolidBackground
        ? colorScheme.surface
        : colorScheme.surface.withOpacity(0.90);

    // F. Overlay Content
    Widget overlayContent;

    if (isFailedState) {
      // CASE A: Failed
      overlayContent = Column(
        key: const ValueKey('failed_state'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            width: 150,
            height: 150,
            brightness == Brightness.dark
                ? "assets/images/fail.png"
                : "assets/images/fail_light.png",
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => authController.retry(),
            child: const Text("Try again"),
          ),
        ],
      );
    } else if (isTechnicalLoading || _isStartingGame) {
      // CASE B: Loading (Logo)
      overlayContent = PulsingLogoAnimation(
        key: const ValueKey('loading_logo'),
        size: 150,
        imagePath: brightness == Brightness.dark
            ? 'assets/images/3.png'
            : 'assets/images/3_light.png',
      );
    } else {
      // CASE C: Ready to Play (Button)
      // Only reached if isGamePaused is true
      overlayContent = Column(
        key: const ValueKey('ready_content'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Ready to play?",
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 24,
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 200,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 10,
              ),
              onPressed: () async {
                setState(() => _isStartingGame = true);
                audioController.playSfx(SfxType.send);
                try {
                  await triviaService.sendMessage('start');
                } catch (e) {
                  if (mounted) setState(() => _isStartingGame = false);
                }
              },
              child: const Text(
                "START",
                style: TextStyle(
                  fontSize: 22,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      drawer: MenuDrawer(parentNavigatorKey: widget.navigatorKey),
      body: Stack(
        children: [
          // LAYER 1: TriviaChat
          const TriviaChat(key: ValueKey('chat')),

          // LAYER 2: Settings Button
          Builder(builder: (scaffoldContext) {
            return Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Consumer<BannerMessageVisibility>(
                    builder: (context, banner, child) {
                      final bool visible = !showOverlay &&
                          (banner.isQuestionVisibleOnScreen() ||
                              banner.isRoundBreak());

                      return Opacity(
                        opacity: visible ? 1.0 : 0.0,
                        child: FloatingActionButton(
                          elevation: 4.0,
                          mini: true,
                          onPressed: () {
                            Scaffold.of(scaffoldContext).openDrawer();
                          },
                          child: const Icon(Icons.settings),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          }),

          // LAYER 3: The Unified Master Overlay
          if (showOverlay)
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                color: overlayBackgroundColor,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: overlayContent,
                  ),
                ),
              ),
            ),

          // LAYER 4: The Money/Subscription Lock
          Consumer<MoneyController>(
            builder: (context, money, child) {
              return ValueListenableBuilder<int>(
                valueListenable: context.read<SettingsController>().lockTimeEnd,
                builder: (context, lockTime, child) {
                  if (lockTime > 0 && !money.isSubscribed()) {
                    primaryFocus?.unfocus();
                    return const BlockingOverlayPopup();
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              );
            },
          ),
        ],
      ),
      drawerEnableOpenDragGesture: false,
      endDrawerEnableOpenDragGesture: false,
    );
  }
}