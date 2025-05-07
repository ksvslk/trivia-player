import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:operation_veritas/ads/ads_controller.dart';
import 'package:operation_veritas/change_notifier/money_controller.dart';
import 'package:operation_veritas/chat_page/message.dart';

class TriviaService extends ChangeNotifier {
  final AdsController? adsController;
  final MoneyController? moneyController;
  final DatabaseReference _messagesRef =
      FirebaseDatabase.instance.ref().child('trivia_messages');
  final DatabaseReference _playerCountRef =
      FirebaseDatabase.instance.ref('player_count');
  final List<Message> _messages = [];

  int _playerCount = 0;
  bool _connected = false;
  bool _isLoading = true;
  String? _currentUserId;
  String _userName = '';
  Message? _activeQuestion;
  Message? _lastMessage;

  List<Message> get messages => List.unmodifiable(_messages);
  int get playerCount => _playerCount;
  bool get connected => _connected;
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;
  Message? get getActiveQuestion => _activeQuestion;
  Message? get getLastMessage => _lastMessage;

  TriviaService({this.moneyController, this.adsController}) {
    _initialize();
  }

  void _initialize() {
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _setupListeners();
  }

  void setUserName(String name) {
    _userName = name;
  }

  void _setupListeners() {
    // Connection status listener
    FirebaseDatabase.instance.ref(".info/connected").onValue.listen((event) {
      _connected = event.snapshot.value as bool? ?? false;
      notifyListeners();
    });

    // Player count listener
    _playerCountRef.onValue.listen((event) {
      _playerCount = event.snapshot.value as int? ?? 0;
      notifyListeners();
    });

    // Messages listener with limit for initial load
    _messagesRef.limitToLast(50).onChildAdded.listen(_handleNewMessage);

    // Mark loading as complete after a short delay to ensure initial messages are loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      _isLoading = false;
      notifyListeners();
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
      if (newMessage.messageType == "question") {
        _activeQuestion = newMessage;
      } else if (newMessage.messageType == "round_end" ||
          newMessage.messageType == "round_end_with_category_selection") {
        if (moneyController?.isSubscribed() == false) {
          Future.delayed(Duration(seconds: 3)).then((_) {
            adsController?.showInterstitialAd();
          });
        }
        _activeQuestion = null;
      }
      _lastMessage = newMessage;
      _messages.add(newMessage);
      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing message: $e');
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    try {
      await _messagesRef.push().set({
        'id': _currentUserId,
        'name': _userName,
        'text': text,
        'isBot': false,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Failed to send message: $e');
      rethrow; // Rethrow to allow UI to handle the error
    }
  }

  String formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // Any cleanup if needed
    super.dispose();
  }
}
