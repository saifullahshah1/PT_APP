import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/const_images.dart';
import '../data/csv_data.dart';
import '../data/db.dart';
import '../utils/utils.dart';
import 'settings.dart';
import 'widgets/Choice.dart';
import 'widgets/SelectedCard.dart';
import 'fitness_test_screen.dart';
import 'widgets/input_dialog.dart';

String? licenseKey;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isFirstTime = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    initializeDatabase();
  }

  Future<void> _checkFirstTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (_isFirstTime) {
      print("First time");
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   _showInputDialog(context);
      // });
      prefs.setBool('isFirstTime', false);
    } else {
      print("Not first time");

      checkActivationExpiry(prefs);
    }
  }

  Future<void> initializeDatabase() async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database;
  }

  Future<void> selectCsvFile(int testType) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      String? filePath = result.files.single.path;
      if (filePath != null) {
        final csvData = await parseCsv(filePath);

        final dbHelper = DatabaseHelper.instance;
        await dbHelper.insertCsvData(csvData, testType);

        print("Data saved to db");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FitnessTestScreen(testType: testType),
          ),
        );
      }
    }
  }

  Future<List<CsvData>> parseCsv(String filePath) async {
    String csvString = await File(filePath).readAsString();
    List<List<dynamic>> rowsAsListOfValues =
    const CsvToListConverter().convert(csvString);
    List<CsvData> parsedData =
    rowsAsListOfValues.skip(1).map((row) => CsvData.fromList(row)).toList();
    return parsedData;
  }

  void _navigateToFitnessTestScreen(int testType) async {
    bool empty = await DatabaseHelper.instance.isTableEmpty(testType);
    if (empty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Alert'),
            content: Text(
                'Student data is not available. Please upload the student data CSV file.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  selectCsvFile(testType);
                  Navigator.pop(context);
                },
                child: Text('Upload CSV'),
              ),
            ],
          );
        },
      );
    } else {
      print("Already have data in db");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FitnessTestScreen(testType: testType),
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("School Fitness Test"),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: Image.asset(
                'assets/images/ic_settings.png',
                // Path to your icon image file
                width: 36, // Adjust width as needed
                height: 36, // Adjust height as needed
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 2 / 1,
                children: choicesHome
                    .map((e) => SelectCardMain(
                        choice: e, onSelect: _navigateToFitnessTestScreen))
                    .toList(),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> checkActivationExpiry(SharedPreferences prefs) async {
    if (prefs.getBool('activatedUser') == true) {
      print("Activated User:");
      DateTime currentDateTime = getCurrentDateTime();
      print(currentDateTime);
      String? storedExpiryDateTime = prefs.getString('expiryDate');
      if (storedExpiryDateTime != null) {
        final storedDateTime = DateTime.parse(storedExpiryDateTime);
        if (currentDateTime.isAfter(storedDateTime)) {
          print("Activation Expired!");
          await prefs.setBool('activatedUser', false);
          await prefs.setString('licenseId', '');
          await prefs.setString('schoolId', '');
          await prefs.setString('expiryDate', '');
        } else {
          print("Activation Not Expired!");
        }
      }
    } else {
      print("Non Activated User:");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('activatedUser', false);
    }
  }
}

const List<ChoiceMain> choicesHome = <ChoiceMain>[
  ChoiceMain(
      title: 'Fitness Test',
      asset: KImages.fitnessTest,
      route: '/fitnessTestScreen',
      testType: 1),
  ChoiceMain(
      title: 'Mock Test',
      asset: KImages.mockTest,
      route: '/fitnessTestScreen',
      testType: 2),
];
