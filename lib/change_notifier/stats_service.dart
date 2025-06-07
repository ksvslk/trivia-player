import 'package:flutter/material.dart';

class StatsService extends ChangeNotifier {
  List<int> _questionsWon =  List.filled(10, 0);
  List<int> getQuestionsWon() => _questionsWon;

  setQuestionsWon(List<int> list) {
    _questionsWon = list;
    notifyListeners();
  }
}
