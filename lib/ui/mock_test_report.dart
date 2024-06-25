import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/const_data.dart';
import '../data/csv_data.dart';
import '../model/class.dart';
import '../model/student.dart';
import 'fitness_test_screen.dart'; // For firstWhereOrNull extension
import 'package:device_info_plus/device_info_plus.dart';

class MockTestReportScreen extends StatefulWidget {
  final List<CsvData> csvData;
  final int testType;

  MockTestReportScreen(this.csvData, this.testType, {Key? key}) : super(key: key);

  @override
  _MockTestReportScreenState createState() => _MockTestReportScreenState();
}

class _MockTestReportScreenState extends State<MockTestReportScreen> {
  String? selectedClass;
  KData kData = KData();

  static const Color tableHeaderColor = Color(0xff00C485);
  static const Color countRowColor =  Color(0xffEAEAEA);
  static const Color textColorWhite = Color(0xffFAFAFA);
  static const Color textColorBlack = Color(0xff0A0A0A);

  @override
  void initState() {

    if (classes.isNotEmpty) {
      selectedClass = classes.first.className;
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Variables to count the number of students in each award category
    int goldCount = 0;
    int silverCount = 0;
    int bronzeCount = 0;
    int failCount = 0;

    // Calculate total points for each student and categorize awards
    var studentRows = _getSelectedClassStudents()?.mapIndexed((index, student) {

      int threshold = 0;

      int sitUpPoints = kData.calculatePoints(1, student.age, student.gender, student.sitUpReps);
      int broadJumpPoints = kData.calculatePoints(2, student.age, student.gender, student.broadJumpCm);
      int sitAndReachPoints = kData.calculatePoints(3, student.age, student.gender, student.sitAndReachCm);
      int pullUpPoints = kData.calculatePoints(4, student.age, student.gender, student.pullUpReps);
      int shuttleRunPoints = kData.calculatePointsForShuttleRun(5, student.age, student.gender, student.shuttleRunSec);
      int kmRunPoints = kData.calculatePointsForKmRun(6, student.age, student.gender, student.runTime);

      int totalPoints = sitUpPoints + broadJumpPoints + pullUpPoints + sitAndReachPoints + shuttleRunPoints + kmRunPoints;

      if(sitUpPoints >= 3 && broadJumpPoints >= 3 && pullUpPoints >= 3 && sitAndReachPoints >= 3  && shuttleRunPoints >= 3 && kmRunPoints >= 3){
        threshold = 3;
      } else if(sitUpPoints >= 2 && broadJumpPoints >= 2 && pullUpPoints >= 2 && sitAndReachPoints >= 2  && shuttleRunPoints >= 2 && kmRunPoints >= 2){
        threshold = 2;
      }else if(sitUpPoints >= 1 && broadJumpPoints >= 1 && pullUpPoints >= 1 && sitAndReachPoints >= 1  && shuttleRunPoints >= 1 && kmRunPoints >= 1){
        threshold = 1;
      }else {
        threshold = 0;
      }


      // Categorize award based on total points
      if (totalPoints >= 21 && threshold == 3) {
        goldCount++;
      } else if (totalPoints >= 15 && threshold == 2) {
        silverCount++;
      } else if (totalPoints >= 6 && threshold == 1) {
        bronzeCount++;
      } else {
        failCount++;
      }

      return TableRow(
        decoration: BoxDecoration(
          color: index.isEven ? const Color(0xffEAEAEA) : Colors.white,
        ),
        children: [
          _buildTableCell('${student.no}', true, false, true, false, const Color(0xffF1F1F1)),
          _buildTableCell('${student.sitUpReps == -1 ? '' : student.sitUpReps} ($sitUpPoints)', false, false, false, false, const Color(0xffE7E4FF)),
          _buildTableCell('${student.broadJumpCm == -1 ? '' : student.broadJumpCm} ($broadJumpPoints)', false, false, false, false, const Color(0xffFFEAD0)),
          _buildTableCell('${student.pullUpReps == -1 ? '' : student.pullUpReps} ($pullUpPoints)', false, false, false, false, const Color(0xffFFDBDB)),
          _buildTableCell('${student.sitAndReachCm == -1 ? '' : student.sitAndReachCm} ($sitAndReachPoints)', false, false, false, false, const Color(0xffE4E4E4)),
          _buildTableCell('${student.shuttleRunSec == -1 ? '' : student.shuttleRunSec} ($shuttleRunPoints)', false, false, false, false, const Color(0xffFFE7DA)),
          _buildTableCell('${student.runTime == -1 ? '' : student.runTime} ($kmRunPoints)', false, false, false, false, const Color(
              0xffb3fbe3)),
          _buildTableCell('$totalPoints', false, true, false, true, const Color(0xffF1F1F1)),
        ],
      );
    }).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.testType == 1 ? "Test Results Screen" : 'Mock Test Results Screen'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.save), // Replace with your desired icon
            onPressed: () {
              // Implement the action when the button is pressed
              // For example, navigate to another screen, show a dialog, etc.
              _generateCSV(widget.csvData, widget.testType, context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Class Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15.0),
                        color: const Color(0xffF1F1F1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedClass,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedClass = newValue;
                            });
                          },
                          items: classes
                              .map<DropdownMenuItem<String>>((Class classItem) {
                            return DropdownMenuItem<String>(
                              value: classItem.className,
                              child: Text(classItem.className),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Table Header
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xffEAEAEA)),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Table(
                  border: TableBorder.symmetric(
                    inside: const BorderSide(color: Color(0xffEAEAEA)),
                    outside: BorderSide.none,
                  ),
                  children: [
                    TableRow(
                      children: [
                        _buildTableHeaderCell('No', true, false),
                        _buildTableHeaderCell('Sit Up', false, false, const Color(0xffA9A1FF)),
                        _buildTableHeaderCell('B-Jump', false, false, const Color(0xffFFCB8A)),
                        _buildTableHeaderCell('Pull Up', false, false, const Color(0xffFF7D7D)),
                        _buildTableHeaderCell('Sit & Reach', false, false, const Color(0xff434343)),
                        _buildTableHeaderCell('Shuttle Run', false, false, const Color(0xffFFA36E)),
                        _buildTableHeaderCell('Km Run', false, false, const Color(0xff00C485)),
                        _buildTableHeaderCell('Result', false, true),
                      ],
                    ),
                    ...studentRows,
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Result Summary
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xffEAEAEA)),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Table(
                  border: TableBorder.symmetric(
                    inside: const BorderSide(color: Color(0xffEAEAEA)),
                    outside: BorderSide.none,
                  ),
                  children: [
                    // Header Row
                    TableRow(
                      children: [
                        _buildTableHeaderCell2('Gold', true, false, false, false),
                        _buildTableHeaderCell2('Silver', false, false, false, false),
                        _buildTableHeaderCell2('Bronze', false, false, false, false),
                        _buildTableHeaderCell2('Fail', false, true, false, false),
                      ],
                    ),
                    // Count Row
                    TableRow(
                      children: [
                        _buildTableCell2(goldCount.toString(), true, false, false, false, countRowColor, textColorBlack),
                        _buildTableCell2(silverCount.toString(), false, false, false, false, countRowColor, textColorBlack),
                        _buildTableCell2(bronzeCount.toString(), false, false, false, false, countRowColor, textColorBlack),
                        _buildTableCell2(failCount.toString(), false, true, false, false, countRowColor, textColorBlack),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String title, bool isFirst, bool isLast, [Color? color]) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? const Color(0xff0A0A0A),
        borderRadius: BorderRadius.only(
          topLeft: isFirst ? const Radius.circular(10.0) : Radius.zero,
          topRight: isLast ? const Radius.circular(10.0) : Radius.zero,
        ),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTableCell(String content, bool isFirst, bool isLast, bool isTopLeft, bool isTopRight, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
      ),
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(content),
      ),
    );
  }

  // Helper method to build table header cell
  Widget _buildTableHeaderCell2(String title, bool isFirst, bool isLast, bool isBottomLeft, bool isBottomRight) {
    return Container(
      decoration: BoxDecoration(
        color: tableHeaderColor,
        borderRadius: BorderRadius.only(
          topLeft: isFirst ? const Radius.circular(10.0) : Radius.zero,
          topRight: isLast ? const Radius.circular(10.0) : Radius.zero,
          bottomLeft: isBottomLeft ? const Radius.circular(10.0) : Radius.zero,
          bottomRight: isBottomRight ? const Radius.circular(10.0) : Radius.zero,
        ),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(color: textColorWhite, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Helper method to build table cell
  Widget _buildTableCell2(String content, bool isFirst, bool isLast, bool isTopLeft, bool isTopRight, Color color, [Color textColor = textColorWhite]) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: isTopLeft ? const Radius.circular(10.0) : Radius.zero,
          topRight: isTopRight ? const Radius.circular(10.0) : Radius.zero,
          bottomLeft: isFirst ? const Radius.circular(10.0) : Radius.zero,
          bottomRight: isLast ? const Radius.circular(10.0) : Radius.zero,
        ),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          content,
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }

  List<Student>? _getSelectedClassStudents() {
    return classes
        .firstWhereOrNull((cls) => cls.className == selectedClass)
        ?.students;
  }

  Future<void> _generateCSV(List<CsvData> dataList,
      int testType,
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

        // check if Android version is lower than 14
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
        }else {
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
      String filePath = testType == 1 ? '${directory.path}/report.csv' : '${directory.path}/mock_report.csv';

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
            content: Text(testType == 1 ? 'report.csv generated successfully at Downloads folder.' : 'mock_report.csv generated successfully at Downloads folder.'),
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
