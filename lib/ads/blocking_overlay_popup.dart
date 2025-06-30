import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:operation_veritas/ads/ads_controller.dart';
import 'package:operation_veritas/change_notifier/money_controller.dart';
import 'package:operation_veritas/l10n/app_localizations.dart';
import 'package:operation_veritas/persistence/settings_controller.dart';
import 'package:provider/provider.dart';

class BlockingOverlayPopup extends StatelessWidget {
  const BlockingOverlayPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsController = context.read<SettingsController>();
    final adsController = context.watch<AdsController>();
    final moneyController = context.read<MoneyController>();
    final local = AppLocalizations.of(context)!;

    final mediaQuery = MediaQuery.of(context);
    final screenSize = MediaQuery.of(context).size;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                width: screenSize.width,
                height: screenSize.height,
                child: IgnorePointer(
                  ignoring: false,
                  child: MediaQuery(
                    data: mediaQuery.copyWith(
                      viewInsets: EdgeInsets.zero,
                      padding: EdgeInsets.zero,
                      viewPadding: EdgeInsets.zero,
                    ),
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: Center(
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          margin: const EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    '${local.continuePlaying}:',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter',
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.play_circle_outline),
                                  label: Text(
                                    local.watchRewardedAd,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Inter',
                                      color: adsController.rewardedAd == null ? colorScheme.onSurfaceVariant : colorScheme.onTertiaryContainer,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        colorScheme.tertiaryContainer,
                                    foregroundColor:
                                        colorScheme.onTertiaryContainer,
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                  ),
                                  onPressed: adsController.rewardedAd == null
                                      ? null
                                      : () {
                                          adsController.rewardedAd?.show(
                                            onUserEarnedReward: (
                                              AdWithoutView ad,
                                              RewardItem rewardItem,
                                            ) {
                                              settingsController
                                                  .saveLockTimeEnd(newValue: 0);
                                            },
                                          );
                                        },
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.diamond),
                                  label: Text(
                                    "Go ${moneyController.getProductFriendlyInfo()}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Inter',
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        colorScheme.primaryContainer,
                                    foregroundColor:
                                        colorScheme.onPrimaryContainer,
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                  ),
                                  onPressed: () {
                                    moneyController.purchaseSubscription();
                                  },
                                ),
                                const SizedBox(height: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildPremiumFeature(context,
                                        Icons.lock_open, local.unlimitedGameplay),
                                    _buildPremiumFeature(
                                        context,
                                        Icons.auto_awesome,
                                        local.playWithoutPauses),
                                    _buildPremiumFeature(context, Icons.speed,
                                        local.competitiveEdge),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        colorScheme.surfaceContainer,
                                    foregroundColor:
                                        colorScheme.onSurfaceVariant,
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                  ),
                                  child: ValueListenableBuilder<int>(
                                    valueListenable:
                                        settingsController.lockTimeEnd,
                                    builder: (context, time, child) {
                                      final dateTime =
                                          DateTime.fromMillisecondsSinceEpoch(
                                                  time,
                                                  isUtc: true)
                                              .toLocal();
                                      final formatted =
                                          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                                      return Text(
                                        '${local.lockedUntil} $formatted',
                                        style: const TextStyle(fontSize: 14),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumFeature(
      BuildContext context, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Inter',
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
