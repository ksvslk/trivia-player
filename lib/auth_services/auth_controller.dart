import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:games_services/games_services.dart' as gs;
import 'package:games_services/games_services.dart';
import 'package:logging/logging.dart';
import 'package:operation_veritas/extensions.dart';

enum AuthState { none, authenticated, progress }

class AuthController extends ChangeNotifier {
  static final Logger _log = Logger('AuthController');

  final String androidRoundLeaderboard = 'CgkIxYLalKEVEAIQAQ';
  final String androidQuestionLeaderboard = 'CgkIxYLalKEVEAIQAg';

  final String iosdRoundLeaderboard = 'CgkIxYLalKEVEAIQAQ';
  final String iosQuestionLeaderboard = 'CgkIxYLalKEVEAIQAg';

  AuthState _authState = AuthState.none;
  User? _currentUser;
  String _playerName = "";
  bool _isGameServicesAvailable = false;
  String? gameServicesPlayerId;

  AuthState get authState => _authState;
  User? get currentUser => _currentUser;
  String get playerName => _playerName;
  bool get isLeaderboardAvailable => _isGameServicesAvailable;

  AuthController() {
    initialize();
  }

  Future<void> initialize() async {
    _authState = AuthState.progress;
    notifyListeners();
    _log.info('Starting authentication process.');

    _log.info('Attempting Game Services login...');
    try {
      _log.info('Attempting single Game Services login...');

      await gs.GamesServices.signIn();
      _log.info('Native Game Services sign-in initiated successfully.');
      gameServicesPlayerId = await gs.GamesServices.getPlayerID();
      _log.info("ASFD PID:  $gameServicesPlayerId");

      final AuthCredential? credential = await _getPlatformCredential();

      if (credential != null) {
        _log.info('Platform credential obtained. Signing into Firebase...');
        final UserCredential userCredential = await FirebaseAuth.instance
            .signInWithCredential(credential);

        if (userCredential.user != null) {
          _log.info('Successfully signed into Firebase with Game Services.');
          _log.info("ASFD UID:  ${userCredential.user?.uid}");
          _currentUser = userCredential.user;
          _playerName = _currentUser?.displayName ?? "-";
          _authState = AuthState.authenticated;
          _isGameServicesAvailable = true;
        } else {
          _log.warning('Firebase signInWithCredential returned null user.');
        }
      } else {
        _log.warning(
          'Failed to obtain platform credential after native sign-in.',
        );
      }
    } catch (e) {
      _log.warning('Game Services login failed: $e');
    }

    if (!_isGameServicesAvailable) {
      _log.info(
        'Game Services login failed. Falling back to anonymous login...',
      );
      try {
        final UserCredential anonCredential = await FirebaseAuth.instance
            .signInAnonymously();

        _log.info('Successfully signed in anonymously.');
        _currentUser = anonCredential.user;
        _playerName = _currentUser?.uid.generateLifelikeUsername() ?? "-";
        _authState = AuthState.authenticated;
      } catch (e) {
        _log.severe('Anonymous login failed: $e');
        _currentUser = null;
        _playerName = "-";
        _authState = AuthState.none;
      }
    }

    notifyListeners();
    _log.info('Authentication process finished. State: $_authState');
  }

  Future<AuthCredential?> _getPlatformCredential() async {
    try {
      if (Platform.isAndroid) {
        // The empty string might need adjustment based on your specific setup
        final authCode = await GameAuth.getAuthCode(
          "730456293701-nepun8t1d5u90rm9qrohhjbb9ujp7d5o.apps.googleusercontent.com",
        );
        if (authCode == null) {
          _log.warning('Android GameAuth.getAuthCode returned null.');
          return null;
        }
        return PlayGamesAuthProvider.credential(serverAuthCode: authCode);
      } else if (Platform.isIOS) {
        return GameCenterAuthProvider.credential();
      } else {
        _log.warning(
          'Current platform is not Android or iOS. Game Services credentials not supported.',
        );
        return null;
      }
    } catch (err) {
      _log.warning('Failed to get platform auth credential: $err');
      return null;
    }
  }

  void showLeaderboard() async {
    await Leaderboards.showLeaderboards(
      androidLeaderboardID: "",
      iOSLeaderboardID: "",
    );
  }

  bool get isAuthenticated =>
      _authState == AuthState.authenticated && _currentUser != null;

  Future<int> _getPlayerQuestionScore() async {
    final result = await Leaderboards.getPlayerScoreObject(
      iOSLeaderboardID: iosQuestionLeaderboard,
      androidLeaderboardID: androidQuestionLeaderboard,
      scope: PlayerScope.global,
      timeScope: TimeScope.allTime,
    );
    _log.info("Score: ${result?.rawScore}");
    var currentScore = 0;
    if (result != null) {
      currentScore = result.rawScore;
    }
    return currentScore;
  }

  Future<int> _getPlayerRoundScore() async {
    final result = await Leaderboards.getPlayerScoreObject(
      iOSLeaderboardID: iosdRoundLeaderboard,
      androidLeaderboardID: androidRoundLeaderboard,
      scope: PlayerScope.global,
      timeScope: TimeScope.allTime,
    );
    _log.info("Score: ${result?.rawScore}");
    var currentScore = 0;
    if (result != null) {
      currentScore = result.rawScore;
    }
    return currentScore;
  }

  void increaseQuestionScore() async {
    final currentQuestionScore = await _getPlayerQuestionScore();
    final newScore = currentQuestionScore + 1;
    await Leaderboards.submitScore(
      score: Score(
        androidLeaderboardID: androidQuestionLeaderboard,
        iOSLeaderboardID: iosQuestionLeaderboard,
        value: newScore,
      ),
    );
    _log.info("Old question score: $currentQuestionScore");
    _log.info("New question score: $newScore");
  }

  void increaseRoundScore() async {
    final currentRoundScore = await _getPlayerRoundScore();
    final newScore = currentRoundScore + 1;
    await Leaderboards.submitScore(
      score: Score(
        androidLeaderboardID: androidRoundLeaderboard,
        iOSLeaderboardID: iosdRoundLeaderboard,
        value: newScore,
      ),
    );
    _log.info("Old round score: $currentRoundScore");
    _log.info("New round score: $newScore");
  }

  void submitRoundScore(int newScore) async {
   await Leaderboards.submitScore(
      score: Score(
        androidLeaderboardID: androidRoundLeaderboard,
        iOSLeaderboardID: iosdRoundLeaderboard,
        value: newScore,
      ),
    );
  }

    void submitQuestionScore(int newScore) async {
   await Leaderboards.submitScore(
      score: Score(
        androidLeaderboardID: androidQuestionLeaderboard,
        iOSLeaderboardID: iosQuestionLeaderboard,
        value: newScore,
      ),
    );
  }
}
