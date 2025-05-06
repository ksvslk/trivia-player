import 'dart:math';

import 'package:flutter/material.dart';
import 'package:operation_veritas/change_notifier/banner_message_visibility.dart';
import 'package:operation_veritas/chat_page/trivia_chat.dart';
import 'package:operation_veritas/settings/menu_drawer.dart';
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
    return Scaffold(
      drawer: MenuDrawer(parentNavigatorKey: navigatorKey),
      body: TriviaChat(
        name: "An_${Random().nextInt(1000)}",
        userColor: userColor,
      ),
      floatingActionButton: Builder(
        builder: (BuildContext scaffoldContext) {
          return Consumer<BannerMessageVisibility>(
            builder: (context, banner, child) {
              print("isQuestionVisibleOnScreen: " + banner.isQuestionVisibleOnScreen().toString());
              print("isRoundBreak: " + banner.isRoundBreak().toString());
              return Opacity(
                  opacity: banner.isQuestionVisibleOnScreen() || banner.isRoundBreak() ? 1.0 : 0.0,
                  child: FloatingActionButton(
                    elevation: 4.0,
                    focusElevation: 4.0,
                    hoverElevation: 4.0,
                    highlightElevation: 4.0,
                    mini: true,
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    child: Icon(Icons.settings),
                  ));
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
    );
  }
}
