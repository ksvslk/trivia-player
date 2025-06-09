import 'package:flutter/material.dart';

class StatsService extends ChangeNotifier {
  List<int> _questionsWon =  List.filled(10, 0);
  List<int> getQuestionsWon() => _questionsWon;

  int _playerCount = 0;
  int getPlayersCount() => _playerCount;

  setQuestionsWon(List<int> list) {
    _questionsWon = list;
    notifyListeners();
  }

  setPlayersCount(int count) {
    _playerCount = count;
    notifyListeners();
  }
}
