import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pt_app/ui/test_screens/km_run.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/const_images.dart';
import '../data/csv_data.dart';
import '../data/db.dart';
import '../model/class.dart';
import '../model/student.dart';
import 'mock_test_report.dart';
import 'widgets/Choice.dart';
import 'widgets/SelectedCard.dart';
import 'test_screens/broad_jump.dart';
import 'test_screens/pull_up_screen.dart';
import 'test_screens/shuttle_run.dart';
import 'test_screens/sit_and_reach_screen.dart';
import 'test_screens/sit_up_screen.dart';

List<Class> classes = [];

final apiBaseUrl = "http://localhost:5002";
final getSchoolsEndpoint = "/api/schools/";
final tempSchool = "h2r8B2O4Ivsza5YrPWE5";
final getStudentsEndpoint =
    "$apiBaseUrl$getSchoolsEndpoint$tempSchool/students";

class FitnessTestScreen extends StatefulWidget {
  final int testType;

  FitnessTestScreen({Key? key, required this.testType}) : super(key: key);

  @override
  _FitnessTestScreenState createState() => _FitnessTestScreenState();
}

class _FitnessTestScreenState extends State<FitnessTestScreen> {
  // const FitnessTestScreen({Key? key});
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print("initState");
    print("Test type: ${widget.testType}");
    selectCsvFile();
  }

  /** Upload CSV */

  List<CsvData> csvData = [];

  Future<void> selectCsvFile() async {
    bool empty = await DatabaseHelper.instance.isTableEmpty(widget.testType);
    if (empty) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        String? filePath = result.files.single.path;
        if (filePath != null) {
          await parseCsv(filePath);

          final dbHelper = DatabaseHelper.instance;
          await dbHelper.insertCsvData(csvData, widget.testType);

          List<CsvData> importedData =
              await dbHelper.getAllCsvData(widget.testType);
          setState(() {
            csvData = importedData;
          });
        }
      }
    } else {
      print("Already have data in db");
    }

    loadData();
  }

  Future<void> parseCsv(String filePath) async {
    String csvString = await File(filePath).readAsString();
    List<List<dynamic>> rowsAsListOfValues =
        const CsvToListConverter().convert(csvString);
    List<CsvData> parsedData =
        rowsAsListOfValues.skip(1).map((row) => CsvData.fromList(row)).toList();
    setState(() {
      csvData = parsedData;
    });
  }

  void loadData() async {
    print("loadData");
    classes = await fetchClassesFromDatabase();
    print(classes);
  }

  Future<List<Class>> fetchClassesFromDatabase() async {
    Map<String, List<CsvData>> studentDataByClass =
        await DatabaseHelper.instance.getCsvDataGroupedByClass(widget.testType);
    List<Class> classes = studentDataByClass.entries.map((entry) {
      List<Student> students =
          entry.value.map((csvData) => Student.fromCsvData(csvData)).toList();
      return Class(className: entry.key, students: students);
    }).toList();
    return classes;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: (widget.testType == 1)
              ? const Text("Fitness Test")
              : const Text("Mock Test"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 2 / 1,
                        children: choices
                            .map((e) => SelectCard(
                                choice: e,
                                onSelect: _onSelectTest,
                                testType: widget.testType))
                            .toList(),
                      ),
                    ),
                    // Sync & Report Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xffF1F1F1),
                              ),
                              onPressed: () async {
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                if (widget.testType == 1 &&
                                    prefs.getBool('activatedUser') == false) {
                                  print('User Not Activated!');
                                } else {
                                  syncData();
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/sync.png',
                                    width: 24,
                                    height: 24,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Sync',
                                      style: TextStyle(color: Colors.black)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff00C485),
                              ),
                              onPressed: () async {
                                // checkActivation(context,widget.testType, false);
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                if (widget.testType == 1 &&
                                    prefs.getBool('activatedUser') == false) {
                                  print('User Not Activated!');
                                } else {
                                  generateReport();
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/report.png',
                                    width: 24,
                                    height: 24,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Report',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
      routes: {
        '/sitUp': (context) => SitUpScreen(testType: widget.testType),
        '/broadJump': (context) => BroadJumpScreen(testType: widget.testType),
        '/sitAndReach': (context) =>
            SitAndReachScreen(testType: widget.testType),
        '/pullUp': (context) => PullUpScreen(testType: widget.testType),
        '/shuttleRun': (context) => ShuttleRunScreen(testType: widget.testType),
        '/run': (context) => KmRunScreen(testType: widget.testType),
      },
    );
  }

  void _onSelectTest(int testType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FitnessTestScreen(testType: testType),
      ),
    );
  }

  Future<void> checkActivation(
      BuildContext context, int testType, bool flag) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (testType == 1 && prefs.getBool('activatedUser') == false) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User Not Activated!')),
      );
    } else {}
  }

  void syncData() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Colors.black,
                ),
                SizedBox(width: 16),
                Text("Syncing data..."),
              ],
            ),
          ),
        );
      },
    );

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final schoolId = prefs.getString('schoolId' ?? '');

    if (schoolId != '') {
      final path = (widget.testType == 1)
          ? "https://13.49.228.139/api/schools/$schoolId/students"
          : "https://13.49.228.139/api/schools/$schoolId/mock/students";

      List<Map<String, dynamic>> studentsData = [];

      for (var classItem in classes) {
        for (var student in classItem.students) {
          studentsData.add({
            'id': student.regNo.toString(),
            'name': student.name,
            'class': student.classVal,
            'gender': student.gender,
            'dob': student.dob,
            'attendanceStatus': student.attendanceStatus,
            'sitUpReps': student.sitUpReps,
            'broadJumpCm': student.broadJumpCm,
            'sitAndReachCm': student.sitAndReachCm,
            'pullUpReps': student.pullUpReps,
            'shuttleRunSec': student.shuttleRunSec,
            'runTime': student.runTime,
            'pftTestDate': student.pftTestDate,
            'uploadDate': student.pftTestDate,
          });
        }
      }

      final response = await http.post(
        Uri.parse(path),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(studentsData),
      );

      if (response.statusCode == 201) {
        print('All student data synced successfully.');
      } else {
        print('Failed to sync data.\n${response.statusCode}\n${response.body}');
      }
    } else {
      print('Invalid School Id!');
    }

    // Hide loading dialog
    Navigator.of(context).pop();
  }

  void generateReport() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Colors.black,
                ),
                SizedBox(width: 16),
                Text("Generating Report..."),
              ],
            ),
          ),
        );
      },
    );

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final schoolId = prefs.getString('schoolId' ?? '');

    if (schoolId != '') {
      final path = (widget.testType == 1)
          ? "http://13.49.228.139:5000/api/schools/$schoolId/students/"
          : "http://13.49.228.139:5000/api/schools/$schoolId/mock/students";

      final response = await http.get(
        Uri.parse(path),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);

        List<CsvData> dataList = [];

        for (var studentJson in responseData) {
          if (studentJson.containsKey('uploadDate')) {
            studentJson.remove('uploadDate');
          }
          CsvData student = CsvData.fromList2(studentJson);
          dataList.add(student);
        }

        final dbHelper = DatabaseHelper.instance;
        await dbHelper.insertCsvData(dataList, widget.testType);

        print('Generate report successful!!!');
        List<CsvData> importedData = await dbHelper.getAllCsvData(widget.testType);

        setState(() {
          csvData = importedData;
        });

        classes = await fetchClassesFromDatabase();

        Navigator.of(context).pop(); // Close the dialog
        if(widget.testType == 1){
          await _generateCSV(csvData, context);
        } else {
          // Navigate to the MockTestReportScreen
          Future.delayed(Duration.zero, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MockTestReportScreen(),
              ),
            );
          });
        }

      } else {
        Navigator.of(context).pop(); // Close the dialog in case of error
        print(
            'Failed to generate report!!!\n${response.statusCode}\n${response.body}');
      }
    } else {
      Navigator.of(context).pop(); // Close the dialog in case of error
      print('Invalid School Id!');
    }
  }


  Future<void> _generateCSV(List<CsvData> dataList, BuildContext context) async {
    try {
      List<List<dynamic>> rows = [];

      // Add header row
      rows.add([
        'Name',
        'ID',
        'Class',
        'Gender',
        'DOB',
        'Attendance Status',
        'Sit-Up Reps',
        'Broad Jump (cm)',
        'Sit and Reach (cm)',
        'Pull-Up Reps',
        'Shuttle Run (sec)',
        'Run Time',
        'PFT Test Date',
      ]);

      // Add data rows
      dataList.forEach((data) {
        rows.add([
          data.name,
          data.id,
          data.classVal,
          data.gender,
          data.dob,
          data.attendanceStatus,
          data.sitUpReps,
          data.broadJumpCm,
          data.sitAndReachCm,
          data.pullUpReps,
          data.shuttleRunSec,
          data.runTime,
          data.pftTestDate,
        ]);
      });

      // Get external storage directory (Android) or documents directory (iOS)
      Directory? directory = await getExternalStorageDirectory();
      if (directory == null) return; // Handle if directory is null

      // Create file path
      String filePath = '${directory.path}/report.csv';

      // Write CSV to file
      File csvFile = File(filePath);
      String csv = const ListToCsvConverter().convert(rows);
      await csvFile.writeAsString(csv);

      // Show a message or perform any other action after CSV generation
      print('CSV generated successfully at: $filePath');
    } catch (e) {
      print('Error generating CSV: $e');
      // Handle error as needed
    }
  }
}

const List<Choice> choices = <Choice>[
  Choice(title: 'Sit Up', asset: KImages.sitUp, route: '/sitUp'),
  Choice(title: 'Broad Jump', asset: KImages.broadJump, route: '/broadJump'),
  Choice(title: 'Sit and Reach', asset: KImages.sitAndReach, route: '/sitAndReach'),
  Choice(title: 'Pull Up', asset: KImages.pullUp, route: '/pullUp'),
  Choice(title: 'Shuttle Run', asset: KImages.shuttleRun, route: '/shuttleRun'),
  Choice(title: '1.6km/2.4km Run', asset: KImages.kmRun, route: '/run'),
];
