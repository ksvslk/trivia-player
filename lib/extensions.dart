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
    final double derivedSaturation =
        minSaturation + (maxSaturation - minSaturation) * hashFactor;
    final double derivedLightness =
        minLightness + (maxLightness - minLightness) * (1.0 - hashFactor);

    // Create a new HSL color.
    // We use the hue from the original color (`baseHSL.hue`),
    // and the derived saturation and lightness for the pastel effect.
    return HSLColor.fromAHSL(
      baseHSL.alpha, // Keep the original alpha (opacity).
      baseHSL.hue, // Keep the original hue.
      derivedSaturation, // Use the saturation derived from the string hash.
      derivedLightness, // Use the lightness derived from the string hash.
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
  "Wise",
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
  "Zephyr",
];

/// Extension methods for converting ISO 8601 subscription period strings to English
extension SubscriptionPeriod on String? {
  /// Converts an ISO 8601 subscription period string to a human-readable English string.
  ///
  /// Examples:
  /// - "P1W".toEnglish() -> "1 week"
  /// - "P1M".toEnglish() -> "1 month"
  /// - "P3M".toEnglish() -> "3 months"
  /// - "P6M".toEnglish() -> "6 months"
  /// - "P1Y".toEnglish() -> "1 year"
  /// - "P2Y".toEnglish() -> "2 years"
  ///
  /// Returns null if the input is null or invalid format.
  String? toEnglish() {
    if (this == null || this!.isEmpty) {
      return null;
    }

    // Remove 'P' prefix if present
    String cleanPeriod = this!.startsWith('P') ? this!.substring(1) : this!;

    if (cleanPeriod.isEmpty) {
      return null;
    }

    // Extract number and unit
    final RegExp regex = RegExp(r'^(\d+)([DWMY])$');
    final match = regex.firstMatch(cleanPeriod);

    if (match == null) {
      return null;
    }

    final int number = int.parse(match.group(1)!);
    final String unit = match.group(2)!;

    String unitName;
    switch (unit) {
      case 'D':
        unitName = number == 1 ? 'day' : 'days';
        break;
      case 'W':
        unitName = number == 1 ? 'week' : 'weeks';
        break;
      case 'M':
        unitName = number == 1 ? 'month' : 'months';
        break;
      case 'Y':
        unitName = number == 1 ? 'year' : 'years';
        break;
      default:
        return null;
    }

    return '$number $unitName';
  }

  /// Converts subscription period to more user-friendly English with common subscription terms.
  ///
  /// Examples:
  /// - "P1W".toFriendlyEnglish() -> "Weekly"
  /// - "P1M".toFriendlyEnglish() -> "Monthly"
  /// - "P3M".toFriendlyEnglish() -> "Quarterly"
  /// - "P6M".toFriendlyEnglish() -> "Semi-annually"
  /// - "P1Y".toFriendlyEnglish() -> "Yearly"
  /// - "P5M".toFriendlyEnglish() -> "5 months"
  ///
  /// Returns null if the input is null or invalid format.
  String? toFriendlyEnglish() {
    final basic = toEnglish();
    if (basic == null) return null;

    // Handle common subscription periods with more friendly names
    switch (this) {
      case 'P1W':
        return 'week';
      case 'P1M':
        return 'month';
      case 'P3M':
        return 'quarter';
      case 'P6M':
        return 'semi-annual';
      case 'P1Y':
        return 'year';
      case 'P2Y':
        return 'bi-annual';
      default:
        // Capitalize first letter for other periods
        return basic[0].toUpperCase() + basic.substring(1);
    }
  }
}

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
