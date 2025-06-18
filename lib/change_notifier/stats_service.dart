import 'package:flutter/material.dart';

class StatsService extends ChangeNotifier {
  List<int> _questionsWon =  List.filled(10, 0);
  List<int> getQuestionsWon() => _questionsWon;

  int _playerCount = 0;
  int getPlayersCount() => _playerCount;

  int _publicQuestionScore = 0;
  int getQuestionScore() => _publicQuestionScore;

  int _publicRoundScore = 0;
  int getRoundScore() => _publicRoundScore;

  int _questionNumber = 0;
  int getQuestionNumber() => _questionNumber;

  setQuestionsWon(List<int> list) {
    _questionsWon = list;
    notifyListeners();
  }

  setCurrentQuestion(int questionNumber) {
    _questionNumber = questionNumber;
    notifyListeners();
  }

  setPlayersCount(int count) {
    _playerCount = count;
    notifyListeners();
  }

  setPublicRoundScore(int roundScore) {
    _publicRoundScore = roundScore;
    notifyListeners();
  }

  setPublicQuestionScore(int questionScore) {
    _publicQuestionScore = questionScore;
    notifyListeners();
  }

}
