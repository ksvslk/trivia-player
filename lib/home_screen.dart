import 'dart:math';

import 'package:flutter/material.dart';
import 'package:operation_veritas/ads/blocking_overlay_popup.dart';
import 'package:operation_veritas/change_notifier/banner_message_visibility.dart';
import 'package:operation_veritas/change_notifier/play_time_controller.dart';
import 'package:operation_veritas/chat_page/trivia_chat.dart';
import 'package:operation_veritas/menus/menu_drawer.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  final Color userColor;
  final GlobalKey<NavigatorState> navigatorKey;

  const HomeScreen({
    super.key,
    required this.userColor,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    final playTimeController = context.read<PlayTimeController>();

    return Scaffold(
      drawer: MenuDrawer(parentNavigatorKey: navigatorKey),
      body: Stack(
        children: [
          TriviaChat(
            name: "An_${Random().nextInt(1000)}",
            userColor: userColor,
          ),
          StreamBuilder<bool>(
            stream: playTimeController.onPopupVisibilityUpdate,
            initialData: playTimeController.lockTimeEnd > 0,
            builder: (context, snapshot) {
              return snapshot.data == true ? const BlockingOverlayPopup() : const SizedBox.shrink();
            },
          ),
        ],
      ),
      floatingActionButton: Builder(
        builder: (BuildContext scaffoldContext) {
          return Consumer<BannerMessageVisibility>(
            builder: (context, banner, child) {
              return Opacity(
                opacity: banner.isQuestionVisibleOnScreen() || banner.isRoundBreak() ? 1.0 : 0.0,
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
        },
      ),
      drawerEnableOpenDragGesture: false,
      endDrawerEnableOpenDragGesture: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartTop,
    );
  }
}
