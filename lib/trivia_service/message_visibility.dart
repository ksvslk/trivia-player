import 'package:flutter/material.dart';

class BannerMessageVisibility extends ChangeNotifier {

  bool _visible = false;
  bool isVisible() => _visible;

  setVisibility(bool isVisible) {
    // Banner message is visible when actual message is NOT
    _visible = !isVisible;
    notifyListeners();
  }

}