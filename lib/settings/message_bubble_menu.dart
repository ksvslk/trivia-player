import 'package:flutter/material.dart';

/// Flutter code sample for [SimpleCascadingMenuApp].

/// A Simple Cascading Menu example using the [MenuAnchor] Widget.
class MessageBubbleMenu extends StatefulWidget {
  const MessageBubbleMenu({super.key});

  @override
  State<MessageBubbleMenu> createState() => _MessageBubbleMenuState();
}

class _MessageBubbleMenuState extends State<MessageBubbleMenu> {
  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');

  @override
  void dispose() {
    _buttonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      childFocusNode: _buttonFocusNode,
      menuChildren: <Widget>[
        MenuItemButton(onPressed: () {}, child: const Text('Hide')),
        MenuItemButton(onPressed: () {}, child: const Text('Block')),
        MenuItemButton(onPressed: () {}, child: const Text('Send Feedback')),
      ],
      builder: (_, MenuController controller, Widget? child) {
        return IconButton(
          focusNode: _buttonFocusNode,
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.more_vert),
        );
      },
    );
  }
}