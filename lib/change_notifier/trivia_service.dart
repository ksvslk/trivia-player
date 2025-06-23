import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:operation_veritas/audio/audio_controller.dart';
import 'package:operation_veritas/audio/sounds.dart';
import 'package:operation_veritas/auth_services/auth_controller.dart';
import 'package:operation_veritas/change_notifier/money_controller.dart';
import 'package:operation_veritas/change_notifier/stats_service.dart';
import 'package:operation_veritas/chat_page/message.dart';
import 'package:operation_veritas/persistence/settings_controller.dart';

class TriviaService extends ChangeNotifier {
  final MoneyController? moneyController;
  final SettingsController? settingsController;
  final AuthController? authController;
  final AudioController? audioController;
  final StatsService? statsService;

  final DatabaseReference _messagesRef =
      FirebaseDatabase.instance.ref().child('trivia_messages');
  final List<Message> _messages = [];
  StreamSubscription? _messagesSubscription;

  bool _connected = false;
  bool _isLoading = true;

  Message? _activeQuestion;
  Message? _lastMessage;

  List<Message> get messages => List.unmodifiable(_messages);
  bool get connected => _connected;
  bool get isLoading => _isLoading;
  String? get currentUserId => authController?.currentUser?.uid;
  Message? get getActiveQuestion => _activeQuestion;
  Message? get getLastMessage => _lastMessage;

  TriviaService({
    this.audioController,
    this.moneyController,
    this.settingsController,
    this.authController,
    this.statsService,
  }) {
    _onAuthStateChanged();
    authController?.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    if (authController?.authState == AuthState.authenticated && _isLoading) {
      _initialize();
    }
  }

  void _initialize() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Setup all listeners and perform initial data loads
    _setupConnectionListener();
    _setupStatsListeners();
    await _loadInitialMessages(); // This now handles the main message logic
  }

  void _setupConnectionListener() {
    FirebaseDatabase.instance.ref(".info/connected").onValue.listen((event) {
      _connected = event.snapshot.value as bool? ?? false;
      notifyListeners();
    });
  }

  void _setupStatsListeners() {
    FirebaseDatabase.instance
        .ref('stats/${authController?.currentUser?.uid}')
        .onValue
        .listen(_handleStatsChange);

    FirebaseDatabase.instance
        .ref('player_count')
        .onValue
        .listen(_handlePlayersChange);
  }

 num _lastPriority = 0;

Future<void> _loadInitialMessages() async {
  // Fetch the initial batch using orderByPriority() to ensure limitToLast works correctly.
  final initialDataEvent =
      await _messagesRef.orderByPriority().limitToLast(15).once();

  if (initialDataEvent.snapshot.value != null) {
    final parsedMessages = <Message>[]; // Assuming YourMessageType is your message class

    // --- 2. ITERATE CHILDREN TO GET PRIORITY ---
    // We iterate `snapshot.children` because it's the only way to access the `.priority` of each message.
    for (final childSnapshot in initialDataEvent.snapshot.children) {
      final message =
          _parseMessage(childSnapshot.key!, childSnapshot.value as Map);
      parsedMessages.add(message);

      // Capture the actual priority and update our "bookmark".
      final currentPriority = childSnapshot.priority as num? ?? 0;
      _lastPriority = max(_lastPriority, currentPriority);
    }

    // Client-side sort for initial display order. This is fine.
    parsedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    _messages.addAll(parsedMessages);

    if (_messages.isNotEmpty) {
      _lastMessage = _messages.last;
      final lastQuestionIndex =
          _messages.lastIndexWhere((m) => m.messageType == 'question');
      if (lastQuestionIndex != -1) {
        _activeQuestion = _messages[lastQuestionIndex];
      }
    }
  }

  _isLoading = false;
  notifyListeners();

  // --- 3. START LISTENER USING THE CORRECT PRIORITY ---
  // Now, we listen for messages with a priority greater than the last one we loaded.
  _messagesSubscription?.cancel();
  _messagesSubscription = _messagesRef
      .orderByPriority()
      .startAt(_lastPriority + 1) // Using our reliable "bookmark"
      .onChildAdded
      .listen(_handleNewMessage);
}

void _handleNewMessage(DatabaseEvent event) {
  if (event.snapshot.value == null) return;
  print('[LISTENER FIRED] Priority: ${event.snapshot.priority}, Text: ${(event.snapshot.value as Map)['text']}');

  try {
    // --- 4. UPDATE PRIORITY ON NEW MESSAGES ---
    // Keep the "bookmark" updated with the priority of each new message.
    final newPriority = event.snapshot.priority as num? ?? 0;
    _lastPriority = max(_lastPriority, newPriority);

    final newMessage =
        _parseMessage(event.snapshot.key!, event.snapshot.value as Map);

    if (_messages.any((m) => m.id == newMessage.id)) {
      return;
    }

    handleSfx(newMessage);
    if (newMessage.messageType == "question") {
      _activeQuestion = newMessage;
      setCurrentQuestionNumber(_activeQuestion?.badgeText ?? "");
    } else if (newMessage.messageType == "round_end" ||
        newMessage.messageType == "round_end_with_category_selection") {
      showAdWhenNeeded(newMessage);
      _activeQuestion = null;
    }
    _lastMessage = newMessage;
    final edited = Message(
      text: newMessage.text,
      badgeText: newMessage.badgeText,
      isBot: newMessage.isBot,
      timestamp: newMessage.timestamp,
      name: "${newMessage.name} - ${event.snapshot.priority}",
      roundNumber: newMessage.roundNumber,
      id: newMessage.id,
      messageType: newMessage.messageType,
      playerUid: newMessage.playerUid,
      questionStartTime: newMessage.questionStartTime,
      questionEndTime: newMessage.questionEndTime,
      photoUrl: newMessage.photoUrl,
      questionWinnerUid: newMessage.questionWinnerUid,
      correctAnswerId: newMessage.correctAnswerId,
      realPlayerId: newMessage.realPlayerId
      );
    _messages.add(edited);

    notifyListeners();
  } catch (e) {
    debugPrint('Error parsing message: $e');
  }
}

  Message _parseMessage(String key, Map<dynamic, dynamic> messageData) {
    final message = Map<String, dynamic>.from(messageData);
    return Message(
      id: key,
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
      photoUrl: message['photoUrl'] ?? '',
      questionWinnerUid: message['questionWinnerUid'] ?? '',
      correctAnswerId: message['correctAnswerId'] ?? '',
      realPlayerId: authController?.gameServicesPlayerId,
    );
  }

  void _handlePlayersChange(DatabaseEvent event) {
    if (event.snapshot.value == null) {
      return;
    }
    final dynamic playerCountValue = event.snapshot.value;
    if (playerCountValue is int) {
      statsService?.setPlayersCount(playerCountValue);
    } else if (playerCountValue is num) {
      statsService?.setPlayersCount(playerCountValue.toInt());
    }
  }

  void _handleStatsChange(DatabaseEvent event) {
    if (event.snapshot.value == null) return;

    try {
      final stats = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      final dynamic streakDynamic = stats["streak"];
      final dynamic publicScore = stats["publicScore"];

      final publicQuestionScore = publicScore["publicQuestionScore"];
      final publicRoundScore = publicScore["publicRoundScore"];
      statsService?.setPublicQuestionScore(publicQuestionScore);
      statsService?.setPublicRoundScore(publicRoundScore);
      if (publicQuestionScore != null) {
        authController?.submitQuestionScore(publicQuestionScore);
      }
      if (publicRoundScore != null) {
        authController?.submitRoundScore(publicRoundScore);
      }

      List<int> streak;
      if (streakDynamic is List) {
        streak = streakDynamic.cast<int>();
      } else {
        streak = List.filled(10, 0);
      }

      statsService?.setQuestionsWon(streak);
    } catch (err) {
      debugPrint('Error handling stats change: $err');
    }
  }

  void setCurrentQuestionNumber(String text) {
    var qnr = 1;
    if (text.contains("QUESTION")) {
      qnr = int.parse(text.split(' ')[1].split('/')[0]);
    }
    statsService?.setCurrentQuestion(qnr);
  }

  void handleSfx(Message newMessage) async {
    if (newMessage.questionWinnerUid == authController?.currentUser?.uid) {
      audioController?.playSfx(SfxType.correct);
      await HapticFeedback.heavyImpact();
    } else if (newMessage.messageType == "question") {
      if (newMessage.badgeText.contains("NEW ROUND")) {
        audioController?.playSfx(SfxType.roundStart);
      } else {
        audioController?.playSfx(SfxType.bell);
      }
    } else if (newMessage.messageType == "round_end") {
      audioController?.playSfx(SfxType.roundEnd);
    }
  }

  Future<void> showAdWhenNeeded(Message message) async {
    if (moneyController?.isSubscribed() == true) return;

    final lastRoundWithAd =
        await settingsController?.getLastRoundWithAd() ?? -2;
    if (lastRoundWithAd < 0) {
      await settingsController?.setLastRoundWithAd(
        newValue: lastRoundWithAd + 1,
      ); // skip first for new users
      return;
    }
    if (message.roundNumber > lastRoundWithAd) {
      await settingsController?.setLastRoundWithAd(
        newValue: message.roundNumber,
      );
      settingsController?.saveLockTimeEnd();
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    try {
      await _messagesRef.push().setWithPriority({
        'id': authController?.currentUser?.uid,
        'name': authController?.playerName,
        'text': text,
        'isBot': false,
        'timestamp': ServerValue.timestamp,
        'photoUrl': (Platform.isAndroid ? authController?.currentUser?.photoURL : authController?.playerImage) ?? '',
      }, ServerValue.timestamp);
    } catch (e) {
      rethrow; // Rethrow to allow UI to handle the error
    }
  }

  String formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    // Depending on lifecycle, you might remove the authController listener here,
    // but it's often managed by the widget that provides the controller.
    super.dispose();
  }
}