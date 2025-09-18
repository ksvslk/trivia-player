import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:logging/logging.dart';
import 'package:operation_veritas/ads/ads_controller.dart';
import 'package:operation_veritas/auth_services/auth_controller.dart';
import 'package:operation_veritas/change_notifier/blocked_players.dart';
import 'package:operation_veritas/change_notifier/banner_message_visibility.dart';
import 'package:operation_veritas/change_notifier/money_controller.dart';
import 'package:operation_veritas/change_notifier/stats_service.dart';
import 'package:operation_veritas/change_notifier/trivia_service.dart';
import 'package:operation_veritas/constants.dart';
import 'package:operation_veritas/home_screen.dart';
import 'package:operation_veritas/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:developer' as dev;
import 'persistence/local_storage_settings_persistence.dart';
import 'app_lifecycle/app_lifecycle.dart';
import 'persistence/settings_controller.dart';
import 'audio/audio_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> setUpRemoteConfig() async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: Duration(hours: 6),
    ),
  );
  await remoteConfig.setDefaults(const {
    C.rewardedAdsIntervalTag: 3,
    C.lockTimeLimitSecondsTag: 3600,
    C.debugVersionTag: false,
    C.delaySecondsPopupReviewTag: 5,
    C.dayBeforeReviewTag: 1,
    C.minutesBeforeReviewTag: 15
  });
  remoteConfig.onConfigUpdated.listen((event) async {
    await remoteConfig.activate();
  });
  await remoteConfig.fetchAndActivate();
}

Future<void> initPlatformState() async {
  await Purchases.setLogLevel(LogLevel.verbose);
  PurchasesConfiguration configuration;
  if (Platform.isAndroid) {
    configuration = PurchasesConfiguration("goog_KHFjwrHpqZqQHQJeIbeSgiBqRQc");
  } else {
    configuration = PurchasesConfiguration("appl_HKKGPRhOttwWOsPdUwLyvJcmwQn");
  }
  await Purchases.configure(configuration);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
  );

  final authController = AuthController();
  await initPlatformState();
  await setUpRemoteConfig();

  AdsController? adsController;
  if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
    adsController = AdsController(MobileAds.instance);
  }

  if (Platform.isIOS || Platform.isMacOS) {
    final status = await AppTrackingTransparency.requestTrackingAuthorization();
    if (status == TrackingStatus.authorized && adsController != null) {
      adsController.requestTheLatestConsentInformation();
    }
  } else {
    if (adsController != null) {
      adsController.requestTheLatestConsentInformation();
    }
  }

  _log.info('Going full screen');
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

  final settingsController = SettingsController(
    persistence: LocalStorageSettingsPersistence(),
  );
  await settingsController.loadStateFromPersistence();
  final statsService = StatsService();

  runApp(
    MyApp(
      settingsController: settingsController,
      adsController: adsController,
      moneyController: MoneyController(),
      authController: authController,
      statsService: statsService,
    ),
  );
}

Logger _log = Logger('main.dart');

class MyApp extends StatelessWidget {
  final SettingsController settingsController;
  final AdsController? adsController;
  final MoneyController moneyController;
  final AuthController authController;
  final StatsService statsService;

  const MyApp({
    super.key,
    required this.settingsController,
    required this.adsController,
    required this.moneyController,
    required this.authController,
    required this.statsService,
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
          ProxyProvider2<
            SettingsController,
            ValueNotifier<AppLifecycleState>,
            AudioController
          >(
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
          ChangeNotifierProxyProvider2<
            SettingsController,
            ValueNotifier<AppLifecycleState>,
            AuthController
          >(
            lazy: false,
            create: (context) => authController,
            update: (context, settings, lifecycleNotifier, auth) {
              if (auth == null) throw ArgumentError.notNull();
              auth.attachSettings(settings);
              auth.attachLifecycleNotifier(lifecycleNotifier);
              return auth;
            },
          ),
          ChangeNotifierProxyProvider<
            ValueNotifier<AppLifecycleState>,
            AdsController?
          >(
            lazy: false,
            create: (context) => adsController,
            update: (context, lifecycleNotifier, ads) {
              if (ads != null) {
                ads.attachLifecycleNotifier(lifecycleNotifier);
              }
              return ads;
            },
          ),
          ChangeNotifierProvider(create: (context) => moneyController),
          ChangeNotifierProxyProvider<AudioController, TriviaService>(
            create: (context) => TriviaService(
              moneyController: moneyController,
              settingsController: settingsController,
              authController: authController,
              statsService: statsService,
              audioController: context.read<AudioController>(),
            ),
            update: (context, audioController, triviaService) {
              // If triviaService already exists, just return it (unless you need to update the audioController reference)
              if (triviaService != null) {
                return triviaService;
              }

              // Create new TriviaService with audioController dependency
              return TriviaService(
                moneyController: moneyController,
                settingsController: settingsController,
                authController: authController,
                statsService: statsService,
                audioController: audioController,
              );
            },
          ),
          ChangeNotifierProvider(
            create: (context) => BannerMessageVisibility(),
          ),
          ChangeNotifierProvider(create: (context) => statsService),
          ChangeNotifierProxyProvider<SettingsController, BlockedPlayers>(
            create: (_) => BlockedPlayers(),
            update: (_, settingsController, blockedPlayers) {
              blockedPlayers!.loadBlockedPlayers();
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
                localizationsDelegates: [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: [
                  Locale('en'),
                  //Locale('fr'),
                  //Locale('it'),
                  //Locale('de'),
                  //Locale('es'),
                  //Locale('et'),
                ],
                debugShowCheckedModeBanner: false,
                theme: lightTheme,
                darkTheme: darkTheme,
                navigatorKey: navigatorKey, // Add navigator key here

                home: HomeScreen(navigatorKey: navigatorKey),
              );
            },
          );
        },
      ),
    );
  }
}
