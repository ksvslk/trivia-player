// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:games_services/games_services.dart' as gs;
import 'package:games_services/games_services.dart';
import 'package:logging/logging.dart';

/// Allows awarding achievements and leaderboard scores,
/// and also showing the platforms' UI overlays for achievements
/// and leaderboards.
///
/// A facade of `package:games_services`.
class GamesServicesController {
  final achievementheElizabethII = "CgkIw8SV_cYeEAIQAg";
  final achievementTarantino = "CgkIw8SV_cYeEAIQAw";
  final achievementDaVinci = "CgkIw8SV_cYeEAIQBA";
  final achievementBeethoven = "CgkIw8SV_cYeEAIQBQ";
  final achievementTyson = "CgkIw8SV_cYeEAIQBg";

  static final Logger _log = Logger('GamesServicesController');
  final Completer<bool> _signedInCompleter = Completer();
  Future<bool> get signedIn => _signedInCompleter.future;

  /// Unlocks an achievement on Game Center / Play Games.
  ///
  /// You must provide the achievement ids via the [iOS] and [android]
  /// parameters.
  ///
  /// Does nothing when the game isn't signed into the underlying
  /// games service.
  Future<void> awardAchievement({required String achievementId}) async {
    if (!await signedIn) {
      _log.warning('Trying to award achievement when not logged in.');
      return;
    }

    try {
      await gs.GamesServices.unlock(
        achievement: gs.Achievement(
          androidID: achievementId,
          iOSID: achievementId,
        ),
      );
    } catch (e) {
      _log.severe('Cannot award achievement: $e');
    }
  }

  Future<void> signInWithCredential() async {
    await _signInAnonymously();
    try {
      final UserCredential? credential = await _getPlatformCredential();
      if (credential?.user?.uid == null) {
        await _signInAnonymously();
      }
    } catch (e) {
      await _signInAnonymously();
    }
  }

  Future<UserCredential?> _getPlatformCredential() async {
    try {
      if (Platform.isAndroid) {
        final authCode = await GameAuth.getAuthCode(
            "1049845129795-tk1o75fqgu4j4bbgf0c10te6kgkg46tr.apps.googleusercontent.com");
        if (authCode == null) return null;

        return FirebaseAuth.instance.signInWithCredential(
          PlayGamesAuthProvider.credential(serverAuthCode: authCode),
        );
      }

      if (Platform.isIOS) {
        return FirebaseAuth.instance.signInWithCredential(
          GameCenterAuthProvider.credential(),
        );
      }
    } catch (err) {
      return null;
    }
  }

  Future<void> _signInAnonymously() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      _log.log(Level.WARNING, 'Anonymous authentication failed: $e');
    }
  }

  /// Signs into the underlying games service.
  Future<void> initialize() async {
    try {
      await gs.GamesServices.signIn().then((onValue) {
        signInWithCredential();
      }).onError((err, st) {
        _signInAnonymously();
      });
      // The API is unclear so we're checking to be sure. The above call
      // returns a String, not a boolean, and there's no documentation
      // as to whether every non-error result means we're safely signed in.
      final signedIn = await gs.GamesServices.isSignedIn;
      _signedInCompleter.complete(signedIn);

      //final savedGame = await gs.GamesServices.loadGame(name: "a");
      //final saveGameJson = savedGame.jsify();
    } catch (e) {
      _log.severe('Cannot log into GamesServices: $e');
      _signedInCompleter.complete(false);
    }
  }

  /// Launches the platform's UI overlay with achievements.
  Future<void> showAchievements() async {
    if (!await signedIn) {
      _log.severe('Trying to show achievements when not logged in.');
      return;
    }

    try {
      await gs.GamesServices.showAchievements();
    } catch (e) {
      _log.severe('Cannot show achievements: $e');
    }
  }

  Future<void> unlockAchievementForLevel(int nr) async {
    switch (nr) {
      case 12:
        awardAchievement(achievementId: achievementheElizabethII);
      case 31:
        awardAchievement(achievementId: achievementTarantino);
      case 64:
        awardAchievement(achievementId: achievementDaVinci);
      case 79:
        awardAchievement(achievementId: achievementBeethoven);
      case 95:
        awardAchievement(achievementId: achievementTyson);
    }
  }


}