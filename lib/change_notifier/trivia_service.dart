import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:operation_veritas/ads/ads_controller.dart';
import 'package:operation_veritas/auth_services/auth_controller.dart';
import 'package:operation_veritas/change_notifier/money_controller.dart';
import 'package:operation_veritas/change_notifier/stats_service.dart';
import 'package:operation_veritas/chat_page/message.dart';
import 'package:operation_veritas/persistence/settings_controller.dart';

class TriviaService extends ChangeNotifier {
  final AdsController? adsController;
  final MoneyController? moneyController;
  final SettingsController? settingsController;
  final AuthController? authController;
  final StatsService? statsService;
  final DatabaseReference _messagesRef = FirebaseDatabase.instance.ref().child(
    'trivia_messages',
  );
  late final DatabaseReference _statsRef;
  final List<Message> _messages = [];

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
    this.moneyController,
    this.adsController,
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
    _setupListeners();
  }

  void _setupListeners() {
    // Connection status listener
    FirebaseDatabase.instance.ref(".info/connected").onValue.listen((event) {
      _connected = event.snapshot.value as bool? ?? false;
      notifyListeners();
    });

    // Messages listener with limit for initial load
    _messagesRef.limitToLast(10).onChildAdded.listen(_handleNewMessage);

    // Listen stats
    FirebaseDatabase.instance
        .ref('stats/${authController?.currentUser?.uid}')
        .onValue
        .listen(_handleStatsChange);

    // Listen players count
    FirebaseDatabase.instance
        .ref('player_count')
        .onValue
        .listen(_handlePlayersChange);

    // Mark loading as complete after a short delay to ensure initial messages are loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      _isLoading = false;
      notifyListeners();
    });
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
  } else {
    print('Warning: Unexpected type for player count: ${playerCountValue.runtimeType}');
  }
}

void _handleStatsChange(DatabaseEvent event) {
  if (event.snapshot.value == null) return;

  final stats = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
  final dynamic streakDynamic = stats["streak"];

  List<int> streak;
  if (streakDynamic is List) {
    streak = streakDynamic.cast<int>();
  } else {
    streak = List.filled(10, 0);
  }

  statsService?.setQuestionsWon(streak);
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
        photoUrl: message['photoUrl'] ?? '',
        questionWinnerUid: message['questionWinnerUid'] ?? '',
        correctAnswerId: message['correctAnswerId'] ?? '',
      );
      print("questionWinnerUid: ${newMessage.questionWinnerUid}");
      if (newMessage.messageType == "question") {
        _activeQuestion = newMessage;
      } else if (newMessage.messageType == "round_end" ||
          newMessage.messageType == "round_end_with_category_selection") {
        showAdWhenNeeded(newMessage);
        _activeQuestion = null;
      }
      handleEffects(newMessage.questionWinnerUid);
      _lastMessage = newMessage;
      _messages.add(newMessage);
      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing message: $e');
    }
  }

  void handleEffects(String questionWinnerUid) async {
    if (questionWinnerUid == authController?.currentUser?.uid) {
      await HapticFeedback.heavyImpact();
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
      await _messagesRef.push().set({
        'id': authController?.currentUser?.uid,
        'name': authController?.playerName,
        'text': text,
        'isBot': false,
        'timestamp': ServerValue.timestamp,
        'photoUrl': authController?.currentUser?.photoURL ?? '',
      });
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
    // Any cleanup if needed
    super.dispose();
  }
}
