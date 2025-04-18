import 'package:flutter/material.dart';

class ConnectionStatusIcon extends StatelessWidget {
  final bool connected;

  const ConnectionStatusIcon({super.key, required this.connected});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        connected 
            ? Icons.signal_cellular_4_bar_sharp 
            : Icons.signal_cellular_0_bar,
        color: connected ? Colors.green : Colors.red,
      ),
      onPressed: () {},
    );
  }
}