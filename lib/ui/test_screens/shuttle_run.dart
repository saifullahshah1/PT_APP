import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pt_app/utils/utils.dart';

import '../../data/db.dart';
import '../../model/class.dart';
import '../../model/student.dart';
import '../../constants/const_data.dart';
import '../widgets/NumberContainer.dart';
import '../fitness_test_screen.dart';

class ShuttleRunScreen extends StatefulWidget {
  final int testType;

  ShuttleRunScreen({Key? key, required this.testType}) : super(key: key);

  @override
  _ShuttleRunScreenState createState() => _ShuttleRunScreenState();
}

class _ShuttleRunScreenState extends State<ShuttleRunScreen> {
  String? selectedClass;
  int? _selectedRegNo;

  double reps = 0;
  final TextEditingController _repsController = TextEditingController();
  int points = 5;
  int totalPoints = 0;

  bool _switchValue = true;
  bool isTimerRunning = false;
  Duration duration = const Duration(seconds: 0);
  Timer? timer;

  bool isLoading = true;
  Student? selectedStudent;
  List<Map<String, dynamic>> currentPointsTable = [];
  var tapBack = false;

  List<Student>? _getSelectedClassStudents() {
    return classes
        .firstWhereOrNull((cls) => cls.className == selectedClass)
        ?.students;
  }

  @override
  void initState() {
    super.initState();
    print("initState");
    loadData();
  }

  void loadData() async {
    // classes = await fetchClassesFromDatabase();

    // Automatically select the first class and the first student's regNo if available
    if (classes.isNotEmpty) {
      selectedClass = classes.first.className;
      if (classes.first.students.isNotEmpty) {
        _selectedRegNo = classes.first.students.first.regNo;
        selectedStudent = classes.first.students.first;
        currentPointsTable =
            _getPointsTable(); // Update points table after selecting the student
      }
    }
    setState(() {
      isLoading = false; // Data loading completed
    }); // To refresh the UI after loading data
  }

  Student _getStudentData() {
    final selectedStudent = _getSelectedClassStudents()!
        .firstWhere((student) => student.regNo == _selectedRegNo);
    return selectedStudent;
  }

  List<Map<String, dynamic>> _getPointsTable() {
    //   selectedStudent = _getStudentData();
    if (selectedStudent != null) {
      KData kData = KData();
      print("Reg NO: $_selectedRegNo");
      currentPointsTable = kData.getPointsTable(
          selectedStudent!.age, selectedStudent!.gender, 5);
      return currentPointsTable;
    } else {}
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shuttle Run')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (selectedStudent == null ||
        selectedClass == null ||
        _selectedRegNo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shuttle Run')),
        body: const Center(child: Text('No data available.')),
      );
    }

    if (reps == 0) {
      if (tapBack) {
        tapBack = false;
      } else if (selectedStudent != null && selectedStudent?.shuttleRunSec != -1) {
        _repsController.text = selectedStudent!.shuttleRunSec.toString();
        reps = selectedStudent!.shuttleRunSec;
        points = calculatePoints(reps, _getPointsTable());
      } else {
        _repsController.clear();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shuttle Run'),
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
                              _selectedRegNo = null; // Reset selected regNo
                              _selectedRegNo = classes
                                  .firstWhere((Class cls) =>
                                      cls.className == selectedClass)
                                  .students
                                  .first
                                  .regNo;
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
              // Reg No. Selection
              SizedBox(
                height: 300, // Set to a suitable height for your use case
                child: GridView.builder(
                  itemCount: _getSelectedClassStudents()?.length ?? 0,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 10,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final student = _getSelectedClassStudents()![index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRegNo = student.regNo;
                          selectedStudent = _getStudentData();
                          reps = 0;
                          points = 0;
                          _repsController.clear();
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedRegNo == student.regNo
                              ? const Color(0xff00C485)
                              : student.shuttleRunSec == -1 ? const Color(0xffF1F1F1) : const Color(0xffC9C9C9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${student.no}',
                            style: TextStyle(
                              color: _selectedRegNo == student.regNo
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              Row(
                children: [
                  // Left Side
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // Align all text to the start
                          children: [
                            const SizedBox(
                              height: 10.0,
                            ),
                            // Name Selection
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Name',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 5.0),
                            _buildStudentDetails(0),

                            const SizedBox(height: 10.0),
                            // Gender & Age
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Gender',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(height: 5.0),
                                      _buildStudentDetails(2),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Age',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(height: 5.0),
                                      _buildStudentDetails(1),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20.0),
                            // Scale Table
                            Container(
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: const Color(0xffEAEAEA)),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Table(
                                border: TableBorder.symmetric(
                                  inside: const BorderSide(
                                      color: Color(0xffEAEAEA)),
                                  outside: BorderSide.none,
                                ),
                                children: [
                                  TableRow(
                                    children: [
                                      Container(
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(10.0),
                                          ),
                                          color: Color(0xff0A0A0A),
                                        ),
                                        padding: const EdgeInsets.all(8.0),
                                        child: const Center(
                                          child: Text(
                                            'Time',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(10.0),
                                          ),
                                          color: Color(0xff0A0A0A),
                                        ),
                                        padding: const EdgeInsets.all(8.0),
                                        child: const Center(
                                          child: Text(
                                            'Points',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ..._getPointsTable()
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final int index = entry.key;
                                    final Map<String, dynamic> row =
                                        entry.value;
                                    final rowColor =
                                        getColorForRow(row['time'], reps);
                                    return TableRow(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: index == 5
                                                ? const BorderRadius.only(
                                                    bottomLeft:
                                                        Radius.circular(10.0),
                                                  )
                                                : BorderRadius.zero,
                                            color: rowColor,
                                          ),
                                          padding: const EdgeInsets.all(8.0),
                                          child: Center(
                                            child: Text(row['time']),
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: index == 5
                                                ? const BorderRadius.only(
                                                    bottomRight:
                                                        Radius.circular(10.0),
                                                  )
                                                : BorderRadius.zero,
                                            color: rowColor,
                                          ),
                                          padding: const EdgeInsets.all(8.0),
                                          child: Center(
                                            child:
                                                Text(row['points'].toString()),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ]),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right Side
                  Expanded(
                    child: Column(
                      children: [
                        const SizedBox(height: 91),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text('Manual Entry'),
                            const SizedBox(width: 5),
                            Transform.scale(
                              scale: 0.8,
                              child: CupertinoSwitch(
                                value: _switchValue,
                                onChanged: (bool value) {
                                  if (isTimerRunning) {
                                    stopTimer();
                                  }
                                  setState(() {
                                    _switchValue = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        _switchValue ? _buildNumericPad() : _buildTimer(),
                        const SizedBox(
                          height: 10.0,
                        ),
                        // Next
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff00C485),
                                ),
                                onPressed: _updateShuttleRunSec,
                                child: const Text(
                                  'Enter',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color getColorForRow(String range, double reps) {
    // Helper function to parse range strings
    bool isInRange(String range, double reps) {
      if (range.startsWith('> ')) {
        double value = double.parse(range.substring(2));
        return reps > value;
      } else if (range.startsWith('< ')) {
        double value = double.parse(range.substring(2));
        return reps < value;
      } else if (range.contains('-')) {
        List<String> parts = range.split(' - ');
        double start = double.parse(parts[0]);
        double end = double.parse(parts[1]);
        return reps >= start && reps <= end;
      }
      return false;
    }

    if (isInRange(range, reps)) {
      return Color(0xffFFD5A1); // Skin color for the current range
    }
    return Color(0xffF1F1F1); // Default color
  }

  bool isInRange(String range, double reps) {
    if (range.startsWith('> ')) {
      double value = double.parse(range.substring(2));
      return reps > value;
    } else if (range.startsWith('< ')) {
      double value = double.parse(range.substring(2));
      return reps < value;
    } else if (range.contains('-')) {
      List<String> parts = range.split(' - ');
      double start = double.parse(parts[0]);
      double end = double.parse(parts[1]);
      return reps >= start && reps <= end;
    }
    return false;
  }

  int calculatePoints(double reps, List<Map<String, dynamic>> pointsTable) {
    for (var range in pointsTable) {
      var repsRange = range['time'];
      if (repsRange != null && isInRange(repsRange, reps)) {
        print("point: ${range['points']}");
        return range['points'];
      }
      print("inside");
    }
    print("here");
    return 0; // Default points if no range matches
  }

  void _updateShuttleRunSec() async {
    if (_selectedRegNo == null) return;

    // Stop the timer if it's running
    if (isTimerRunning) {
      stopTimer();
    }

    // Determine the value to be used for reps based on the switch value
    if (!_switchValue) {
      // If manual entry is not selected, use the timer value
      reps = duration.inSeconds.toDouble();
    }

    // Update the reps for the current student in the classes list
    for (var classItem in classes) {
      for (var i = 0; i < classItem.students.length; i++) {
        if (classItem.students[i].regNo == _selectedRegNo) {
          setState(() {
            classItem.students[i] =
                classItem.students[i].copyWith(shuttleRunSec: reps);
          });

          // Update the reps in the database
          await DatabaseHelper.instance
              .updateShuttleRunSec(classItem.students[i].regNo, reps,widget.testType);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Shuttle run time updated successfully!')),
          );

          // navigate to next student if available
          if (i < classItem.students.length - 1) {
            setState(() {
              _selectedRegNo = classItem.students[i + 1].regNo;
              selectedStudent = _getStudentData();
              reps = 0;
              points = 0;
              _repsController.clear();
            });
          }

          return;
        }
      }
    }
  }

  void _addDecimalPoint() {
    if (!_repsController.text.contains('.')) {
      _repsController.text += '.';
      setState(() {
        reps = double.tryParse(_repsController.text) ?? 0;
        points = calculatePoints(reps, currentPointsTable);
      });
    }
  }

  void startTimer() {
    setState(() {
      isTimerRunning = true;
      // duration = const Duration(seconds: 0);
    });
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        final seconds = duration.inSeconds + 1;
        duration = Duration(seconds: seconds);
      });
    });
  }

  void stopTimer() {
    setState(() {
      isTimerRunning = false;
      timer?.cancel();
    });
  }

  void resetTimer() {
    setState(() {
      isTimerRunning = false;
      timer?.cancel();
      duration = const Duration(seconds: 0);
    });
  }

  Widget _buildStudentDetails(int attribute) {
    final selectedStudent = _getSelectedClassStudents()!
        .firstWhere((student) => student.regNo == _selectedRegNo);

    String displayText;
    switch (attribute) {
      case 0:
        displayText = selectedStudent.name;
        break;
      case 1:
        displayText = '${selectedStudent.age}';
        break;
      case 2:
        displayText = selectedStudent.gender;
        break;
      default:
        displayText = '';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffF1F1F1), // Set the desired grey shade here
        borderRadius:
            BorderRadius.circular(10.0), // Set the desired border radius here
      ),
      child: TextField(
        enabled: false, // Make the TextField non-editable
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.fromLTRB(16.0, 4.0, 4.0,
              4.0), // Optional: Add padding inside the TextField
        ),
        style: const TextStyle(color: Color(0xff0A0A0A)),
        controller: TextEditingController(text: displayText),
      ),
    );
  }

  Widget _buildTimer() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xffF1F1F1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.all(28.0),
                child: Center(
                  child: Text(
                    '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (isTimerRunning) ...[
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFF5C5C),
                  ),
                  onPressed: stopTimer,
                  child: const Text(
                    'Stop',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ] else ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff00C485),
                ),
                onPressed: startTimer,
                child: const Text(
                  'Start',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0A0A0A),
                ),
                onPressed: resetTimer,
                child: const Text(
                  'Reset',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildNumericPad() {
    return Column(
      children: [
        // Time & Points
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Time',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 5.0),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xffF1F1F1),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Enter Time',
                        hintStyle: TextStyle(color: Color(0xffC9C9C9)),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.fromLTRB(16.0, 4.0, 4.0, 4.0),
                      ),
                      style: const TextStyle(color: Color(0xff0A0A0A)),
                      controller: _repsController,
                      onChanged: (text) {
                        setState(() {
                          reps = double.tryParse(text) ?? 0;
                          points = calculatePoints(reps, _getPointsTable());
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Points',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 5.0),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xffF1F1F1),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding:
                          const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 14.0),
                      child: Text(
                        '$points',
                        style: const TextStyle(color: Color(0xff0A0A0A)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            NumberContainer('7', () {
              setState(() {
                _repsController.text += '7';
                reps = double.tryParse(_repsController.text) ?? 0;
                points = calculatePoints(reps, currentPointsTable);
              });
            }),
            const SizedBox(width: 1.0),
            NumberContainer('8', () {
              setState(() {
                _repsController.text += '8';
                reps = double.tryParse(_repsController.text) ?? 0;
                points = calculatePoints(reps, currentPointsTable);
              });
            }),
            const SizedBox(width: 1.0),
            NumberContainer('9', () {
              setState(() {
                _repsController.text += '9';
                reps = double.tryParse(_repsController.text) ?? 0;
                points = calculatePoints(reps, currentPointsTable);
              });
            }),
          ],
        ),
        const SizedBox(height: 2.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            NumberContainer('4', () {
              setState(() {
                _repsController.text += '4';
                reps = double.tryParse(_repsController.text) ?? 0;
                points = calculatePoints(reps, currentPointsTable);
              });
            }),
            const SizedBox(width: 1.0),
            NumberContainer('5', () {
              setState(() {
                _repsController.text += '5';
                reps = double.tryParse(_repsController.text) ?? 0;
                points = calculatePoints(reps, currentPointsTable);
              });
            }),
            const SizedBox(width: 1.0),
            NumberContainer('6', () {
              setState(() {
                _repsController.text += '6';
                reps = double.tryParse(_repsController.text) ?? 0;
                points = calculatePoints(reps, currentPointsTable);
              });
            }),
          ],
        ),
        const SizedBox(height: 2.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            NumberContainer('1', () {
              setState(() {
                _repsController.text += '1';
                reps = double.tryParse(_repsController.text) ?? 0;
                points = calculatePoints(reps, currentPointsTable);
              });
            }),
            const SizedBox(width: 1.0),
            NumberContainer('2', () {
              setState(() {
                _repsController.text += '2';
                reps = double.tryParse(_repsController.text) ?? 0;
                points = calculatePoints(reps, currentPointsTable);
              });
            }),
            const SizedBox(width: 1.0),
            NumberContainer('3', () {
              setState(() {
                _repsController.text += '3';
                reps = double.tryParse(_repsController.text) ?? 0;
                points = calculatePoints(reps, currentPointsTable);
              });
            }),
          ],
        ),
        const SizedBox(height: 2.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            NumberContainer('0', () {
              setState(() {
                _repsController.text += '0';
                reps = double.tryParse(_repsController.text) ?? 0;
                points = calculatePoints(reps, currentPointsTable);
              });
            }),
            const SizedBox(width: 1.0),
            NumberContainer('.', () {
              setState(() {
                _addDecimalPoint();
              });
            }),
            const SizedBox(width: 1.0),
            NumberContainer('⌫', () {
              tapBack = true;
              setState(() {
                if (_repsController.text.isNotEmpty) {
                  _repsController.text = _repsController.text
                      .substring(0, _repsController.text.length - 1);
                }
                reps = double.tryParse(_repsController.text) ?? 0;
                points = calculatePoints(reps, currentPointsTable);
              });
            }, backgroundColor: const Color(0xffC9C9C9)),
          ],
        ),
      ],
    );
  }
}