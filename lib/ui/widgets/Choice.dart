import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChoiceMain {
  const ChoiceMain(
      {required this.title,
      required this.asset,
      required this.route,
      required this.testType});

  final String title;
  final String asset;
  final String route;
  final int testType;

  void onTap(BuildContext context) {
    Navigator.pushNamed(context, route); // Navigate to the specified route
  }
}

class Choice {
  const Choice({required this.title, required this.asset, required this.route});

  final String title;
  final String asset;
  final String route;

  Future<void> onTap(BuildContext context, int testType) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (testType == 1 &&
        prefs.getBool('activatedUser') == false &&
        title != "Sit Up") {

      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User Not Activated!')),
      );
    } else {
      Navigator.pushNamed(context, route); // Navigate to the specified route
    }
  }
}
