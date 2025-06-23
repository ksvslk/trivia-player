import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:games_services/games_services.dart' as gs;
import 'package:games_services/games_services.dart';
import 'package:logging/logging.dart';
import 'package:operation_veritas/persistence/settings_controller.dart';

enum AuthState { authenticated, progress, failed }

class AuthController extends ChangeNotifier {
  static final Logger _log = Logger('AuthController');

  // Configuration
  final String androidWebClientID =
      '730456293701-nepun8t1d5u90rm9qrohhjbb9ujp7d5o.apps.googleusercontent.com';
  final String androidRoundLeaderboard = 'CgkIxYLalKEVEAIQAQ';
  final String androidQuestionLeaderboard = 'CgkIxYLalKEVEAIQAg';
  final String iosdRoundLeaderboard = 'CgkIxYLalKEVEAIQAQ';
  final String iosQuestionLeaderboard = 'CgkIxYLalKEVEAIQAg';

  // State
  AuthState _authState = AuthState.progress;
  User? _currentUser;
  String _playerName = "Player";
  String _errorMessage = "";
  bool _isGameServicesAvailable = false;
  String? gameServicesPlayerId;
  String? playerImage = "";

  // Dependencies
  SettingsController? _settings;
  ValueNotifier<AppLifecycleState>? _lifecycleNotifier;

  // Getters
  AuthState get authState => _authState;
  String get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  String get playerName => _playerName;
  bool get isLeaderboardAvailable => _isGameServicesAvailable;
  bool get isAuthenticated => _currentUser != null;

  AuthController() {
    initialize();
  }

  Future<void> initialize() async {
    _authState = AuthState.progress;
    _errorMessage = "";
    notifyListeners();

    try {
      await _signIn();

      if (_currentUser != null) {
        _authState = AuthState.authenticated;

        // Initialize notifications after successful auth
        _initializeNotifications();
        _handlePostAuthNotifications();
      } else {
        _authState = AuthState.failed;
        _errorMessage = "Sign in failed";
      }
    } catch (e) {
      _authState = AuthState.failed;
      _errorMessage = e.toString();
      _log.log(Level.SEVERE, 'Auth failed: $e');
    }

    notifyListeners();
  }

  Future<void> _signIn() async {
    // Try Game Services + Firebase
    try {
      await gs.GamesServices.signIn();
      gameServicesPlayerId = await gs.GamesServices.getPlayerID();

      final credential = await _getPlatformCredential();
      if (credential != null) {
        final userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
        _currentUser = userCredential.user;

        // Additional check: ensure Firebase actually gave us a user
        if (_currentUser == null) {
          throw Exception(
            'Firebase returned null user despite successful credential',
          );
        }

        _playerName = _currentUser?.displayName ?? "Player";
        _isGameServicesAvailable = true;

        // Upload player image
        try {
             final playerData = await gs.GameAuth.player.first;
        if (playerData?.iconImage?.isNotEmpty == true) {
          playerImage = await _uploadImage(playerData!.iconImage!);
        } else {
          playerImage = "";
        }
        } catch(e) {
      _log.log(Level.WARNING, 'Error uploading avatar: $e');

        }
     

        /*
        if (Platform.isIOS) {
          gs.GamesServices.player.first.then(
            (a) => _currentUser?.updatePhotoURL(a?.iconImage),
          );
        }
        */
        return;
      }

      // If credential is null, throw error to trigger failed state
      throw Exception(
        'Failed to get platform credential - check androidWebClientID configuration',
      );
    } catch (e) {
      _log.log(Level.WARNING, 'Game Services failed: $e');
      _isGameServicesAvailable = false;
      rethrow; // Re-throw to trigger failed state in initialize()
    }
  }

  Future<String> _uploadImage(String base64Image) async {
    final bytes = base64Decode(base64Image);
    final ref = FirebaseStorage.instance.ref(
      'avatars/${_currentUser!.uid}.png',
    );

    // This will overwrite the existing file if it exists
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }

  Future<AuthCredential?> _getPlatformCredential() async {
    try {
      if (Platform.isAndroid && androidWebClientID.isNotEmpty) {
        final authCode = await GameAuth.getAuthCode(androidWebClientID);
        if (authCode != null) {
          return PlayGamesAuthProvider.credential(serverAuthCode: authCode);
        }
      } else if (Platform.isIOS || Platform.isMacOS) {
        return GameCenterAuthProvider.credential();
      }
    } catch (e) {
      _log.log(Level.WARNING, 'Platform credential failed: $e');
    }
    return null;
  }

  // Notification logic
  void _initializeNotifications() {
    _askNotificationPermissions().catchError(
      (e) => _log.warning('Notification permission failed: $e'),
    );

    if (Platform.isMacOS || Platform.isIOS) {
      FirebaseMessaging.instance.getAPNSToken().catchError(
        (e) => _log.log(Level.WARNING, 'APNS token failed: $e'),
      );
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) => _checkAndStoreToken(token),
      onError: (e) => _log.log(Level.WARNING, 'Token refresh error: $e'),
    );
  }

  void _handlePostAuthNotifications() {
    FirebaseMessaging.instance
        .getToken()
        .then((token) {
          if (token != null) {
            _checkAndStoreToken(token);
          }
          _checkInUser();
        })
        .catchError(
          (e) => _log.log(Level.WARNING, 'Post-auth notifications failed: $e'),
        );
  }

  Future<void> _askNotificationPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  Future<void> _checkAndStoreToken(String token) async {
    try {
      final tokenStored = await _settings?.getToken() ?? '';
      final uid = _currentUser?.uid;

      if (uid != null && token.isNotEmpty && tokenStored != token) {
        final deviceToken = {
          'token': token,
          'timestamp': FieldValue.serverTimestamp(),
          'checkInTimestamp': FieldValue.serverTimestamp(),
        };

        final collection = Platform.isAndroid
            ? 'fcmTokensAndroid'
            : 'fcmTokensIos';
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(uid)
            .set(deviceToken);
        await _settings?.setToken(token);
        _log.info('FCM token stored');
      }
    } catch (e) {
      _log.warning('Token storage failed: $e');
    }
  }

  Future<void> _checkInUser() async {
    try {
      final uid = _currentUser?.uid;
      if (uid != null) {
        final data = {'checkInTimestamp': FieldValue.serverTimestamp()};
        final collection = Platform.isAndroid
            ? 'fcmTokensAndroid'
            : 'fcmTokensIos';
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(uid)
            .update(data);
        _log.info('User check-in updated');
      }
    } catch (e) {
      _log.warning('Check-in failed: $e');
    }
  }

  // Leaderboard methods
  void showLeaderboard() async {
    if (!_isGameServicesAvailable) return;
    try {
      await Leaderboards.showLeaderboards(
        androidLeaderboardID: androidRoundLeaderboard,
        iOSLeaderboardID: iosdRoundLeaderboard,
      );
    } catch (e) {
      _log.warning('Show leaderboard failed: $e');
    }
  }

  void submitRoundScore(int score) async {
    if (!_isGameServicesAvailable) return;
    try {
      await Leaderboards.submitScore(
        score: Score(
          androidLeaderboardID: androidRoundLeaderboard,
          iOSLeaderboardID: iosdRoundLeaderboard,
          value: score,
        ),
      );
    } catch (e) {
      _log.log(Level.WARNING, 'Submit round score failed: $e');
    }
  }

  void submitQuestionScore(int score) async {
    if (!_isGameServicesAvailable) return;
    try {
      await Leaderboards.submitScore(
        score: Score(
          androidLeaderboardID: androidQuestionLeaderboard,
          iOSLeaderboardID: iosQuestionLeaderboard,
          value: score,
        ),
      );
    } catch (e) {
      _log.log(Level.WARNING, 'Submit question score failed: $e');
    }
  }

  Future<void> retry() async {
    await initialize();
  }

  // Dependencies
  void attachSettings(SettingsController settingsController) {
    _settings = settingsController;
  }

  void attachLifecycleNotifier(
    ValueNotifier<AppLifecycleState> lifecycleNotifier,
  ) {
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);
    lifecycleNotifier.addListener(_handleAppLifecycle);
    _lifecycleNotifier = lifecycleNotifier;
  }

  void _handleAppLifecycle() {
    if (_lifecycleNotifier?.value == AppLifecycleState.resumed &&
        isAuthenticated) {
      _checkInUser();
    }
  }

  @override
  void dispose() {
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);
    super.dispose();
  }
}
