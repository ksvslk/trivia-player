import 'dart:convert';

import 'package:crypto/crypto.dart';
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

  Color pastelColorFromName(String name) {
    // Get the HSL components of the original color (`this`).
    final HSLColor baseHSL = HSLColor.fromColor(this);

    // Get a consistent numerical value from the input string.
    // The hashCode is a good way to get a deterministic integer from a string.
    final int hash = name.hashCode;

    // Use the hash to introduce variation in saturation and lightness
    // while keeping the color within the pastel range.
    // We'll keep the hue from the original color.

    // Define the desired range for pastel saturation and lightness.
    // Pastel colors typically have low-to-moderate saturation and high lightness.
    const double minSaturation = 0.3;
    const double maxSaturation = 0.6;
    const double minLightness = 0.75;
    const double maxLightness = 0.95;

    // Map the hash code to a value between 0.0 and 1.0 to use for interpolation.
    // Using a large number for the modulo operation helps distribute values.
    final double hashFactor = (hash % 1000).abs() / 1000.0;

    // Interpolate saturation and lightness within the pastel ranges based on the hash factor.
    // We can use the hash factor directly for one and its inverse for the other
    // to help create more distinct combinations.
    final double derivedSaturation = minSaturation + (maxSaturation - minSaturation) * hashFactor;
    final double derivedLightness = minLightness + (maxLightness - minLightness) * (1.0 - hashFactor);

    // Create a new HSL color.
    // We use the hue from the original color (`baseHSL.hue`),
    // and the derived saturation and lightness for the pastel effect.
    return HSLColor.fromAHSL(
      baseHSL.alpha,      // Keep the original alpha (opacity).
      baseHSL.hue,        // Keep the original hue.
      derivedSaturation,  // Use the saturation derived from the string hash.
      derivedLightness,   // Use the lightness derived from the string hash.
    ).toColor(); // Convert the HSL color back to a standard Color object.
  }
}

final adjectives = [
  "Agile",
  "Amber",
  "Azure",
  "Bold",
  "Bright",
  "Bronze",
  "Calm",
  "Clear",
  "Cobalt",
  "Cool",
  "Coral",
  "Crimson",
  "Crystal",
  "Cyan",
  "Eager",
  "Emerald",
  "Fast",
  "Golden",
  "Grand",
  "Green",
  "Indigo",
  "Jade",
  "Keen",
  "Lime",
  "Loyal",
  "Maple",
  "Noble",
  "Olive",
  "Pearl",
  "Placid",
  "Plum",
  "Proud",
  "Pure",
  "Quick",
  "Quiet",
  "Regal",
  "Rose",
  "Royal",
  "Ruby",
  "Silver",
  "Sky",
  "Solar",
  "Stead",
  "Swift",
  "Teal",
  "Topaz",
  "True",
  "Valid",
  "Vivid",
  "Wise"
];

final nouns = [
  "Alpaca",
  "Badger",
  "Beacon",
  "Bison",
  "Canyon",
  "Castle",
  "Cobra",
  "Comet",
  "Condor",
  "Cougar",
  "Coyote",
  "Delta",
  "Desert",
  "Dragon",
  "Falcon",
  "Fjord",
  "Forest",
  "Galaxy",
  "Glacier",
  "Griffin",
  "Harbor",
  "Hornet",
  "Island",
  "Jaguar",
  "Kestrel",
  "Lagoon",
  "Lancer",
  "Lizard",
  "Meteor",
  "Mirage",
  "Nomad",
  "Oasis",
  "Oracle",
  "Panda",
  "Panther",
  "Path",
  "Pinnacle",
  "Planet",
  "Portal",
  "Pyramid",
  "Quasar",
  "Raptor",
  "Raven",
  "Reef",
  "Rider",
  "River",
  "Sphinx",
  "Spirit",
  "Summit",
  "System",
  "Temple",
  "Terra",
  "Thunder",
  "Tiger",
  "Tundra",
  "Unicorn",
  "Valley",
  "Viper",
  "Voyage",
  "Warden",
  "Wizard",
  "Wolf",
  "Wyvern",
  "Zenith",
  "Zephyr"
];

extension PlayerName on String {
  String generateLifelikeUsername() {
    final bytes = utf8.encode(this);
    final digest = sha256.convert(bytes).bytes;

    final adjIndex = digest[0] % adjectives.length;
    final nounIndex = digest[1] % nouns.length;
    final numberVal = ((digest[2] << 8) + digest[3]) % 1000;

    final adjective = adjectives[adjIndex];
    final noun = nouns[nounIndex];
    final number = numberVal.toString().padLeft(3, '0');

    final username = '$adjective$noun$number';

    return username;
  }
}
