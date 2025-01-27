import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:logging/logging.dart';
import 'package:operation_veritas/name_prompt_screen.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as dev;
import 'settings/persistence/settings_persistence.dart';
import 'settings/persistence/local_storage_settings_persistence.dart';
import 'app_lifecycle/app_lifecycle.dart';
import 'settings/settings_controller.dart';
import 'audio/audio_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


void setupConnectionTracking() {
  final connectedRef = FirebaseDatabase.instance.ref(".info/connected");
  final playerCountRef = FirebaseDatabase.instance.ref("player_count");

  connectedRef.onValue.listen((event) {
    final connected = event.snapshot.value as bool? ?? false;
    if (connected) {
      
      // Setup disconnect handler first
      playerCountRef.onDisconnect().set(ServerValue.increment(-1));
      
      // Correct transaction return type
      playerCountRef.runTransaction((Object? currentValue) {
        final currentCount = (currentValue ?? 0) as int;
        return Transaction.success(currentCount + 1);
      });
    }
  });
}

Future<void> main() async {
  //debugPaintSizeEnabled = true;
  // Subscribe to log messages.
  Logger.root.onRecord.listen((record) {
    if (record.level >= Level.INFO) {
      dev.log(
        record.message,
        time: record.time,
        level: record.level.value,
        name: record.loggerName,
        zone: record.zone,
        error: record.error,
        stackTrace: record.stackTrace,
      );
    }
  });

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await FirebaseAuth.instance.signInAnonymously();
  setupConnectionTracking();

  _log.info('Going full screen');
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    MyApp(settingsPersistence: LocalStorageSettingsPersistence()),
  );
}

Logger _log = Logger('main.dart');
//Color.fromARGB(255, 40, 0, 161)
//Color.fromARGB(255, 255, 0, 187)
//Color.fromARGB(255, 0, 255, 0)
//Color.fromARGB(255, 0, 255, 255)
//Color.fromARGB(255, 0, 0, 255)
//Color.fromARGB(255, 255, 255, 0)
//Color.fromARGB(255, 255, 0, 0)

class MyApp extends StatelessWidget {
  final SettingsPersistence settingsPersistence;

  const MyApp({
    super.key,
    required this.settingsPersistence,
  });

  @override
  Widget build(BuildContext context) {
    return AppLifecycleObserver(
        child: MultiProvider(
      providers: [
        Provider<SettingsController>(
          lazy: false,
          create: (context) => SettingsController(
            persistence: settingsPersistence,
          )..loadStateFromPersistence(),
        ),
        ProxyProvider2<SettingsController, ValueNotifier<AppLifecycleState>,
            AudioController>(
          // Ensures that the AudioController is created on startup,
          // and not "only when it's needed", as is default behavior.
          // This way, music starts immediately.
          lazy: false,
          create: (context) => AudioController()..initialize(),
          update: (context, settings, lifecycleNotifier, audio) {
            if (audio == null) throw ArgumentError.notNull();
            audio.attachSettings(settings);
            audio.attachLifecycleNotifier(lifecycleNotifier);
            return audio;
          },
          dispose: (context, audio) => audio.dispose(),
        ),
      ],
      builder: (context, child) {
        final settingsController = context.read<SettingsController>();

        return ValueListenableBuilder(
          valueListenable: settingsController.seedColor,
          builder: (context, changingSeedColor, child) {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
            return MaterialApp(
                title: 'Trivia Chat',
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                    scaffoldBackgroundColor: Colors.white,
                    useMaterial3: true,
                    // Define the default brightness and colors.
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: Color(changingSeedColor),
                      brightness: Brightness.light,
                    ),
                    fontFamily: 'Inter'),
                darkTheme: ThemeData(
                    scaffoldBackgroundColor: Colors.black,
                    useMaterial3: true,
                    // Define the default brightness and colors.
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: Color(changingSeedColor),
                      brightness: Brightness.dark,
                    ),
                    fontFamily: 'Inter'),
                home: const Scaffold(
                  body: NamePromptScreen(),
                ));
          },
        );
      },
    ));
  }
}
