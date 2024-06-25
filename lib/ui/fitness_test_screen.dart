import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pt_app/ui/test_screens/km_run.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/const_images.dart';
import '../data/adminLog.dart';
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
import 'package:device_info_plus/device_info_plus.dart';

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
    loadData();
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
          adminLogCall("CSV imported");
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
                      .map((e) =>
                      SelectCard(
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

  Future<void> checkActivation(BuildContext context, int testType,
      bool flag) async {
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
          ? "http://51.20.95.159/api/schools/$schoolId/students"
          : "http://51.20.95.159/api/schools/$schoolId/mock/students";

      List<Map<String, dynamic>> studentsData = [];

      for (var classItem in classes) {
        for (var student in classItem.students) {
          studentsData.add({
            'no': student.no,
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
            'uploadDate': DateTime.now().toString(),
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
        adminLogCall("Data Synced");
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
          ? "http://51.20.95.159/api/schools/$schoolId/students/"
          : "http://51.20.95.159/api/schools/$schoolId/mock/students";

      try {
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
          adminLogCall("Report Generated");
          List<CsvData> importedData = await dbHelper.getAllCsvData(
              widget.testType);

          setState(() {
            csvData = importedData;
          });

          classes = await fetchClassesFromDatabase();

          Navigator.of(context).pop(); // Close the dialog
          // if (widget.testType == 1) {
          //   await _generateCSV(csvData, context);
          // } else {
            // Navigate to the MockTestReportScreen
            Future.delayed(Duration.zero, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MockTestReportScreen(csvData, widget.testType),
                ),
              );
            });
          // }
        } else {
          Navigator.of(context).pop(); // Close the dialog in case of error
          print(
              'Failed to generate report!!!\n${response.statusCode}\n${response
                  .body}');
        }
      } catch (e) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Oh no,,,!'),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } else {
      Navigator.of(context).pop(); // Close the dialog in case of error
      print('Invalid School Id!');
    }
  }


  Future<void> _generateCSV(List<CsvData> dataList,
      BuildContext context) async {
    try {
      List<List<dynamic>> rows = [];

      rows.add(['Instruction:', '', '', '', '', '', '', '', '', '', '', '', '']);
      rows.add(['1. Please do not delete any Rows or columns. You can upload the partially filled data.', '', '', '', '', '', '', '', '', '', '', '', '']);
      rows.add(['     The system will validate and if there are any errors the system will promot and will automatically update the records without error.', '', '', '', '', '', '', '', '', '', '', '', '']);
      rows.add(['2. When the downloaded file is re-uploaded existing values will be replaced with the new values.', '', '', '', '', '', '', '', '', '', '', '', '']);
      rows.add(['3. Attendance status should be one of the following values (P/A/L/O/H/E)', '', '', '', '', '', '', '', '', '', '', '', '']);
      rows.add(['     P - Present', '', '', '', '', '', '', '', '', '', '', '', '']);
      rows.add(['     A - Absent', '', '', '', '', '', '', '', '', '', '', '', '']);
      rows.add(['     L - Long Term MC', '', '', '', '', '', '', '', '', '', '', '', '']);
      rows.add(['     O - Short Term MC', '', '', '', '', '', '', '', '', '', '', '', '']);
      rows.add(['     E - Special Case', '', '', '', '', '', '', '', '', '', '', '', '']);
      rows.add(['     H - Pending appointment Student Health Services', '', '', '', '', '', '', '', '', '', '', '', '']);
      rows.add(['4. Please save your updated file in CSV(Comma delimited) format only.', '', '', '', '', '', '', '', '', '', '', '', '']);
      rows.add(['5.  The value of Sit Up reps should be numeric and it can be up to 2 digits.', '', '', '', '', '', '', '', '', '', '', '', '']);
      rows.add(['6.  The value of Broad Jump should be numeric and it can be up to 3 digits.', '', '', '', '', '', '', '', '', '', '', '', '']);
      rows.add(['7.  The value of Sit& Reach should be numeric and it can be up to 2 digits.', '', '', '', '', '', '', '', '', '', '', '', '']);
      rows.add(['8.  The value of IPU/Push-up reps should be numeric and it can be up to 2 digits. (Applicable for PRE-U)', '', '', '', '', '', '', '', '', '', '', '', '']);
      rows.add(['9.  The value of IPU/Pull-up reps should be numeric and it can be up to 2 digits. ', '', '', '', '', '', '', '', '', '', '', '', '']);
      rows.add(['10. The value of Shuttle Run time should be numeric and it has to be either 2 or 3 digits with 1 decimal place allowed', '', '', '', '', '', '', '', '', '', '', '', '']);
      rows.add(['11. The value of 1.6/2.4 km Run should be numeric and it has to be either 3 or 4 digits e.g. 10 Minutes and 45 seconds will be entered as 1045', '', '', '', '', '', '', '', '', '', '', '', '']);
      rows.add(['     another example 9 minute 45 seconds will be entered as 945', '', '', '', '', '', '', '', '', '', '', '', '']);

      // Add header row
      rows.add([
        'No',
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
          data.no,
          data.name,
          data.id,
          data.classVal,
          data.gender,
          data.dob,
          data.attendanceStatus,
          data.sitUpReps == -1 ? "" : data.sitUpReps ,
          data.broadJumpCm == -1 ? "" : data.broadJumpCm,
          data.sitAndReachCm == -1 ? "" : data.sitAndReachCm,
          data.pullUpReps == -1 ? "" : data.pullUpReps,
          data.shuttleRunSec == -1 ? "" : data.shuttleRunSec,
          data.runTime == -1 ? "" : data.runTime,
          data.pftTestDate,
        ]);
      });

      // Get external storage directory (Android) or documents directory (iOS)
      Directory? directory;
      if (Platform.isAndroid) {
        var isGranted = true;

        var androidInfo = await DeviceInfoPlugin().androidInfo;
        var sdkInt = androidInfo.version.sdkInt;

        // check if Android version is 14 or above
        if (sdkInt < 34) {
          isGranted = await Permission.storage
              .request()
              .isGranted;
        }

        if (isGranted) {
          directory = await getExternalStorageDirectory();
          if (directory != null) {
            String newPath = '';
            List<String> paths = directory.path.split('/');
            for (int i = 1; i < paths.length; i++) {
              String pathSegment = paths[i];
              if (pathSegment != 'Android') {
                newPath += '/' + pathSegment;
              } else {
                break;
              }
            }
            newPath = newPath + '/Download';
            directory = Directory(newPath);
          }
        } else {
          // Handle the case where permissions are denied
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Permission denied to access storage')),
          );
          return;
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      if (directory == null) return; // Handle if directory is null

      // Create file path
      String filePath = '${directory.path}/report.csv';

      // Write CSV to file
      File csvFile = File(filePath);
      String csv = const ListToCsvConverter().convert(rows);
      await csvFile.writeAsString(csv);

      // Show a message or perform any other action after CSV generation
      print('CSV generated successfully at: $filePath');

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Success'),
            content: Text('report.csv generated successfully at Downloads folder.'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
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
