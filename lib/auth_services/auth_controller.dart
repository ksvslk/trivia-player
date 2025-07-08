import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:games_services/games_services.dart' as gs;
import 'package:games_services/games_services.dart';
import 'package:logging/logging.dart';
import 'package:operation_veritas/persistence/settings_controller.dart';

enum AuthState {
  authenticated,
  signingIntoGameServices,
  signingIntoFirebase,
  failed,
}

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
  AuthState _authState = AuthState.signingIntoGameServices;
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
    _authState = AuthState.signingIntoGameServices;
    _errorMessage = "";
    notifyListeners();

    try {
      // Step 1: Sign into Game Services
      await _signIntoGameServices();

      // Step 2: Sign into Firebase
      _authState = AuthState.signingIntoFirebase;
      notifyListeners();

      await _signIntoFirebase();

      // Step 3: Success - setup post-auth
      _authState = AuthState.authenticated;

      // Initialize notifications after successful auth
      _initializeNotifications();
      _handlePostAuthNotifications();
    } catch (e) {
      _authState = AuthState.failed;
      _errorMessage = e.toString();
      _log.log(Level.SEVERE, 'Authentication failed: $e');
    }

    notifyListeners();
  }

  Future<void> _signIntoGameServices() async {
    try {
      await gs.GamesServices.signIn();
      gameServicesPlayerId = await gs.GamesServices.getPlayerID();
      if (gameServicesPlayerId == null || gameServicesPlayerId!.isEmpty) {
        throw Exception('Game Services sign-in failed: No player ID received');
      }
      _isGameServicesAvailable = true;
    } catch (e) {
      _isGameServicesAvailable = false;
      _log.log(Level.SEVERE, 'Game Services sign-in failed: $e');
      throw Exception('Game Services sign-in failed: $e');
    }
  }

  Future<void> _signIntoFirebase() async {
    try {
      final credential = await _getPlatformCredential();
      if (credential == null) {
        throw Exception(
          'Failed to get platform credential - check androidWebClientID configuration',
        );
      }
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      _currentUser = userCredential.user;

      if (_currentUser == null) {
        throw Exception(
          'Firebase returned null user despite successful credential',
        );
      }
      _playerName = _currentUser?.displayName ?? "Player";
      // Upload player image
      await _uploadPlayerImage();
    } catch (e) {
      _log.log(Level.SEVERE, 'Firebase sign-in failed: $e');
      throw Exception('Firebase sign-in failed: $e');
    }
  }

  Future<void> _uploadPlayerImage() async {
    try {
      final playerData = await gs.GameAuth.player.first;
      if (playerData?.iconImage?.isNotEmpty == true) {
        // Check if we need to upload (only if file is older than a week)
        final ref = FirebaseStorage.instance.ref(
          'avatars/${_currentUser!.uid}.png',
        );
        bool shouldUpload = true;

        try {
          final metadata = await ref.getMetadata();
          final lastModified = metadata.updated ?? metadata.timeCreated;
          if (lastModified != null) {
            final weekAgo = DateTime.now().subtract(const Duration(days: 7));
            shouldUpload = lastModified.isBefore(weekAgo);
          }
        } catch (e) {
          // File doesn't exist, so we should upload
          shouldUpload = true;
        }

        if (shouldUpload) {
          playerImage = await _uploadImage(playerData!.iconImage!);
        } else {
          playerImage = await ref.getDownloadURL();
        }
      } else {
        playerImage = "";
      }
    } catch (e) {
      _log.log(Level.WARNING, 'Error uploading avatar (non-fatal): $e');
      playerImage = "";
    }
  }

  Future<String> _uploadImage(String base64Image) async {
    Uint8List originalBytes = base64Decode(base64Image);

    const int minWidth = 128;
    const int minHeight = 128;
    const int quality = 85;

    Uint8List? compressedBytes = await FlutterImageCompress.compressWithList(
      originalBytes,
      minWidth: minWidth,
      minHeight: minHeight,
      quality: quality,
      format: CompressFormat.png,
    );

    final ref = FirebaseStorage.instance.ref(
      'avatars/${_currentUser!.uid}.png',
    );

    final metadata = SettableMetadata(contentType: 'image/png');

    await ref.putData(compressedBytes, metadata);
    return await ref.getDownloadURL();
  }

  Future<AuthCredential?> _getPlatformCredential() async {
    try {
      if (Platform.isAndroid && androidWebClientID.isNotEmpty) {
        final authCode = await GameAuth.getAuthCode(androidWebClientID);
        if (authCode != null) {
          return PlayGamesAuthProvider.credential(serverAuthCode: authCode);
        } else {
          throw Exception('Failed to get Android auth code');
        }
      } else if (Platform.isIOS || Platform.isMacOS) {
        return GameCenterAuthProvider.credential();
      } else {
        throw Exception('Unsupported platform or missing androidWebClientID');
      }
    } catch (e) {
      _log.log(Level.SEVERE, 'Platform credential failed: $e');
      rethrow;
    }
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
      await Leaderboards.showLeaderboards();
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
