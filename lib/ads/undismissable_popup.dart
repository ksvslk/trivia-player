import 'package:flutter/material.dart';
import 'package:operation_veritas/persistence/settings_controller.dart';
import 'package:provider/provider.dart';

class UndismissablePopup extends StatelessWidget {
  const UndismissablePopup({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsController = context.read<SettingsController>();

    return PopScope(
      canPop: false,
      child: AlertDialog(
        // Make dialog not dismissible by tapping outside
        // Note: barrierDismissible is already set to false in showDialog
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Continue playing:',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                color: colorScheme.onSurface),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Watch Rewarded AD button
            ElevatedButton.icon(
              icon: const Icon(Icons.play_circle_outline),
              label: Text(
                'Watch Rewarded Ad',
                style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Inter',
                    color: colorScheme.onTertiaryContainer),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.tertiaryContainer,
                foregroundColor: colorScheme.onTertiaryContainer,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                // Add logic to watch ad
                print('Watch ad clicked');
              },
            ),
            const SizedBox(height: 16),

            // Subscribe to Premium button
            ElevatedButton.icon(
              icon: const Icon(Icons.diamond),
              label: Text(
                'Subscribe to Premium',
                style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Inter',
                    color: colorScheme.onPrimaryContainer),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                // Add logic for subscription
                print('Subscribe clicked');
              },
            ),

            // Premium benefits list
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Column(
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
            ),

            const SizedBox(height: 10),

            // Wait 24 Hours button
            ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainer,
                  foregroundColor: colorScheme.onSurfaceVariant,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: ValueListenableBuilder<int>(
                  valueListenable: settingsController.lockTimeSecondsLeft,
                  builder: (context, seconds, _) {
                    if (seconds == 0) {
                      Navigator.of(context).pop();
                    }
                    final minutes = (seconds / 60).floor();
                    final secs = seconds % 60;
                    final formatted =
                        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

                    return Text(
                      'Continuing in $formatted',
                      style: TextStyle(fontSize: 14),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }
}

// Helper method to build consistent premium feature items
Widget _buildPremiumFeature(BuildContext context, IconData icon, String text) {
  final colorScheme = Theme.of(context).colorScheme;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: colorScheme.primary,
        ),
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
