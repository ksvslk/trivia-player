// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:operation_veritas/constants.dart';
import 'settings_persistence.dart';

/// An class that holds settings like [playerName] or [musicOn],
/// and saves them to an injected persistence store.
class SettingsController {
  final SettingsPersistence _persistence;

  /// Whether or not the sound is on at all. This overrides both music
  /// and sound.

  ValueNotifier<bool> soundsOn = ValueNotifier(false);
  ValueNotifier<int> seedColor = ValueNotifier(C.defaultThemeColor.toARGB32());
  ValueNotifier<bool> isBlockedExpanded = ValueNotifier(false);
  ValueNotifier<bool> isColorsExpanded = ValueNotifier(false);

  /// Creates a new instance of [SettingsController] backed by [persistence].
  SettingsController({required SettingsPersistence persistence})
      : _persistence = persistence;

  /// Asynchronously loads values from the injected persistence store.
  Future<void> loadStateFromPersistence() async {
    await Future.wait([
      _persistence.getSoundsOn().then((value) => soundsOn.value = value),
      _persistence.getSeedColor().then((value) => seedColor.value = value),
      _persistence
          .getBlockedExpanded()
          .then((value) => isBlockedExpanded.value = value),
      _persistence
          .getColorsExpanded()
          .then((value) => isColorsExpanded.value = value),
    ]);
  }

  Future<void> saveBlockedExpanded(bool expanded) async {
    await _persistence.saveBlockedExpanded(expanded);
  }

  Future<void> saveColorsExpanded(bool expanded) async {
    await _persistence.saveColorsExpanded(expanded);
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
    await _persistence.setToken(token);
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
}
