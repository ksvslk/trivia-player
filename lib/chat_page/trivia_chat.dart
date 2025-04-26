import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:operation_veritas/audio/audio_controller.dart';
import 'package:operation_veritas/audio/sounds.dart';
import 'package:operation_veritas/chat_page/connection_status_icon.dart';
import 'package:operation_veritas/chat_page/message.dart';
import 'package:operation_veritas/chat_page/message_input.dart';
import 'package:operation_veritas/chat_page/message_list_view.dart';
import 'package:operation_veritas/chat_page/question_timer.dart';
import 'package:operation_veritas/settings_menu.dart';
import 'package:provider/provider.dart';

class TriviaChat extends StatefulWidget {
  const TriviaChat({
    super.key, 
    required this.name, 
    required this.userColor
  });
  
  final String name;
  final Color userColor;

  @override
  State<TriviaChat> createState() => _TriviaChatState();
}

class _TriviaChatState extends State<TriviaChat> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseReference _messagesRef = FirebaseDatabase.instance.ref().child('trivia_messages');
  final DatabaseReference _playerCountRef = FirebaseDatabase.instance.ref('player_count');
  final List<Message> _messages = [];
  
  int _playerCount = 0;
  bool _connected = false;
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _setupListeners();
  }

  void _setupListeners() {
    // Connection status listener
    FirebaseDatabase.instance.ref(".info/connected").onValue.listen((event) {
      if (mounted) {
        setState(() {
          _connected = event.snapshot.value as bool? ?? false;
        });
      }
    });
    
    // Player count listener
    _playerCountRef.onValue.listen((event) {
      if (mounted) {
        setState(() {
          _playerCount = event.snapshot.value as int? ?? 0;
        });
      }
    });
    
    // Messages listener with limit for initial load
    _messagesRef
        .limitToLast(50)
        .onChildAdded
        .listen(_handleNewMessage);
        
    // Mark loading as complete after a short delay to ensure initial messages are loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _handleNewMessage(DatabaseEvent event) {
    if (event.snapshot.value == null) return;
    
    try {
      final message = Map<String, dynamic>.from(event.snapshot.value as Map);
      final newMessage = Message(
        id: event.snapshot.key ?? '',
        playerUid: message['id'] ?? '',
        name: message['name'] ?? 'Unknown',
        text: message['text'] ?? '',
        badgeText: message['badgeText'] ?? '',
        isBot: message['isBot'] ?? false,
        timestamp: message['timestamp'] ?? 0,
        roundNumber: message['roundNumber'] ?? -1,
        messageType: message['messageType'] ?? '',
        questionStartTime: message['questionStartTime'] ?? -1,
        questionEndTime: message['questionEndTime'] ?? -1,
        serverTime: message['serverTime'] ?? -1,
      );
      
      if (mounted) {
        setState(() {
          _messages.add(newMessage);
        });
        
        // Auto-scroll to bottom for new messages if already at bottom
        if (_scrollController.hasClients && 
            _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error parsing message: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    try {
      await _messagesRef.push().set({
        'id': _currentUserId,
        'name': widget.name,
        'text': text,
        'isBot': false,
        'timestamp': ServerValue.timestamp,
      });
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  String _formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}}';
  }

  @override
  Widget build(BuildContext context) {
    final audioController = context.read<AudioController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Players: $_playerCount',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'WorkSans', fontSize: 18),
        ),
        actions: [
          const SettingsMenu(),
          ConnectionStatusIcon(connected: _connected),
        ],
      ),
      body: Column(
        children: [
          QuestionTimer(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : MessageListView(
                        messages: _messages,
                        scrollController: _scrollController,
                        currentUserId: _currentUserId,
                        formatTimestamp: _formatTimestamp,
                      ),
          ),
          MessageInput(
            controller: _controller,
            onSend: () {
              if (_controller.text.isNotEmpty) {
                //audioController.playSfx(SfxType.rotate);
                _sendMessage();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

