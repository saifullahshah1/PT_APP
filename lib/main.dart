import 'dart:io';

import 'package:flutter/material.dart';

import 'data/db.dart';
import 'sp/SharedPreferencesHelper.dart';
import 'ui/home_screen.dart';

Future<void> main() async {

  // Ensure all plugins are initialized
  WidgetsFlutterBinding.ensureInitialized();

  //
  HttpOverrides.global = MyHttpOverrides();

  // db initialization
  final dbHelper = DatabaseHelper.instance;

  runApp(MyApp());
}


class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}


class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PT App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(title: 'Home Screen'),
    );
  }
}

