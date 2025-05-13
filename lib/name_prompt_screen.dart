import 'dart:math';
import 'package:flutter/material.dart';
import 'package:operation_veritas/chat_page/trivia_chat.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NamePromptScreen extends StatefulWidget {
  const NamePromptScreen({super.key});

  @override
  NamePromptScreenState createState() => NamePromptScreenState();
}

class NamePromptScreenState extends State<NamePromptScreen> {
  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userName = prefs.getString('name');

    if (userName == null || userName.isEmpty) {
      await _showNameDialog(prefs);
    } else {
      _navigateToTriviaChat(userName, _generateRandomDarkerColor());
    }
  }

  Future<void> _showNameDialog(SharedPreferences prefs) async {
    TextEditingController nameController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Your Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Your name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  String userName = nameController.text.trim();
                  prefs.setString('name', userName);
                  Navigator.of(context).pop();
                  _navigateToTriviaChat(userName, _generateRandomDarkerColor());
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToTriviaChat(String userName, Color randomColor) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => TriviaChat(),
      ),
    );
  }

  // Function to generate a random darker color
  Color _generateRandomDarkerColor() {
    Random random = Random();
    // Generate random RGB values and adjust to ensure it's dark
    int r = random.nextInt(100) + 50; // Ensuring a darker value (50 to 150 range)
    int g = random.nextInt(100) + 50;
    int b = random.nextInt(100) + 50;

    return Color.fromRGBO(r, g, b, 1);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
