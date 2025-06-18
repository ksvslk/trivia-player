import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:operation_veritas/auth_services/auth_controller.dart';
import 'package:operation_veritas/persistence/settings_controller.dart';

class NotificationController {
  static final Logger _log = Logger('NotificationController');

  AuthController? _authController;
  SettingsController? _settings;
  ValueNotifier<AppLifecycleState>? _lifecycleNotifier;

  // We need to track the previous state inside this controller now
  AuthState? _previousAuthState;

  NotificationController() {
    _log.info('NotificationController has been initialized.'); // For debugging
  }

  Future<void> initialize() async {
    await askPermissions();
    if (Platform.isMacOS || Platform.isIOS) {
      await FirebaseMessaging.instance.getAPNSToken();
    }
    final oldToken = await FirebaseMessaging.instance.getToken();
    await checkAndStoreToken(oldToken ?? "");
    FirebaseMessaging.instance.onTokenRefresh
        .listen((fcmToken) {
          // Note: This callback is fired at each app startup and whenever a new
          // token is generated.
          checkAndStoreToken(fcmToken);
        })
        .onError((err) {
          _log.log(Level.WARNING, "Error getting new token: $err");
        });
  }

  Future<void> askPermissions() async {
    //if (Platform.isIOS && _apnsToken == null) return;
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

  Future<void> checkAndStoreToken(String token) async {
    // Check whether the retrieved token matches the one on your server for this user's device
    final tokenStored = await _settings?.getToken() ?? '';
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null &&
        token != '' &&
        (tokenStored == '' || tokenStored != token)) {
      // If you have your own server, call API to send the above token and Date() for this user's device

      // Example shown below with Firestore
      // Add token and timestamp to Firestore for this user
      final deviceToken = {
        'token': token,
        'timestamp': FieldValue.serverTimestamp(),
        'checkInTimestamp': FieldValue.serverTimestamp(),
      };

      // Get user ID from Firebase Auth or your own server
      await FirebaseFirestore.instance
          .collection(Platform.isAndroid ? 'fcmTokensAndroid' : 'fcmTokensIos')
          .doc(uid)
          .set(deviceToken);

      // Save locally
      await _settings?.setToken(token);
    }
  }

  void attachLifecycleNotifier(
    ValueNotifier<AppLifecycleState> lifecycleNotifier,
  ) {
    if (_lifecycleNotifier == lifecycleNotifier) return; // Avoid re-attaching
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);
    lifecycleNotifier.addListener(_handleAppLifecycle);
    _lifecycleNotifier = lifecycleNotifier;
  }

  /// Establishes a subscription to the AuthController.
  void linkAuthController(AuthController authController) {
    // If we're already listening to this instance, do nothing.
    if (_authController == authController) return;

    // Before linking the new one, remove the listener from the old one (if it exists).
    _authController?.removeListener(_onAuthStateChanged);

    // Link to the new controller and subscribe to its changes.
    _authController = authController;
    _authController?.addListener(_onAuthStateChanged);

    // Immediately check the state in case auth happened before this link was made.
    _onAuthStateChanged();
  }

  void _onAuthStateChanged() {
    final currentAuthState = _authController?.authState;

    // This checks for the TRANSITION
    if (_previousAuthState != AuthState.authenticated &&
        currentAuthState == AuthState.authenticated) {
      _log.info(
        "NotificationController detected login via listener! Checking in...",
      );
      checkInUser();
    }

    // Update our memory for the next time
    _previousAuthState = currentAuthState;
  }

  void _handleAppLifecycle() {
    if (_lifecycleNotifier?.value == AppLifecycleState.resumed) {
      if (_authController?.isAuthenticated == true) {
        _log.info('App resumed and user is authenticated. Checking in...');
        checkInUser();
      } else {
        _log.info(
          'App resumed, but user is not authenticated. Skipping check-in.',
        );
      }
    }
  }

  void checkInUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final checkInData = {'checkInTimestamp': FieldValue.serverTimestamp()};
      final collectionPath = Platform.isAndroid
          ? 'fcmTokensAndroid'
          : 'fcmTokensIos';
      await FirebaseFirestore.instance
          .collection(collectionPath)
          .doc(uid)
          .update(checkInData);
    }
  }

  void attachSettings(SettingsController settingsController) {
    if (_settings == settingsController) {
      // Already attached to this instance. Nothing to do.
      return;
    }
    _settings = settingsController;
  }

  void dispose() {
    _authController?.removeListener(_onAuthStateChanged);
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);
  }
}
