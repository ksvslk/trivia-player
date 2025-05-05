import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:logging/logging.dart';
import 'package:operation_veritas/name_prompt_screen.dart';
import 'package:operation_veritas/change_notifier/message_visibility.dart';
import 'package:operation_veritas/change_notifier/trivia_service.dart';
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
         ChangeNotifierProvider(
          create: (context) => TriviaService(),
        ),
        ChangeNotifierProvider(
          create: (context) => BannerMessageVisibility(),
        ),
      ],
      builder: (context, child) {
        final settingsController = context.read<SettingsController>();

   return ValueListenableBuilder(
      valueListenable: settingsController.seedColor,
      builder: (context, changingSeedColor, child) {
        // Set preferred orientations and system UI modes here if needed
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);

        // Define your light and dark themes
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
          theme: lightTheme, // Provide the light theme
          darkTheme: darkTheme, // Provide the dark theme
          // themeMode: settingsController.themeMode, // You might have a themeMode setting too

          // Use the builder callback to access the theme applied by MaterialApp
          builder: (BuildContext context, Widget? child) {
            // Get the actual theme data that MaterialApp decided to use
            final ThemeData resolvedTheme = Theme.of(context);
            final bool isDarkMode = resolvedTheme.brightness == Brightness.dark;

            // *** Set the System UI Overlay Style here ***
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
              // Use colors from the resolved theme's colorScheme
              systemNavigationBarColor: isDarkMode
                  ? resolvedTheme.colorScheme.surface // Or another color for dark mode
                  : resolvedTheme.colorScheme.surface, // Or another color for light mode
              systemNavigationBarDividerColor: isDarkMode
                  ? resolvedTheme.colorScheme.surface
                  : resolvedTheme.colorScheme.surface,
              // Set icon brightness based on the resolved theme's brightness
              systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,

              // You can also set status bar colors here if needed,
              // also based on resolvedTheme.brightness
              // statusBarColor: Colors.transparent,
              // statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
              // statusBarBrightness: isDarkMode ? Brightness.light : Brightness.dark, // iOS
            ));

            // Return the child (which is your Navigator/home widget)
            return child!;
          },
           // Your home widget goes here
          home: const Scaffold(
            body: NamePromptScreen(),
          ),
        );
      },
    );
  }
  ));
  }
}
