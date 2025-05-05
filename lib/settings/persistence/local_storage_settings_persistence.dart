// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  Future<Set<String>> getBanned() async {
    final prefs = await instanceFuture;
    return prefs.getStringList('bannedUsers')?.toSet() ?? Set.of({});
  }
  
  @override
  Future<void> setBanned(String id) async {
    final prefs = await instanceFuture;
    final bannedUsers = prefs.getStringList('bannedUsers')?.toSet() ?? <String>{};
    bannedUsers.add(id);
    await prefs.setStringList('bannedUsers', bannedUsers.toList());
  }

}
