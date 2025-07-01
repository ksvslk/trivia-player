// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:operation_veritas/constants.dart';
import 'settings_persistence.dart';

/// An class that holds settings like [playerName] or [musicOn],
/// and saves them to an injected persistence store.
class SettingsController {
  final Logger _log = Logger('SettingsController');

  final SettingsPersistence _persistence;

  /// Whether or not the sound is on at all. This overrides both music
  /// and sound.

  ValueNotifier<bool> soundsOn = ValueNotifier(false);
  ValueNotifier<int> seedColor = ValueNotifier(C.defaultThemeColor.toARGB32());
  ValueNotifier<bool> isBlockedExpanded = ValueNotifier(false);
  bool isEulaAccepted = false;
  ValueNotifier<bool> isColorsExpanded = ValueNotifier(false);
  ValueNotifier<int> lockTimeEnd = ValueNotifier(0);
  ValueNotifier<String> formattedTimeLeft = ValueNotifier("00:00");
  Timer? _lockTimeCheckTimer;

  /// Creates a new instance of [SettingsController] backed by [persistence].
  SettingsController({
    required SettingsPersistence persistence,
  }) : _persistence = persistence;

  /// Asynchronously loads values from the injected persistence store.
  Future<void> loadStateFromPersistence() async {
    _lockTimeCheckTimer?.cancel();

    await Future.wait([
      _persistence.getSoundsOn().then((value) => soundsOn.value = value),
      _persistence.getSeedColor().then((value) => seedColor.value = value),
      _persistence
          .getBlockedExpanded()
          .then((value) => isBlockedExpanded.value = value),
      _persistence
          .getColorsExpanded()
          .then((value) => isColorsExpanded.value = value),
      _persistence
          .getEulaAccepted()
          .then((value) => isEulaAccepted = value),
      _persistence.getLockTimeEnd().then((value) => lockTimeEnd.value = value)
    ]);
    _log.info("loadStateFromPersistence");
    _lockTimeCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final currentTime = DateTime.now().toUtc().millisecondsSinceEpoch;
      if (lockTimeEnd.value > 0 && currentTime >= lockTimeEnd.value) {
        saveLockTimeEnd(newValue: 0);
      }
    });
  }

  void dispose() {
    _lockTimeCheckTimer?.cancel();
    _lockTimeCheckTimer = null;
    soundsOn.dispose();
    seedColor.dispose();
    isBlockedExpanded.dispose();
    isColorsExpanded.dispose();
    lockTimeEnd.dispose();
  }

  Future<void> saveBlockedExpanded(bool expanded) async {
    _persistence.saveBlockedExpanded(expanded);
  }

  Future<void> setEulaAccepted() async {
    isEulaAccepted = true;
    _persistence.setEulaAccepted();
  }

  Future<void> saveColorsExpanded(bool expanded) async {
    _persistence.saveColorsExpanded(expanded);
  }

  void changeSeedColor(Color color) {
    seedColor.value = color.toARGB32();
    _persistence.saveSeedColor(seedColor.value);
  }

  void toggleSoundsOn() {
    soundsOn.value = !soundsOn.value;
    _persistence.saveSoundsOn(soundsOn.value);
  }

  Future<void> setToken(String token) async {
    _persistence.setToken(token);
  }

  Future<String> getToken() async {
    return await _persistence.getToken();
  }

  Future<Map<String, String>> getBanned() async {
    return await _persistence.getBanned();
  }

  Future<Map<String, String>> setBan(String id, String name) async {
    return await _persistence.setBan(id, name);
  }

  Future<Map<String, String>> removeBan(String id) async {
    return await _persistence.removeBan(id);
  }

  Future<int> getLockTimeEnd() async {
    return await _persistence.getLockTimeEnd();
  }

  Future<void> saveLockTimeEnd({int newValue = -1}) async {
    lockTimeEnd.value = await _persistence.saveLockTimeEnd(newValue);
  }

  Future<int> getRoundsWithoutAds() async {
    return await _persistence.getRoundsWithoutAds();
  }

  Future<void> increaseRoundsWithoutAds() async {
    await _persistence.increaseRoundsWithoutAds();
  }

  Future<void> resetRoundsWithoutAds() async {
    await _persistence.resetRoundsWithoutAds();
  }
}
