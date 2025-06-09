import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_et.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('et'),
    Locale('fr'),
    Locale('it'),
  ];

  /// Live trivia chat
  ///
  /// In en, this message translates to:
  /// **'Trivia Player'**
  String get appTitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading game...'**
  String get loading;

  /// No description provided for @player.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get player;

  /// No description provided for @failedToAuth.
  ///
  /// In en, this message translates to:
  /// **'Failed to authenticate :('**
  String get failedToAuth;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @noBlockedPlayers.
  ///
  /// In en, this message translates to:
  /// **'No players are currently blocked.'**
  String get noBlockedPlayers;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @youOwnPremium.
  ///
  /// In en, this message translates to:
  /// **'You own premium'**
  String get youOwnPremium;

  /// No description provided for @premiumInfo.
  ///
  /// In en, this message translates to:
  /// **'Premium (no ads)'**
  String get premiumInfo;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @blockedPlayers.
  ///
  /// In en, this message translates to:
  /// **'Blocked Players'**
  String get blockedPlayers;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @shareConcerns.
  ///
  /// In en, this message translates to:
  /// **'Share your concerns about'**
  String get shareConcerns;

  /// No description provided for @blowTheWhistle.
  ///
  /// In en, this message translates to:
  /// **'Blow the whistle'**
  String get blowTheWhistle;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @typeYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your Answer'**
  String get typeYourAnswer;

  /// No description provided for @failedToSend.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get failedToSend;

  /// No description provided for @continuePlaying.
  ///
  /// In en, this message translates to:
  /// **'Continue playing'**
  String get continuePlaying;

  /// No description provided for @watchRewardedAd.
  ///
  /// In en, this message translates to:
  /// **'Watch Rewarded Ad'**
  String get watchRewardedAd;

  /// No description provided for @subscribeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to Premium'**
  String get subscribeToPremium;

  /// No description provided for @unlimitedGameplay.
  ///
  /// In en, this message translates to:
  /// **'Unlimited gameplay'**
  String get unlimitedGameplay;

  /// No description provided for @playWithoutPauses.
  ///
  /// In en, this message translates to:
  /// **'Play without pauses'**
  String get playWithoutPauses;

  /// No description provided for @competitiveEdge.
  ///
  /// In en, this message translates to:
  /// **'Competitive edge'**
  String get competitiveEdge;

  /// No description provided for @lockedUntil.
  ///
  /// In en, this message translates to:
  /// **'Locked until'**
  String get lockedUntil;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @versionLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get versionLoading;

  /// No description provided for @sendingDelay.
  ///
  /// In en, this message translates to:
  /// **'Slow down.'**
  String get sendingDelay;

  /// No description provided for @round.
  ///
  /// In en, this message translates to:
  /// **'Round:'**
  String get round;

  /// No description provided for @players.
  ///
  /// In en, this message translates to:
  /// **'Players:'**
  String get players;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'et',
    'fr',
    'it',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'et':
      return AppLocalizationsEt();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
