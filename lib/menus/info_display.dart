import 'dart:io';

import 'package:flutter/material.dart';
import 'package:operation_veritas/auth_services/auth_controller.dart';
import 'package:operation_veritas/change_notifier/stats_service.dart';
import 'package:operation_veritas/constants.dart';
import 'package:operation_veritas/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoDisplay extends StatefulWidget {
  const InfoDisplay({super.key});

  @override
  State<InfoDisplay> createState() => _InfoDisplayState();
}

class _InfoDisplayState extends State<InfoDisplay> {
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    _getVersionInfo();
  }

  Future<void> _getVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version =
            '${AppLocalizations.of(context)!.version}: ${packageInfo.version} (${packageInfo.buildNumber})';
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<AuthController>(
            builder: (context, auth, child) {
              return Text(
                "${local.player}: ${auth.playerName}",
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Inter',
                  color: Colors.grey[600],
                ),
              );
            },
          ),
          Consumer<StatsService>(
            builder: (context, stats, child) {
              return Text(
                "Round wins: ${stats.getRoundScore()}\nQuestion wins: ${stats.getQuestionScore()}",
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Inter',
                  color: Colors.grey[600],
                ),
              );
            },
          ),
          const Text(""),
          Text(
            _version,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Inter',
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          // Legal links
          Row(
            children: [
              if ((Platform.isIOS || Platform.isMacOS)) ...[
                InkWell(
                  onTap: () => _launchUrl(
                    C.eulaAppleLink,
                  ),
                  child: Text(
                    'Terms of Use',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Inter',
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text(
                  ' • ',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Inter',
                    color: Colors.grey[600],
                  ),
                ),
              ],
              InkWell(
                onTap: () =>
                    _launchUrl(C.privacyLink),
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Inter',
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
