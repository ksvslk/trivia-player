import 'package:flutter/material.dart';
import 'package:operation_veritas/chat_page/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final String? playerId;
  final String Function(int) formatTimestamp;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.playerId,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width:
                          22, // Diameter of the original CircleAvatar (radius * 2)
                      height:
                          22, // Diameter of the original CircleAvatar (radius * 2)
                      decoration: BoxDecoration(
                        color: message.isBot
                            ? colorScheme.outlineVariant
                            : (isCurrentUser
                                ? colorScheme.tertiaryContainer
                                : colorScheme.secondary),
                        borderRadius: BorderRadius.circular(
                            6.0), // Adjust the value (e.g., 4.0, 8.0) for desired corner roundness
                      ),
                      child: Center(
                        // Keep the existing child content
                        child: Transform.translate(
                          offset: const Offset(0,
                              0), // This offset seems unnecessary if it's always (0,0)
                          child: Text(
                            message.isBot
                                ? "🦉"
                                : (message.name.substring(0, 1)),
                            style: TextStyle(
                              fontFamily: 'WorkSans',
                              fontSize: message.isBot ? 12 : 8,
                              height: 1,
                              color: (isCurrentUser
                                  ? colorScheme.onTertiaryContainer
                                  : colorScheme.onSecondary),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      !message.isBot ? message.name : (message.badgeText == '' ? 'Host' : ""),
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'WorkSans',
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(width: message.isBot ? 0 : 4),
                    if (message.isBot && message.badgeText != '')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 3),
                        decoration: BoxDecoration(
                          color: message.messageType == 'question'
                              ? colorScheme.tertiary
                              : colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          message.badgeText,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'WorkSans',
                            color: message.messageType == 'question'
                                ? colorScheme.onTertiary
                                : colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    /*
                    const Spacer(),
                    Text(
                      formatTimestamp(message.timestamp),
                      style: TextStyle(
                        fontFamily: 'WorkSans',
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    */
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: message.isBot
                        ? colorScheme.surfaceContainerHigh
                        : (isCurrentUser
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerLow),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: message.isBot
                          ? colorScheme.onSurface
                          : (isCurrentUser
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
