import 'package:flutter/material.dart';
import 'package:operation_veritas/ads/ads_controller.dart';
import 'package:operation_veritas/change_notifier/money_controller.dart';
import 'package:operation_veritas/change_notifier/play_time_controller.dart';
import 'package:provider/provider.dart';

class BlockingOverlayPopup extends StatelessWidget {
  const BlockingOverlayPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final playTimeController = context.read<PlayTimeController>();
    final adsController = context.read<AdsController>();
    final moneyController = context.read<MoneyController>();

    return Positioned.fill(
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
                      'Continue playing:',
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
                      'Watch Rewarded Ad',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Inter',
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.tertiaryContainer,
                      foregroundColor: colorScheme.onTertiaryContainer,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      adsController.showRewardedAd((_) => {
                        playTimeController.transitionToPlayTime()
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.diamond),
                    label: Text(
                      'Subscribe to Premium',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Inter',
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      moneyController.purchaseSubscription();
                    },
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPremiumFeature(
                          context, Icons.lock_open, 'Unlimited gameplay'),
                      _buildPremiumFeature(
                          context, Icons.auto_awesome, 'Play without pauses'),
                      _buildPremiumFeature(
                          context, Icons.speed, 'Competitive edge'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainer,
                      foregroundColor: colorScheme.onSurfaceVariant,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: StreamBuilder<int>(
                      stream: playTimeController.onLockTimeUpdate,
                      builder: (context, snapshot) {
                        final remainingMillis = snapshot.data ?? 0;
                        final remainingSeconds =
                            (remainingMillis / 1000).ceil();
                        final minutes = remainingSeconds ~/ 60;
                        final seconds = remainingSeconds % 60;
                        final formatted =
                            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
                        return Text(
                          'Continuing in $formatted',
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
