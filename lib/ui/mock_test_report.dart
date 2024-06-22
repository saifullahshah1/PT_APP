import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import '../constants/const_data.dart';
import '../model/class.dart';
import '../model/student.dart';
import 'fitness_test_screen.dart'; // For firstWhereOrNull extension

class MockTestReportScreen extends StatefulWidget {
  MockTestReportScreen({Key? key}) : super(key: key);

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
      int sitUpPoints = kData.calculatePoints(1, student.age, student.gender, student.sitUpReps);
      int broadJumpPoints = kData.calculatePoints(2, student.age, student.gender, student.broadJumpCm);
      int pullUpPoints = kData.calculatePoints(3, student.age, student.gender, student.pullUpReps);
      int sitAndReachPoints = kData.calculatePoints(4, student.age, student.gender, student.sitAndReachCm);
      int shuttleRunPoints = kData.calculatePointsForShuttleRun(5, student.age, student.gender, student.shuttleRunSec);
      int kmRunPoints = kData.calculatePointsForKmRun(6, student.age, student.gender, student.runTime);

      int totalPoints = sitUpPoints + broadJumpPoints + pullUpPoints + sitAndReachPoints + shuttleRunPoints;

      // Categorize award based on total points
      if (totalPoints >= 21) {
        goldCount++;
      } else if (totalPoints >= 15) {
        silverCount++;
      } else if (totalPoints >= 6) {
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
        title: const Text('Mock Test Screen'),
        centerTitle: true,
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
}
