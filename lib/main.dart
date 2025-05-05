import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:logging/logging.dart';
import 'package:operation_veritas/change_notifier/blocked_players.dart';
import 'package:operation_veritas/chat_page/trivia_chat.dart';
import 'package:operation_veritas/change_notifier/message_visibility.dart';
import 'package:operation_veritas/change_notifier/trivia_service.dart';
import 'package:operation_veritas/settings/blocked_players_dialog.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as dev;
import 'settings/persistence/settings_persistence.dart';
import 'settings/persistence/local_storage_settings_persistence.dart';
import 'app_lifecycle/app_lifecycle.dart';
import 'settings/settings_controller.dart';
import 'audio/audio_controller.dart';
import 'package:firebase_core/firebase_core.dart';

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
          ChangeNotifierProvider(
            create: (context) => TriviaService(),
          ),
          ChangeNotifierProvider(
            create: (context) => BannerMessageVisibility(),
          ),
          ChangeNotifierProxyProvider<SettingsController, BlockedPlayers>(
            create: (_) => BlockedPlayers(),
            update: (_, settingsController, blockedPlayers) {
              blockedPlayers!.updateSettings(settingsController);
              return blockedPlayers;
            },
          ),
        ],
        builder: (context, child) {
          final settingsController = context.read<SettingsController>();

          return ValueListenableBuilder(
            valueListenable: settingsController.seedColor,
            builder: (context, changingSeedColor, _) {
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.portraitUp,
                DeviceOrientation.portraitDown,
              ]);
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                  overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);

              final lightTheme = ThemeData(
                scaffoldBackgroundColor: Colors.white,
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Color(changingSeedColor),
                  brightness: Brightness.light,
                ),
                fontFamily: 'Inter',
              );

              final darkTheme = ThemeData(
                scaffoldBackgroundColor: Colors.black,
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Color(changingSeedColor),
                  brightness: Brightness.dark,
                ),
                fontFamily: 'Inter',
              );

              return MaterialApp(
                title: 'Trivia Chat',
                debugShowCheckedModeBanner: false,
                theme: lightTheme,
                darkTheme: darkTheme,
                builder: (BuildContext context, Widget? child) {
                  final ThemeData resolvedTheme = Theme.of(context);
                  final bool isDarkMode =
                      resolvedTheme.brightness == Brightness.dark;

                  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
                    systemNavigationBarColor: resolvedTheme.colorScheme.surface,
                    systemNavigationBarDividerColor:
                        resolvedTheme.colorScheme.surface,
                    systemNavigationBarIconBrightness:
                        isDarkMode ? Brightness.light : Brightness.dark,
                  ));

                  return child!;
                },
                home: Builder(
                  builder: (context) => Scaffold(
                    onDrawerChanged: (isOpened) {
                      if (!isOpened) {
                        // Use a post-frame callback to ensure unfocus happens after the build
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          FocusScope.of(context).unfocus();
                        });
                      }
                    },
                    drawer: Drawer(
                      child: SafeArea(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            ListTile(
                              title: const Text('Blocked Users'),
                              onTap: () {
                                Navigator.pop(context); // Close drawer
                                showDialog(
                                  context: context,
                                  builder: (_) => const BlockedPlayersDialog(),
                                );
                              },
                            ),
                            ListTile(
                              title: const Text('Sound'),
                              onTap: () {},
                            ),
                            ListTile(
                              title: const Text('Credits'),
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                    body: TriviaChat(
                      name: "An_${Random().nextInt(1000)}",
                      userColor: _generateRandomDarkerColor(),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Function to generate a random darker color
  Color _generateRandomDarkerColor() {
    Random random = Random();
    // Generate random RGB values and adjust to ensure it's dark
    int r =
        random.nextInt(100) + 50; // Ensuring a darker value (50 to 150 range)
    int g = random.nextInt(100) + 50;
    int b = random.nextInt(100) + 50;

    return Color.fromRGBO(r, g, b, 1);
  }
}
