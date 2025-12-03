import 'package:flutter/material.dart';
import 'package:operation_veritas/auth_services/auth_controller.dart';
import 'package:operation_veritas/change_notifier/money_controller.dart';
import 'package:operation_veritas/change_notifier/blocked_players.dart';
import 'package:operation_veritas/change_notifier/stats_service.dart';
import 'package:operation_veritas/l10n/app_localizations.dart';
import 'package:operation_veritas/menus/info_display.dart';
import 'package:operation_veritas/persistence/settings_controller.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Re-using your existing enums
enum ThemeSubMenuItem { red, yellow, green, blue, purple }

class MenuDrawer extends StatelessWidget {
  final GlobalKey<NavigatorState> parentNavigatorKey;

  const MenuDrawer({super.key, required this.parentNavigatorKey});

  // Helper method to get color circle button
  Widget _buildColorButton(
    Color color,
    SettingsController settings,
    BuildContext context,
  ) {
    bool isSelected = settings.seedColor.value == color.toARGB32();

    return InkWell(
      onTap: () {
        settings.changeSeedColor(color);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: color,
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Text(_getColorName(color), style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // Helper to get color name
  String _getColorName(Color color) {
    if (color.toARGB32() ==
        const Color.fromARGB(255, 255, 67, 104).toARGB32()) {
      return 'Red';
    }
    if (color.toARGB32() ==
        const Color.fromARGB(255, 242, 209, 76).toARGB32()) {
      return 'Yellow';
    }
    if (color.toARGB32() ==
        const Color.fromARGB(255, 193, 226, 59).toARGB32()) {
      return 'Green';
    }
    if (color.toARGB32() == const Color.fromARGB(255, 0, 136, 255).toARGB32()) {
      return 'Blue';
    }
    if (color.toARGB32() ==
        const Color.fromARGB(255, 255, 87, 216).toARGB32()) {
      return 'Purple';
    }
    return 'Custom';
  }

  // Helper to build blocked player list
  Widget _buildBlockedPlayersSection(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Consumer<BlockedPlayers>(
      builder: (context, blockedPlayers, child) {
        if (blockedPlayers.blockedPlayers.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              local.noBlockedPlayers,
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(), // Important to prevent nested scrolling issues
          itemCount: blockedPlayers.blockedPlayers.length,
          itemBuilder: (context, index) {
            String uid = blockedPlayers.blockedPlayers.keys.elementAt(index);
            String name = blockedPlayers.blockedPlayers[uid] ?? local.player;

            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              title: Text(
                name,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              ),
              trailing: IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove_circle_outline, size: 18),
                onPressed: () {
                  blockedPlayers.remove(uid);
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsController>(context, listen: false);
    final local = AppLocalizations.of(context)!;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer header
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Text(
                local.menu,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            Consumer<MoneyController>(
              builder: (context, money, child) {
                return ListTile(
                  leading: Icon(
                    money.isSubscribed() ? Icons.diamond : Icons.diamond,
                  ),
                  title: money.isSubscribed()
                      ? Text(local.youOwnPremium)
                      : Text(money.getProductFriendlyInfo() ?? "..."),
                     subtitle: money.isSubscribed() 
                  ? null 
                  : Text("Remove ads/popups"),
                  onTap: money.isSubscribed()
                      ? null
                      : () {
                          money.purchaseSubscription();
                        },
                );
              },
            ),

            ValueListenableBuilder<bool>(
              valueListenable: settings.isColorsExpanded,
              builder: (context, isExpanded, child) {
                return ExpansionTile(
                  initiallyExpanded: isExpanded,
                  onExpansionChanged: (bool expanded) {
                    settings.isColorsExpanded.value = expanded;
                    settings.saveColorsExpanded(expanded);
                  },
                  maintainState: true,
                  leading: const Icon(Icons.color_lens),
                  title: Text(local.theme),
                  children: [
                    ValueListenableBuilder(
                      valueListenable: settings.seedColor,
                      builder: (context, value, child) {
                        return Column(
                          children: [
                            _buildColorButton(
                              const Color.fromARGB(255, 255, 67, 104),
                              settings,
                              context,
                            ),
                            _buildColorButton(
                              const Color.fromARGB(255, 242, 209, 76),
                              settings,
                              context,
                            ),
                            _buildColorButton(
                              const Color.fromARGB(255, 193, 226, 59),
                              settings,
                              context,
                            ),
                            _buildColorButton(
                              const Color.fromARGB(255, 0, 136, 255),
                              settings,
                              context,
                            ),
                            _buildColorButton(
                              const Color.fromARGB(255, 255, 87, 216),
                              settings,
                              context,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: settings.isBlockedExpanded,
              builder: (context, isExpanded, child) {
                return ExpansionTile(
                  initiallyExpanded: isExpanded,
                  onExpansionChanged: (bool expanded) {
                    settings.isBlockedExpanded.value = expanded;
                    settings.saveBlockedExpanded(expanded);
                  },
                  leading: const Icon(Icons.block),
                  title: Text(local.blockedPlayers),
                  children: [_buildBlockedPlayersSection(context)],
                );
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: settings.soundsOn,
              builder: (context, soundsOn, child) {
                return SwitchListTile(
                  title: Text(local.sound),
                  value: soundsOn,
                  onChanged: (bool value) {
                    settings.toggleSoundsOn();
                  },
                  secondary: const Icon(Icons.volume_up),
                );
              },
            ),

            /*
            ListTile(
              leading: const Icon(Icons.info),
              title: Text(local.credits),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: parentNavigatorKey.currentContext!,
                  builder: (_) => const CreditsDialog(),
                );
              },
            ),
            */

            // Version display at the bottom
            const Divider(),
            const InfoDisplay(),
          ],
        ),
      ),
    );
  }
}
