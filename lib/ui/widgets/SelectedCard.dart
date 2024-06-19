import 'package:flutter/material.dart';

import 'Choice.dart';
class SelectCardMain extends StatelessWidget {
  const SelectCardMain({Key? key, required this.choice, required this.onSelect}) : super(key: key);

  final ChoiceMain choice;
  final void Function(int testType) onSelect;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // onTap: () => choice.onTap(context), // Call onTap function on tap
        onTap: () {
              onSelect(choice.testType);
            },
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            image: DecorationImage(
                image: AssetImage(
                  choice.asset,
                ),
                fit: BoxFit.cover)),
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        child: Text(choice.title,
            style: const TextStyle(fontSize: 15, color: Colors.white)),
      ),
    );
  }
}


class SelectCard extends StatelessWidget {
  const SelectCard ({Key? key, required this.choice, required this.onSelect, required this.testType}) : super(key: key);

  final Choice choice;
  final int testType;

  final void Function(int testType) onSelect;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => {
        choice.onTap(context, testType)
      }, // Call onTap function on tap
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            image: DecorationImage(
                image: AssetImage(
                  choice.asset,
                ),
                fit: BoxFit.cover)),
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        child: Text(choice.title,
            style: const TextStyle(fontSize: 15, color: Colors.white)),
      ),
    );
  }
}

