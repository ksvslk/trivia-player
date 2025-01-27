import 'package:flutter/material.dart';
import 'package:operation_veritas/settings/settings_controller.dart';
import 'package:provider/provider.dart';
import 'dart:io';

enum MenuItem { theme }

enum ThemeSubMenuItem { red, yellow, green, blue, purple }

MenuItemButton getMenuButton(Color color, SettingsController settings) {
  return MenuItemButton(
      onPressed: () {
        settings.changeSeedColor(color);
      },
      child: settings.seedColor.value == color.value
          ? CircleAvatar(
              backgroundColor: color,
              child:
                  Icon(Icons.check, color: color.withOpacity(0.5)))
          : CircleAvatar(backgroundColor: color));
}

class SettingsMenu extends StatefulWidget {
  const SettingsMenu({Key? key}) : super(key: key);

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsController>();

    return MenuAnchor(
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
        return IconButton(
          onPressed: () {
            controller.open();
          },
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Show menu',
        );
      },
      menuChildren: MenuItem.values.map((item) {
        switch (item) {
          case MenuItem.theme:
            return ValueListenableBuilder(
                valueListenable: settings.seedColor,
                builder: (context, value, child) {
                  return SubmenuButton(
                    leadingIcon: const Icon(Icons.color_lens_outlined),
                    menuChildren: ThemeSubMenuItem.values.map((item) {
                      switch (item) {
                        case ThemeSubMenuItem.red:
                          const color = Color.fromARGB(255, 255, 67, 104);
                          return getMenuButton(color, settings);
                        case ThemeSubMenuItem.yellow:
                          const color = Color.fromARGB(255, 242, 209, 76);
                          return getMenuButton(color, settings);
                        case ThemeSubMenuItem.green:
                          const color = Color.fromARGB(255, 193, 226, 59);
                          return getMenuButton(color, settings);
                        case ThemeSubMenuItem.blue:
                          const color = Color.fromARGB(255, 0, 136, 255);
                          return getMenuButton(color, settings);
                        case ThemeSubMenuItem.purple:
                          const color = Color.fromARGB(255, 255, 87, 216);
                          return getMenuButton(color, settings);
                      }
                    }).toList(),
                    child: Text(item.name),
                  );
                });
        }
      }).toList(),
    );
  }
}
