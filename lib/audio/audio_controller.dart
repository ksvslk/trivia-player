// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:operation_veritas/persistence/settings_controller.dart';
import 'package:sound_effect/sound_effect.dart';

import 'sounds.dart';

/// Allows playing music and sound. A facade to `package:audioplayers`.
class AudioController {
  static final _log = Logger('AudioController');

  SettingsController? _settings;
  ValueNotifier<AppLifecycleState>? _lifecycleNotifier;
  final _soundEffect = SoundEffect();

  AudioController({int polyphony = 2});

  void attachLifecycleNotifier(
    ValueNotifier<AppLifecycleState> lifecycleNotifier,
  ) {
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);
    lifecycleNotifier.addListener(_handleAppLifecycle);
    _lifecycleNotifier = lifecycleNotifier;
  }

  void attachSettings(SettingsController settingsController) {
    if (_settings == settingsController) {
      // Already attached to this instance. Nothing to do.
      return;
    }

    // Remove handlers from the old settings controller if present
    final oldSettings = _settings;
    if (oldSettings != null) {
      oldSettings.soundsOn.removeListener(_soundsOnHandler);
    }

    _settings = settingsController;

    // Add handlers to the new settings controller
    settingsController.soundsOn.addListener(_soundsOnHandler);
  }

  void dispose() {
    _log.info("dispose");
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);
    _stopAllSound();
    _soundEffect.release();
  }

  /// Preloads all sound effects.
  Future<void> initialize() async {
    _log.info('Preloading sound effects');
    await _soundEffect.initialize();
    await Future.wait(
      SfxType.values
          .expand(
            (sfxType) => soundTypeToFilename(
              sfxType,
            ).map((path) => (sfxType: sfxType, path: path)),
          )
          .map(
            (record) =>
                _soundEffect.load(record.sfxType.name, 'assets/sfx/${record.path}'),
          ),
    );
  }

  void playSfx(SfxType type) {

    final soundsOn = _settings?.soundsOn.value ?? false;
    if (!soundsOn) {
      return;
    }
    _soundEffect.play(type.name);
  }

  void _handleAppLifecycle() {
    switch (_lifecycleNotifier!.value) {
      case AppLifecycleState.paused:
        _stopAllSound();
      case AppLifecycleState.detached:
        _stopAllSound();
      case AppLifecycleState.hidden:
        _stopAllSound();
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
        _stopAllSound();
        break;
    }
  }

  void _soundsOnHandler() {
  
  }

  void _stopAllSound() {
    _log.info('Stopping all sound');
  }
}
