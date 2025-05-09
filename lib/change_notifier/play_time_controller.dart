import 'dart:async';
import 'package:operation_veritas/persistence/settings_controller.dart';

class PlayTimeController {
  final SettingsController _settingsController;
  late Timer _timer;

  final _lockTimeEndController = StreamController<int>.broadcast();
  Stream<int> get onLockTimeUpdate => _lockTimeEndController.stream;

  final _popupVisibilityController = StreamController<bool>.broadcast();
  Stream<bool> get onPopupVisibilityUpdate => _popupVisibilityController.stream;

  int lockTimeEnd = -1;
  int _playTimeEnd = -1;

  PlayTimeController(this._settingsController) {
    _initialize();
  }

  Future<void> _initialize() async {
    lockTimeEnd = await _settingsController.getLockTimeEnd();
    _playTimeEnd = await _settingsController.getPlayTimeEnd();
    if (lockTimeEnd == -1 && _playTimeEnd == -1) {
      await _settingsController.savePlayTimeEnd();
      _playTimeEnd = await _settingsController.getPlayTimeEnd();
    }
    _timer = Timer.periodic(const Duration(seconds: 1), _handleTick);
  }

  Future<void> _handleTick(Timer _) async {

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    final latestPlayTime = await _settingsController.getPlayTimeEnd();
    final latestLockTime = await _settingsController.getLockTimeEnd();

    _playTimeEnd = latestPlayTime;
    lockTimeEnd = latestLockTime;

    if (lockTimeEnd > -1 && now >= lockTimeEnd) {
      await transitionToPlayTime();
    } else if (_playTimeEnd > -1 && now >= _playTimeEnd) {
      await _transitionToLockTime();
    } else if (lockTimeEnd > -1) {
      _lockTimeEndController.add(lockTimeEnd - now);
    }
  }

  Future<void> transitionToPlayTime() async {
    await _settingsController.saveLockTimeEnd(disable: true);
    await _settingsController.savePlayTimeEnd();

    lockTimeEnd = await _settingsController.getLockTimeEnd();
    _playTimeEnd = await _settingsController.getPlayTimeEnd();

    _popupVisibilityController.add(false);
  }

  Future<void> _transitionToLockTime() async {

    await _settingsController.savePlayTimeEnd(disable: true);
    await _settingsController.saveLockTimeEnd();

    lockTimeEnd = await _settingsController.getLockTimeEnd();
    _playTimeEnd = await _settingsController.getPlayTimeEnd();

    _popupVisibilityController.add(true);
  }

  void dispose() {
    _timer.cancel();
    _lockTimeEndController.close();
    _popupVisibilityController.close();
  }
}
