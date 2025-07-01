import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:operation_veritas/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class EulaBottomSheet extends StatelessWidget {
  final VoidCallback onAccept;

  const EulaBottomSheet({super.key, required this.onAccept});

  /// Launches a given URL in the external application.
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isLargeScreen = constraints.maxWidth > 600;
        final double contentMaxWidth = isLargeScreen ? 600 : double.infinity;

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: contentMaxWidth,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sunny,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, Player!',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Please accept our terms to continue',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Scrollable content (EULA text)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          height: 1.5,
                        ),
                        children: [
                          if (Platform.isIOS || Platform.isMacOS) ...[
                            TextSpan(
                              text: 'End User License Agreement (EULA)',
                              style: TextStyle(
                                color: colorScheme.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _launchUrl(C.eulaAppleLink),
                            ),
                            const TextSpan(
                              text: '\n\nIncluding but not limited to:\n',
                            ),
                          ],
                          TextSpan(
                            text:
                                '${!Platform.isAndroid ? '\n' : ''}We maintain a zero-tolerance policy regarding objectionable content and abusive behavior. Users are strictly prohibited from uploading, posting, transmitting, or sharing any content that is unlawful, harmful, threatening, abusive, harassing, defamatory, vulgar, obscene, sexually explicit, or otherwise objectionable. This includes but is not limited to hate speech, discriminatory content, violent material, spam, or any content that violates the rights of others. Additionally, users must not engage in abusive conduct toward other users, including harassment, bullying, stalking, or any form of intimidation. We reserve the right to immediately suspend or terminate accounts and remove content without prior notice. Users who violate this policy will face permanent account suspension and forfeit any right to refunds for paid services, subscriptions, or purchases. No refunds, credits, or compensation will be provided to users whose accounts are terminated for violations of this policy. Violating users may also be reported to appropriate authorities and may be held liable for any damages resulting from their actions.\n',
                          ),
                          const TextSpan(
                            style: TextStyle(fontWeight: FontWeight.bold),
                            text:
                                '\nSee bad behavior?\nTap their icon to report or block.\nEnjoy!\n',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom action area
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: SafeArea(
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Accept & Continue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 56),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void show(BuildContext context, {required VoidCallback onAccept}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54, // Optional dim background
      transitionDuration: Duration.zero, // 🔑 No animation
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: EulaBottomSheet(onAccept: onAccept),
        );
      },
    );
  }
}
