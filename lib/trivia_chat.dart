import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:operation_veritas/audio/audio_controller.dart';
import 'package:operation_veritas/audio/sounds.dart';
import 'package:operation_veritas/settings_menu.dart';
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
  final DatabaseReference _messagesRef =
      FirebaseDatabase.instance.ref().child('trivia_messages');
  final List<Map<String, dynamic>> _messages = [];
  final DatabaseReference _playerCountRef = FirebaseDatabase.instance.ref('player_count');
  int _playerCount = 0;
  bool connected = false;

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is int) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    }
    return 'N/A';
  }

  @override
  void initState() {
    super.initState();
    _setupListeners();
      // Listen for changes to 'player_count' in the database
    _playerCountRef.onValue.listen((DatabaseEvent event) {
      final count = event.snapshot.value as int?;
      setState(() {
        _playerCount = count ?? 0;
      });
    });
  }

  void _setupListeners() {

    final connectedRef = FirebaseDatabase.instance.ref(".info/connected");
    connectedRef.onValue.listen((event) {
      final isConnected = event.snapshot.value as bool? ?? false;
      setState(() { connected = isConnected; });
    });
    
    _messagesRef.onChildAdded.listen((event) {
      final message = Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        _messages.add({
          'id': event.snapshot.key,
          ...message,
        });
      });
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      await _messagesRef.push().set({
        'id': FirebaseAuth.instance.currentUser?.uid,
        'name': widget.name,
        'text': _controller.text,
        'isBot': false,
        'timestamp': ServerValue.timestamp,
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioController = context.read<AudioController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          textAlign: TextAlign.center,
          'Players: $_playerCount',
          style:const TextStyle(fontFamily: 'WorkSans', fontSize: 18),
        ),
        actions: [
          const SettingsMenu(),
          IconButton(
            icon: connected ? const Icon(Icons.signal_cellular_4_bar_sharp, color: Colors.green) : const Icon(Icons.signal_cellular_0_bar, color: Colors.red),
            onPressed: () => {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              shrinkWrap: true,
              itemCount: _messages.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - index - 1];
                final isCurrentUser =
                    message["id"] == FirebaseAuth.instance.currentUser?.uid;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: message['isBot']
                            ? colorScheme.outlineVariant
                            : (isCurrentUser
                                ? colorScheme.tertiaryContainer
                                : colorScheme.secondary),
                        child: Center(
                          child: Transform.translate(
                            offset: const Offset(
                                0, 0), // Adjust this value as needed
                            child: Text(
                              message['isBot']
                                  ? "🦁"
                                  : (message['name']?.substring(0, 1) ?? 'U'),
                              style: TextStyle(
                                fontFamily: 'WorkSans',
                                fontSize: message['isBot']
                                    ? 22
                                    : 16, // Larger size for emoji
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
                                  !message['isBot']
                                      ? (message['name'] ?? 'Unknown')
                                      : "Quiz King",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'WorkSans',
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (message["isBot"])
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: message["isBot"]
                                          ? colorScheme.tertiary
                                          : colorScheme.tertiaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      message["isBot"] ? 'HOST' : 'YOU',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'WorkSans',
                                        color: message["isBot"]
                                            ? colorScheme.onTertiary
                                            : colorScheme.onTertiaryContainer,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                Text(
                                  _formatTimestamp(message['timestamp']),
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
                                color: message['isBot']
                                    ? colorScheme.surfaceContainerHigh
                                    : (isCurrentUser
                                        ? colorScheme.primaryContainer
                                        : colorScheme.surfaceContainerLow),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                message['text'] ?? '',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  color: message['isBot']
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
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type your answer...',
                      border: const OutlineInputBorder(),
                      hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  elevation: 0,
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      audioController.playSfx(SfxType.rotate);
                    }
                    _sendMessage();
                  },
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
