// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

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
  Future<Map<String, String>> setBan(String id, String name) async {
    final prefs = await instanceFuture;
    final bannedMapString = prefs.getString('bannedUsers');
    final bannedMapObject =
        Map<String, String>.from(jsonDecode(bannedMapString ?? "{}"));
    bannedMapObject[id] = name;
    String bannedMapStringUpdated = jsonEncode(bannedMapObject);
    await prefs.setString('bannedUsers', bannedMapStringUpdated);
    return bannedMapObject;
  }

  @override
  Future<Map<String, String>> removeBan(String id) async {
    final prefs = await instanceFuture;
    final bannedMapString = prefs.getString('bannedUsers');
    final bannedMapObject =
        Map<String, String>.from(jsonDecode(bannedMapString ?? "{}"));
    bannedMapObject.remove(id);
    String bannedMapStringUpdated = jsonEncode(bannedMapObject);
    await prefs.setString('bannedUsers', bannedMapStringUpdated);
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
  Future<int> getPlayTimeEnd() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('playTimeEnd') ?? -1;
  }

  @override
  Future<void> savePlayTimeEnd(bool disable) async {
    final prefs = await SharedPreferences.getInstance();
    if (disable) {
      await prefs.setInt('playTimeEnd', -1);
      return;
    }
    final playTimeEnd = DateTime.now()
        .add(Duration(seconds: 300))
        .toUtc()
        .millisecondsSinceEpoch;
    await prefs.setInt('playTimeEnd', playTimeEnd);
  }

  @override
  Future<int> getLockTimeEnd() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('lockTimeEnd') ?? -1;
  }

  @override
  Future<void> saveLockTimeEnd(bool disable) async {
    final prefs = await SharedPreferences.getInstance();
    if (disable) {
      await prefs.setInt('lockTimeEnd', -1);
      return;
    }
    final lockTimeEnd = DateTime.now()
        .add(Duration(seconds: 900))
        .toUtc()
        .millisecondsSinceEpoch;
    await prefs.setInt('lockTimeEnd', lockTimeEnd);
  }
  
}
