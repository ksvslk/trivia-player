import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:operation_veritas/extensions.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:operation_veritas/persistence/settings_controller.dart';

enum AuthState {
  authenticated,
  signingIntoFirebase,
  waitingToRetry,
  failed,
}

class AuthController extends ChangeNotifier {
  static final Logger _log = Logger('AuthController');

  // --- State ---
  AuthState _authState = AuthState.signingIntoFirebase;
  User? _currentUser;
  String _playerName = "Player";
  String _errorMessage = "";

  // --- Exponential Backoff Configuration ---
  int _retryCount = 0;
  static const int _maxRetries = 5;
  static const int _initialDelaySeconds = 2;

  // --- Dependencies ---
  SettingsController? _settings;
  ValueNotifier<AppLifecycleState>? _lifecycleNotifier;

  // --- Getters ---
  AuthState get authState => _authState;
  String get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  String get playerName => _playerName;
  bool get isAuthenticated => _currentUser != null;

  AuthController() {
    initialize();
  }

  Future<void> initialize() async {
    if (_authState != AuthState.waitingToRetry) {
      _authState = AuthState.signingIntoFirebase;
      _errorMessage = "";
      notifyListeners();
    }

    try {
      // Step 1: Sign in and set up the player profile.
      await _signInAndSetupPlayerProfile();

      // Step 2: Success
      _authState = AuthState.authenticated;
      _log.info(
          'Auth & profile setup successful for $_playerName (UID: ${_currentUser?.uid})');

      _retryCount = 0;
      _subscribeToSomeoneIsPlayingNotification();
      _initializeNotifications();
      _handlePostAuthNotifications();
    } catch (e) {
      _log.warning('Auth attempt #${_retryCount + 1} failed: $e');

      if (_retryCount < _maxRetries) {
        _retryCount++;
        final baseDelay = _initialDelaySeconds * pow(2, _retryCount - 1);
        final jitter = Random().nextInt(2) - 1; // -1, 0, or 1
        final delayInSeconds = (baseDelay + jitter).toInt().clamp(1, 60);
        final delay = Duration(seconds: delayInSeconds);

        _authState = AuthState.waitingToRetry;
        _errorMessage =
            'Connection failed. Retrying in ${delay.inSeconds} seconds...';
        notifyListeners();

        _log.info(
            'Scheduling retry #${_retryCount} in ${delay.inSeconds} seconds.');
        await Future.delayed(delay);
        await initialize();
        return;
      } else {
        _authState = AuthState.failed;
        _errorMessage =
            'Authentication failed after $_maxRetries attempts. Please check your connection and try again.';
        _log.severe('Authentication failed after max retries.');
      }
    }
    notifyListeners();
  }

  Future<void> _subscribeToSomeoneIsPlayingNotification() async {
     FirebaseMessaging.onMessage.listen((RemoteMessage message) {});
     await FirebaseMessaging.instance.subscribeToTopic('someone_is_playing');
  }

  /// Handles anonymous sign-in and fetches or creates a player profile in Firestore.
  Future<void> _signInAndSetupPlayerProfile() async {
    try {
      // Part A: Sign in to Firebase Auth
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      _currentUser = userCredential.user;

      if (_currentUser == null) {
        throw Exception('Firebase returned null user after anonymous sign-in.');
      }

      // Here is where the user ID is put into the 'uid' variable
      final uid = _currentUser!.uid; // <-- THE ID IS STORED HERE

      // The 'uid' variable is used here to get the correct document from Firestore
      final playerDocRef =
          FirebaseFirestore.instance.collection('players').doc(uid); // <-- USED HERE

      // Part B: Fetch or create profile in Firestore
      final playerDoc = await playerDocRef.get();

      if (playerDoc.exists) {
        // Player exists, load their data
        final data = playerDoc.data() as Map<String, dynamic>;
        _playerName = data['playerName'] ?? 'Player';
        _log.info('Existing player profile loaded for $uid.');
      } else {
        // The 'uid' variable is used here to generate the username
        _playerName = uid.generateLifelikeUsername(); // <-- USED HERE

        await playerDocRef.set({
          'playerName': _playerName,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _log.info('New player profile created for $uid with name: $_playerName');
      }
    } catch (e) {
      _log.severe('Player sign-in or profile setup failed: $e');
      rethrow;
    }
  }

  /// Manually triggers a new authentication attempt and resets the backoff counter.
  Future<void> retry() async {
    _log.info('Manual retry initiated.');
    _retryCount = 0;
    _authState = AuthState.signingIntoFirebase;
    await initialize();
  }

  // --- Notification Logic ---

  void _initializeNotifications() {
    _askNotificationPermissions().catchError(
      (e) => _log.warning('Notification permission failed: $e'),
    );

    if (Platform.isIOS || Platform.isMacOS) {
      FirebaseMessaging.instance.getAPNSToken().catchError(
            (e) => _log.warning('APNS token failed: $e'),
          );
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) => _checkAndStoreToken(token),
      onError: (e) => _log.warning('Token refresh error: $e'),
    );
  }

  void _handlePostAuthNotifications() {
    FirebaseMessaging.instance.getToken().then((token) {
      if (token != null) {
        _checkAndStoreToken(token);
      }
      _checkInUser();
    }).catchError(
      (e) => _log.warning('Post-auth notifications failed: $e'),
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
      // Here the user ID is retrieved again to use for notifications
      final uid = _currentUser?.uid; // <-- THE ID IS ACCESSED HERE

      if (uid != null && token.isNotEmpty && tokenStored != token) {
        final deviceToken = {
          'token': token,
          'timestamp': FieldValue.serverTimestamp(),
          'checkInTimestamp': FieldValue.serverTimestamp(),
        };

        final collection =
            Platform.isAndroid ? 'fcmTokensAndroid' : 'fcmTokensIos';
        // The 'uid' is used here to store the notification token
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(uid) // <-- USED HERE
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
      // Here the user ID is retrieved again for the check-in
      final uid = _currentUser?.uid; // <-- THE ID IS ACCESSED HERE

      if (uid != null) {
        final data = {'checkInTimestamp': FieldValue.serverTimestamp()};
        final collection =
            Platform.isAndroid ? 'fcmTokensAndroid' : 'fcmTokensIos';
        // The 'uid' is used here to update the user's last active time
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(uid) // <-- USED HERE
            .update(data);
        _log.info('User check-in updated');
      }
    } catch (e) {
      _log.warning('Check-in failed: $e');
    }
  }

  // --- Dependencies & Lifecycle ---

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