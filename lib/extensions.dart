import 'package:flutter/material.dart';

extension ColorUtils on Color {
  Color get inverted => Color.fromARGB(
        a.toInt(),
        255 - r.toInt(),
        255 - g.toInt(),
        255 - b.toInt(),
      );

  Color get contrastingTextColor =>
      computeLuminance() > 0.5 ? Colors.black : Colors.white;
}