import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:operation_veritas/ads/blocking_overlay_popup.dart';
import 'package:operation_veritas/auth_services/auth_controller.dart';
import 'package:operation_veritas/change_notifier/banner_message_visibility.dart';
import 'package:operation_veritas/change_notifier/money_controller.dart';
import 'package:operation_veritas/chat_page/trivia_chat.dart';
import 'package:operation_veritas/l10n/app_localizations.dart';
import 'package:operation_veritas/menus/menu_drawer.dart';
import 'package:operation_veritas/persistence/settings_controller.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const HomeScreen({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    final settingsController = context.read<SettingsController>();
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = colorScheme.brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: colorScheme.surface,
        statusBarColor: colorScheme.surface,
        systemNavigationBarIconBrightness: brightness,
        statusBarIconBrightness: brightness,
      ),
    );

    final local = AppLocalizations.of(context)!;

    return Scaffold(
      drawer: MenuDrawer(parentNavigatorKey: navigatorKey),
      body: Stack(
        children: [
          Consumer<AuthController>(
            builder: (context, auth, child) {
              if (auth.authState == AuthState.authenticated) {
                return TriviaChat();
              } else if (auth.authState == AuthState.failed) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${local.failedToAuth} (${Platform.isAndroid ? "Play Games account required" : "GameCenter account required"})",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Inter',
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          auth.retry();
                        },
                        child: Text(local.tryAgain),
                      ),
                    ],
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          Consumer<MoneyController>(
            builder: (context, money, child) {
              return ValueListenableBuilder<int>(
                valueListenable: settingsController.lockTimeEnd,
                builder: (context, lockTime, child) {
                  if (lockTime > 0 && !money.isSubscribed()) {
                    primaryFocus?.unfocus();
                    return BlockingOverlayPopup();
                  } else {
                    return SizedBox.shrink();
                  }
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: Builder(
        builder: (BuildContext scaffoldContext) {
          return Consumer<AuthController>(
            builder: (context, auth, child) {
              if (auth.authState == AuthState.authenticated) {
                return Consumer<BannerMessageVisibility>(
                  builder: (context, banner, child) {
                    return Opacity(
                      opacity:
                          banner.isQuestionVisibleOnScreen() ||
                              banner.isRoundBreak()
                          ? 1.0
                          : 0.0,
                      child: FloatingActionButton(
                        elevation: 4.0,
                        mini: true,
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                        child: const Icon(Icons.settings),
                      ),
                    );
                  },
                );
              } else {
                return SizedBox.shrink();
              }
            },
          );
        },
      ),
      drawerEnableOpenDragGesture: false,
      endDrawerEnableOpenDragGesture: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartTop,
    );
  }
}
