// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logging/logging.dart';

class AdsController extends ChangeNotifier {

  AdsController(MobileAds instance) : _instance = instance;

  static final _log = Logger('AdsController');
  final MobileAds _instance;
  final Duration _initialDelay = const Duration(seconds: 1);
  RewardedAd? _rewardedAd;

  final int _maxRetryCount = 25;
  int _rewardedRetryCount = 0;
  int _consentRetryCount = 0;

  bool isFakeAdsEnabled = true;

  /*
  //REAL
  final rewardedAdUnitId = defaultTargetPlatform == TargetPlatform.android
      ? ('ca-app-pub-5386053272091445/6000789763')
      // iOS
      : 'ca-app-pub-5386053272091445/4687708097';
  */

  //FAKE
  final rewardedAdUnitId = defaultTargetPlatform == TargetPlatform.android
      ? 'ca-app-pub-3940256099942544/5224354917'
      // iOS
      : 'ca-app-pub-3940256099942544/1712485313';

  @override
  void dispose() {
    super.dispose();
    _rewardedAd?.dispose();
  }

  Future<void> initialize() async {
    _log.info('initialize');
    await _instance.initialize();
    Future<void>.delayed(const Duration(seconds: 1)).then((_) {
      return loadRewardedAd(null);
    });
  }

  bool isAdAvailable() {
    return _rewardedAd != null;
  }

  void loadRewardedAd(AdRequest? adRequestNullable) {
    assert(Platform.isAndroid || Platform.isIOS,
        'AdMob currently does not support ${Platform.operatingSystem}');
    _log.info('loadRewardedAd');
    final adRequest = adRequestNullable ?? const AdRequest();
    RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: adRequest,
        rewardedAdLoadCallback: RewardedAdLoadCallback(onAdLoaded: (ad) {
          _rewardedAd = ad;
          _log.info('preloaded rewarded ad loaded.');
          _rewardedRetryCount = 0; // Reset retry count on success
          notifyListeners();
        }, onAdFailedToLoad: ((error) async {
          _log.info('preloaded rewarded ad not loaded - $error');
          if (_rewardedRetryCount < _maxRetryCount) {
            _rewardedRetryCount++;
            final delay = _initialDelay * pow(2, _rewardedRetryCount - 1);
            _log.info(
                'Retrying rewarded ad load in ${delay.inSeconds} seconds...');
            await Future.delayed(delay);
            loadRewardedAd(adRequest);
          } else {
            _log.info('Max retries reached for rewarded. Not retrying.');
          }
        })));
  }

  void reloadRewardedAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    loadRewardedAd(null);
    notifyListeners();
  }

  Future<void> showRewardedAd(Function giveRewardCallback) async {
    if (_rewardedAd == null) {
      _log.info('Warning, attempt to show rewarded before loaded.');
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        _log.info('ad onAdShowedFullScreenContent.');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        _log.info('$ad onAdDismissedFullScreenContent.');
        giveRewardCallback.call();
        reloadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        _log.info('$ad onAdFailedToShowFullScreenContent: $error');
        reloadRewardedAd();
      },
    );

    if (Platform.isAndroid) _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      _log.info(
          '$ad with reward $RewardItem(${reward.amount}, ${reward.type})');
    });
  }

  Future<void> requestTheLatestConsentInformation() async {
    final params = ConsentRequestParameters();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        _consentRetryCount = 0; // Reset retry count on success
        var status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.obtained ||
            status == ConsentStatus.notRequired) {
          _log.log(Level.INFO,
              'Consent status: $status, initializing ads - no need to load form.');
          initialize();
          return;
        }
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          _log.log(Level.INFO, 'Consent form available, loading form.');
          loadForm();
        }
      },
      (FormError error) async {
        _log.log(Level.SEVERE, 'Could request consent info update: $error');
        if (_consentRetryCount < _maxRetryCount) {
          _consentRetryCount++;
          final delay = _initialDelay * pow(2, _consentRetryCount - 1);
          _log.info(
              'Retrying consent information update in ${delay.inSeconds} seconds...');
          await Future.delayed(delay);
          requestTheLatestConsentInformation();
        } else {
          _log.info(
              'Max retries reached for consent information update. Not retrying.');
        }
      },
    );
  }

  Future<void> loadForm() async {
    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) async {
        _consentRetryCount = 0; // Reset retry count on success
        var status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          consentForm.show(
            (FormError? formError) {
              // Handle dismissal by reloading form
              _log.log(Level.SEVERE,
                  'Consent form dismissed, reloading. $formError');
              loadForm();
            },
          );
        } else if (status == ConsentStatus.obtained ||
            status == ConsentStatus.notRequired) {
          _log.log(
              Level.INFO, 'Consent status: $status. Initializing mobile ads.');
          initialize();
        }
      },
      (formError) async {
        _log.log(Level.SEVERE, 'Could not load consent form: $formError');
        if (_consentRetryCount < _maxRetryCount) {
          _consentRetryCount++;
          final delay = _initialDelay * pow(2, _consentRetryCount - 1);
          _log.info(
              'Retrying loading consent form in ${delay.inSeconds} seconds...');
          await Future.delayed(delay);
          loadForm();
        } else {
          _log.info(
              'Max retries reached for loading consent form. Not retrying.');
        }
      },
    );
  }
}
