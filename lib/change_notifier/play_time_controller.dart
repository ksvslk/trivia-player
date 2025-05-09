import 'dart:async';
import 'package:operation_veritas/persistence/settings_controller.dart';

/*
  New timer system
  ------------------

  Save 2 values to prefs:
  - Play time end
  - Lock time end

  Have one Ticker in settings that checks:
    1. Play time ended?
    2. Lock time ended?

  State must be arranged so Play time end time and Lock time end time
  cannot be set to a normal value in prefs. Either must be -1 at all times.
  So when starting Play time end is set, and lock time end must be -1.
  When play time reaches end then lock time end is set and play time end is set to -1.
  All these operations must be made in a transactional manner.
  
*/
// Any improvements we can make to this class AI?
class PlayTimeController {
  final SettingsController _settingsController;
  late Timer _timer;

  final _lockTimeEndController = StreamController<int>.broadcast();
  Stream<int> get onLockTimeUpdate => _lockTimeEndController.stream;

  final _playTimeEndedController = StreamController<void>.broadcast();
  Stream<void> get onPlayTimeEnded => _playTimeEndedController.stream;

  late int lockTimeEnd;
  late int playTimeEnd;

  PlayTimeController(this._settingsController) {
    initalize();
  }

  void initalize() async {
    lockTimeEnd = await _settingsController.getLockTimeEnd();
    playTimeEnd = await _settingsController.getPlayTimeEnd();
    if (lockTimeEnd == -1 && playTimeEnd == -1) {
      await _settingsController.savePlayTimeEnd();
    }
    _timer = Timer.periodic(Duration(seconds: 1), handleTick);
  }

  void handleTick(Timer timer) async {
    final nowRef = DateTime.now().toUtc().millisecondsSinceEpoch;

    assert(lockTimeEnd == -1 && playTimeEnd == -1);

    if (lockTimeEnd > -1 && nowRef >= lockTimeEnd) {
      // Lock time has elapsed
      await _settingsController.saveLockTimeEnd(disable: true);
      playTimeEnd = await _settingsController.getPlayTimeEnd();
      lockTimeEnd = await _settingsController.getLockTimeEnd();
      _lockTimeEndController.add(0);
    } else if (playTimeEnd > -1 && nowRef >= playTimeEnd) {
      // Play time has elapsed
      await _settingsController.savePlayTimeEnd(disable: true);
      lockTimeEnd = await _settingsController.getLockTimeEnd();
      playTimeEnd = await _settingsController.getPlayTimeEnd();
      _playTimeEndedController.add(null);
    }
  }

  dispose() {
    _timer.cancel();
  }
}
