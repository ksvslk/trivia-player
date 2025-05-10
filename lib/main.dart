import 'dart:io';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:logging/logging.dart';
import 'package:operation_veritas/ads/ads_controller.dart';
import 'package:operation_veritas/change_notifier/blocked_players.dart';
import 'package:operation_veritas/change_notifier/banner_message_visibility.dart';
import 'package:operation_veritas/change_notifier/money_controller.dart';
import 'package:operation_veritas/change_notifier/trivia_service.dart';
import 'package:operation_veritas/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:developer' as dev;
import 'persistence/settings_persistence.dart';
import 'persistence/local_storage_settings_persistence.dart';
import 'app_lifecycle/app_lifecycle.dart';
import 'persistence/settings_controller.dart';
import 'audio/audio_controller.dart';
import 'package:firebase_core/firebase_core.dart';

const revenueCatGoogleApiKey = "goog_KHFjwrHpqZqQHQJeIbeSgiBqRQc";

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

Future<void> initPlatformState() async {
  await Purchases.setDebugLogsEnabled(true);
  PurchasesConfiguration configuration;
  if (Platform.isAndroid) {
    configuration = PurchasesConfiguration("goog_KHFjwrHpqZqQHQJeIbeSgiBqRQc");
  } else {
    configuration = PurchasesConfiguration("");
  }
  await Purchases.configure(configuration);
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
  await initPlatformState();
  setupConnectionTracking();

  _log.info('Going full screen');
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  AdsController? adsController;
  if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
    /// Prepare the google_mobile_ads plugin so that the first ad loads
    /// faster. This can be done later or with a delay if startup
    /// experience suffers.
    adsController = AdsController(MobileAds.instance);
    adsController.requestTheLatestConsentInformation();
  }

  final settingsController =
      SettingsController(persistence: LocalStorageSettingsPersistence());
  await settingsController.loadStateFromPersistence();

  runApp(
    MyApp(
      settingsController: settingsController,
      adsController: adsController,
      moneyController: MoneyController(),
    ),
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
  final SettingsController settingsController;
  final AdsController? adsController;
  final MoneyController moneyController;

  const MyApp({
    super.key,
    required this.settingsController,
    required this.adsController,
    required this.moneyController,
  });

  @override
  Widget build(BuildContext context) {
    return AppLifecycleObserver(
      child: MultiProvider(
        providers: [
          Provider<SettingsController>(
            lazy: false,
            create: (context) => settingsController,
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
          ChangeNotifierProvider<AdsController?>.value(value: adsController),
          ChangeNotifierProvider(
            create: (context) => moneyController,
          ),
          ChangeNotifierProvider(
            create: (context) => TriviaService(
                adsController: adsController,
                moneyController: moneyController,
                settingsController: settingsController),
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

              final GlobalKey<NavigatorState> navigatorKey =
                  GlobalKey<NavigatorState>();

              return MaterialApp(
                title: 'Trivia Chat',
                debugShowCheckedModeBanner: false,
                theme: lightTheme,
                darkTheme: darkTheme,
                navigatorKey: navigatorKey, // Add navigator key here
                home: HomeScreen(
                  userColor: _generateRandomDarkerColor(),
                  navigatorKey: navigatorKey,
                ),
              );
            },
          );
        },
      ),
    );
  }

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
