// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:operation_veritas/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_persistence.dart';

/// An implementation of [SettingsPersistence] that uses
/// `package:shared_preferences`.
class LocalStorageSettingsPersistence extends SettingsPersistence {
  final Future<SharedPreferences> instanceFuture =
      SharedPreferences.getInstance();

  @override
  Future<bool> getSoundsOn() async {
    final prefs = await instanceFuture;
    return prefs.getBool('soundsOn') ?? true;
  }

  @override
  Future<int> getSeedColor() async {
    final prefs = await instanceFuture;
    return prefs.getInt('seedColor') ?? C.defaultThemeColor.toARGB32();
  }

  @override
  Future<void> saveSoundsOn(bool value) async {
    final prefs = await instanceFuture;
    await prefs.setBool('soundsOn', value);
  }

  @override
  Future<void> saveSeedColor(int value) async {
    final prefs = await instanceFuture;
    await prefs.setInt('seedColor', value);
  }

  @override
  Future<String> getToken() async {
    final prefs = await instanceFuture;
    return prefs.getString('fcmToken') ?? "";
  }

  @override
  Future<void> setToken(String value) async {
    final prefs = await instanceFuture;
    await prefs.setString('fcmToken', value);
  }

  @override
  Future<Map<String, String>> getBanned() async {
    final prefs = await instanceFuture;
    final bannedMapString = prefs.getString('bannedUsers');
    final bannedMapObject =
        Map<String, String>.from(jsonDecode(bannedMapString ?? "{}"));
    return bannedMapObject;
  }

  @override
  Future<bool> getBlockedExpanded() async {
    final prefs = await instanceFuture;
    return prefs.getBool('blockedExpanded') ?? false;
  }

  @override
  Future<bool> getColorsExpanded() async {
    final prefs = await instanceFuture;
    return prefs.getBool('colorsExpanded') ?? false;
  }

  @override
  Future<void> saveBlockedExpanded(bool value) async {
    final prefs = await instanceFuture;
    await prefs.setBool('blockedExpanded', value);
  }

  @override
  Future<void> saveColorsExpanded(bool value) async {
    final prefs = await instanceFuture;
    await prefs.setBool('colorsExpanded', value);
  }

  @override
  Future<int> getLockTimeEnd() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('lockTimeEnd') ?? 0;
  }

  @override
  Future<int> saveLockTimeEnd(int newValue) async {
    final prefs = await SharedPreferences.getInstance();
    final lockTimeSeconds = FirebaseRemoteConfig.instance.getInt(C.lockTimeLimitSecondsTag);
    final lockTimeEnd = newValue == -1
        ? DateTime.now()
            .add(Duration(seconds: lockTimeSeconds))
            .toUtc()
            .millisecondsSinceEpoch
        : 0;
    await prefs.setInt('lockTimeEnd', lockTimeEnd);
    return lockTimeEnd;
  }
  
  @override
  Future<int> getRoundsWithoutAds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('roundsWithoutAds') ?? 0;
  }
  
  @override
  Future<void> increaseRoundsWithoutAds() async {
    final prefs = await SharedPreferences.getInstance();
    final currentRoundsWithoutAds = prefs.getInt('roundsWithoutAds') ?? 0;
    await prefs.setInt('roundsWithoutAds', currentRoundsWithoutAds + 1);
  }
  
  @override
  Future<void> resetRoundsWithoutAds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('roundsWithoutAds', 0);
  }
  
  @override
  Future<bool> getEulaAccepted() async {
    final prefs = await instanceFuture;
    return prefs.getBool('eulaAccepted') ?? false;
  }
  
  @override
  Future<void> setEulaAccepted() async {
    final prefs = await instanceFuture;
    await prefs.setBool('eulaAccepted', true);
  }

}
