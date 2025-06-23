// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logging/logging.dart';

class AdsController extends ChangeNotifier {
  AdsController(MobileAds instance) : _instance = instance;

  static final _log = Logger('AdsController');
  final MobileAds _instance;
  final Duration _initialDelay = const Duration(seconds: 1);
  RewardedAd? rewardedAd;

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
    rewardedAd?.dispose();
  }

  Future<void> initialize() async {
    await _instance.initialize();
    Future<void>.delayed(const Duration(seconds: 1)).then((_) {
      return loadAd();
    });
  }

  bool isAdAvailable() {
    return rewardedAd != null;
  }

  void loadAd() {
    RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedRetryCount = 0; // Reset retry count on success
            ad.fullScreenContentCallback = FullScreenContentCallback(
                // Called when the ad showed the full screen content.
                onAdShowedFullScreenContent: (ad) {},
                // Called when an impression occurs on the ad.
                onAdImpression: (ad) {},
                // Called when the ad failed to show full screen content.
                onAdFailedToShowFullScreenContent: (ad, err) {
                  // Dispose the ad here to free resources.
                  disposeAndReloadAd();
                },
                // Called when the ad dismissed full screen content.
                onAdDismissedFullScreenContent: (ad) {
                  // Dispose the ad here to free resources.
                  disposeAndReloadAd();
                },
                // Called when a click is recorded for an ad.
                onAdClicked: (ad) {});

            // Keep a reference to the ad so you can show it later.
            rewardedAd = ad;
            notifyListeners();
          },
          // Called when an ad request failed.
          onAdFailedToLoad: (LoadAdError error) async {
            if (_rewardedRetryCount < _maxRetryCount) {
              _rewardedRetryCount++;
              final delay = _initialDelay * pow(2, _rewardedRetryCount - 1);
              await Future.delayed(delay);
              loadAd();
            } else {
              _log.info('Max retries reached for rewarded. Not retrying.');
            }
          },
        ));
  }

  void disposeAndReloadAd() {
    rewardedAd?.dispose();
    rewardedAd = null;
    loadAd();
    notifyListeners();
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
          initialize();
          return;
        }
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
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
