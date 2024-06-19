import 'package:flutter/material.dart';

import 'widgets/input_dialog.dart';


class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showInputDialog(context),
          child: const Text('Activation',style: TextStyle(color: Colors.black),),
        ),
      ),
    );
  }

  void _showInputDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return InputDialog();
      },
    );

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You entered: $result')),
      );
    }
  }
}
