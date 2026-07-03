import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob integration. Currently wired to Google's public TEST ad unit IDs so
/// the app is fully testable; swap in the real Riddles-Words ad units before
/// the Play Store release (see PLAN.md — each app gets its own AdMob IDs).
class AdsService {
  static const String appOpenUnitId = 'ca-app-pub-3940256099942544/9257395921';
  static const String bannerUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String rewardedUnitId = 'ca-app-pub-3940256099942544/5224354917';

  InterstitialAd? _interstitial;
  int _solvesSinceInterstitial = 0;

  /// Loads and shows the app-open ad; resolves once dismissed/failed.
  /// [timeout] keeps the splash from hanging when offline.
  Future<void> showAppOpen({Duration timeout = const Duration(seconds: 4)}) async {
    final completer = Completer<void>();
    await AppOpenAd.load(
      adUnitId: appOpenUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    return completer.future.timeout(timeout, onTimeout: () {});
  }

  /// Shows a rewarded ad; resolves true only if the user earned the reward.
  Future<bool> showRewarded() async {
    final completer = Completer<bool>();
    var earned = false;
    await RewardedAd.load(
      adUnitId: rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(earned);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show(onUserEarnedReward: (ad, reward) => earned = true);
        },
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );
    return completer.future;
  }

  void preloadInterstitial() {
    if (_interstitial != null) return;
    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) => _interstitial = null,
      ),
    );
  }

  /// Called after each solve; shows an interstitial every 5th solved level.
  void onLevelSolved() {
    _solvesSinceInterstitial++;
    if (_solvesSinceInterstitial < 5) {
      preloadInterstitial();
      return;
    }
    final ad = _interstitial;
    if (ad == null) {
      preloadInterstitial();
      return;
    }
    _solvesSinceInterstitial = 0;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
    );
    ad.show();
  }

  BannerAd createBanner({void Function(Ad, LoadAdError)? onFailed}) => BannerAd(
        adUnitId: bannerUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            onFailed?.call(ad, error);
          },
        ),
      )..load();
}

final adsServiceProvider = Provider<AdsService>((ref) => AdsService());
