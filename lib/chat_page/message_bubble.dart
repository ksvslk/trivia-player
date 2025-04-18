import 'package:flutter/material.dart';
import 'package:operation_veritas/chat_page/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final String Function(int) formatTimestamp;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: message.isBot
                ? colorScheme.outlineVariant
                : (isCurrentUser
                    ? colorScheme.tertiaryContainer
                    : colorScheme.secondary),
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, 0),
                child: Text(
                  message.isBot ? "🦁" : (message.name.substring(0, 1)),
                  style: TextStyle(
                    fontFamily: 'WorkSans',
                    fontSize: message.isBot ? 22 : 16,
                    height: 1,
                    color: (isCurrentUser
                        ? colorScheme.onTertiaryContainer
                        : colorScheme.onSecondary),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      !message.isBot ? message.name : "Host",
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'WorkSans',
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (message.isBot && (message.messageType == 'question' || message.messageType == 'answer'))
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: message.messageType == 'question'
                              ? colorScheme.tertiary
                              : colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          message.messageType == 'question' ? 'NEW QUESTION' : 'CORRECT!',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'WorkSans',
                            color: message.messageType == 'question'
                                ? colorScheme.onTertiary
                                : colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      formatTimestamp(message.timestamp),
                      style: TextStyle(
                        fontFamily: 'WorkSans',
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
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
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}
