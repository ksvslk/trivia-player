import 'package:flutter/material.dart';

class BannerMessageVisibility extends ChangeNotifier {

  bool _questionVisibilityOnScreen = false;
  bool isQuestionVisibleOnScreen() => _questionVisibilityOnScreen;

  bool _roundBreak = false;
  bool isRoundBreak() => _roundBreak;

  setQuestionVisibilityOnScreen(bool isVisible) {
    _questionVisibilityOnScreen = isVisible;
    _roundBreak = false;
    notifyListeners();
  }

  setIsRoundBreak(bool isRoundBreak) {
    _roundBreak = isRoundBreak;
    notifyListeners();
  }
}
