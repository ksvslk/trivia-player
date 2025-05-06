import 'package:flutter/material.dart';
import 'package:operation_veritas/settings/settings_controller.dart';

class BlockedPlayers extends ChangeNotifier {
  BlockedPlayers();

  late SettingsController _settingsController;

  Map<String, String> _blockedPlayers = <String, String>{};
  Map<String, String> get blockedPlayers => _blockedPlayers;

  add(String uid, String name) async {
    _blockedPlayers = await _settingsController.setBan(uid, name);
    notifyListeners();
  }

  remove(String uid) async {
    _blockedPlayers = await _settingsController.removeBan(uid);
    notifyListeners();
  }

  void updateSettings(SettingsController settingsController) async {
    _settingsController = settingsController;
    _blockedPlayers = await _settingsController.getBanned();
    notifyListeners();
  }
}
