import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/db.dart';
import '../../model/class.dart';
import '../../model/student.dart';
import '../../constants/const_data.dart';
import '../widgets/NumberContainer.dart';
import '../fitness_test_screen.dart';

class PullUpScreen extends StatefulWidget {
  final int testType;

  PullUpScreen({Key? key, required this.testType}) : super(key: key);

  @override
  _PullUpScreenState createState() => _PullUpScreenState();
}

class _PullUpScreenState extends State<PullUpScreen> {
  String? selectedClass;
  int? _selectedRegNo;

  int reps = 0;
  int points = 0;
  int totalPoints = 0;
  final TextEditingController _repsController = TextEditingController();

  bool isTimerRunning = false;
  Duration duration = const Duration(minutes: 1);
  Timer? timer;

  bool isLoading = true; // Add this flag
  Student? selectedStudent;
  List<Map<String, dynamic>> currentPointsTable = [];
  var tapBack = false;

  @override
  void initState() {
    super.initState();
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

  List<Student>? _getSelectedClassStudents() {
    return classes
        .firstWhereOrNull((cls) => cls.className == selectedClass)
        ?.students;
  }

  List<Map<String, dynamic>> _getPointsTable() {
    //   selectedStudent = _getStudentData();
    if (selectedStudent != null) {
      KData kData = KData();
      print("Reg NO: $_selectedRegNo");
      currentPointsTable = kData.getPointsTable(
          selectedStudent!.age, selectedStudent!.gender, 4);
      return currentPointsTable;
    } else {}
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pull Up')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (selectedStudent == null ||
        selectedClass == null ||
        _selectedRegNo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pull Up')),
        body: const Center(child: Text('No data available.')),
      );
    }

    bool shouldShowInclinedPullUp = (selectedStudent!.gender == 'F') || (selectedStudent!.gender == 'M' && selectedStudent!.age < 15);

    if (reps == 0) {
      if (tapBack) {
        tapBack = false;
      } else if (selectedStudent != null && selectedStudent?.pullUpReps != -1) {
        _repsController.text = selectedStudent!.pullUpReps.toString();
        reps = selectedStudent!.pullUpReps;
        points = calculatePoints(reps, _getPointsTable());
      } else {
        _repsController.clear();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pull Up'),
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
                              : student.pullUpReps == -1 ? const Color(0xffF1F1F1) : const Color(0xffC9C9C9),
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
                            const SizedBox(height: 10.0,),
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
                            const SizedBox(height: 10.0),
                            Opacity(
                              opacity: shouldShowInclinedPullUp ? 1.0 : 0.0,
                              child: IgnorePointer(
                                ignoring: !shouldShowInclinedPullUp,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(6.0),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xffFFCB8A),
                                          ),
                                          onPressed: () {},
                                          child: const Text(
                                            'Inclined Pull Up',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10.0,
                            ),
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
                                            'Reps',
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
                                        getColorForRow(row['reps'], reps);
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
                                            child: Text(row['reps'].toString()),
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
                  Expanded(
                    child: Column(
                      children: [
                        // Timer
                        const SizedBox(height: 20.0,),
                        const SizedBox(height: 10.0),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xffF1F1F1),
                                  borderRadius: BorderRadius.circular(
                                      12.0), // Optional: Rounded corners
                                ),
                                padding: const EdgeInsets.all(28.0),
                                // Optional: Padding inside the container
                                child: Center(
                                  child: Text(
                                    '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Colors.black, // Optional: Text color
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 16),

                        // Reps & Points
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Reps',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 5.0),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xffF1F1F1),
                                      // Set the desired grey shade here
                                      borderRadius: BorderRadius.circular(
                                          10.0), // Set the desired border radius here
                                    ),
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        hintText: 'Enter Reps',
                                        hintStyle:
                                            TextStyle(color: Color(0xffC9C9C9)),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.fromLTRB(
                                            16.0,
                                            4.0,
                                            4.0,
                                            4.0), // Optional: Add padding inside the TextField
                                      ),
                                      style: const TextStyle(
                                          color: Color(0xff0A0A0A)),
                                      controller: _repsController,
                                      keyboardType: TextInputType.number,
                                      onChanged: (text) {
                                        setState(() {
                                          reps = int.parse(text);
                                          points = calculatePoints(
                                              reps, _getPointsTable());
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
                                        // Set the desired background color
                                        borderRadius: BorderRadius.circular(
                                            10.0), // Set the desired border radius
                                      ),
                                      padding: const EdgeInsets.fromLTRB(
                                          16.0, 14.0, 16.0, 14.0),
                                      // Optional: Add padding inside the Container
                                      child: Text(
                                        '$points',
                                        style: const TextStyle(
                                            color: Color(
                                                0xff0A0A0A)), // Set text color to ensure it's readable
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Numeric Pad
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            NumberContainer('7', () {
                              setState(() {
                                _repsController.text += '7';
                                reps = int.tryParse(_repsController.text) ?? 0;
                                points =
                                    calculatePoints(reps, currentPointsTable);
                              });
                            }),
                            const SizedBox(width: 1.0),
                            NumberContainer('8', () {
                              setState(() {
                                _repsController.text += '8';
                                reps = int.tryParse(_repsController.text) ?? 0;
                                points =
                                    calculatePoints(reps, currentPointsTable);
                              });
                            }),
                            const SizedBox(width: 1.0),
                            NumberContainer('9', () {
                              setState(() {
                                _repsController.text += '9';
                                reps = int.tryParse(_repsController.text) ?? 0;
                                points =
                                    calculatePoints(reps, currentPointsTable);
                              });
                            }),
                          ],
                        ),
                        const SizedBox(
                          height: 2.0,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            NumberContainer('4', () {
                              setState(() {
                                _repsController.text += '4';
                                reps = int.tryParse(_repsController.text) ?? 0;
                                points =
                                    calculatePoints(reps, currentPointsTable);
                              });
                            }),
                            const SizedBox(width: 1.0),
                            NumberContainer('5', () {
                              setState(() {
                                _repsController.text += '5';
                                reps = int.tryParse(_repsController.text) ?? 0;
                                points =
                                    calculatePoints(reps, currentPointsTable);
                              });
                            }),
                            const SizedBox(width: 1.0),
                            NumberContainer('6', () {
                              setState(() {
                                _repsController.text += '6';
                                reps = int.tryParse(_repsController.text) ?? 0;
                                points =
                                    calculatePoints(reps, currentPointsTable);
                              });
                            }),
                          ],
                        ),
                        const SizedBox(
                          height: 2.0,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            NumberContainer('1', () {
                              setState(() {
                                _repsController.text += '1';
                                reps = int.tryParse(_repsController.text) ?? 0;
                                points =
                                    calculatePoints(reps, currentPointsTable);
                              });
                            }),
                            const SizedBox(width: 1.0),
                            NumberContainer('2', () {
                              setState(() {
                                _repsController.text += '2';
                                reps = int.tryParse(_repsController.text) ?? 0;
                                points =
                                    calculatePoints(reps, currentPointsTable);
                              });
                            }),
                            const SizedBox(width: 1.0),
                            NumberContainer('3', () {
                              setState(() {
                                _repsController.text += '3';
                                reps = int.tryParse(_repsController.text) ?? 0;
                                points =
                                    calculatePoints(reps, currentPointsTable);
                              });
                            }),
                          ],
                        ),
                        const SizedBox(
                          height: 2.0,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            NumberContainer('0', () {
                              setState(() {
                                _repsController.text += '0';
                                reps = int.tryParse(_repsController.text) ?? 0;
                                points =
                                    calculatePoints(reps, currentPointsTable);
                              });
                            }, isDoubleWidth: true),
                            const SizedBox(width: 1.0),
                            NumberContainer(
                              '⌫',
                              () {
                                tapBack = true;
                                setState(() {
                                  if (_repsController.text.isNotEmpty) {
                                    _repsController.text = _repsController.text
                                        .substring(
                                            0, _repsController.text.length - 1);
                                  }
                                  reps =
                                      int.tryParse(_repsController.text) ?? 0;
                                  points =
                                      calculatePoints(reps, currentPointsTable);
                                });
                              },
                              backgroundColor: const Color(0xffC9C9C9),
                            ),
                          ],
                        ),

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
                                onPressed: _updatePullUpReps,
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

  Color getColorForRow(String range, int reps) {
    // Helper function to parse range strings
    bool isInRange(String range, int reps) {
      if (range.startsWith('> ')) {
        int value = int.parse(range.substring(2));
        return reps > value;
      } else if (range.startsWith('< ')) {
        int value = int.parse(range.substring(2));
        return reps < value;
      } else if (range.contains('-')) {
        List<String> parts = range.split(' - ');
        int start = int.parse(parts[0]);
        int end = int.parse(parts[1]);
        return reps >= start && reps <= end;
      }
      return false;
    }

    if (isInRange(range, reps)) {
      return Color(0xffFFD5A1); // Skin color for the current range
    }
    return Color(0xffF1F1F1); // Default color
  }

  int calculatePoints(int reps, List<Map<String, dynamic>> pointsTable) {
    for (var range in pointsTable) {
      if (_isInRange(range['reps'], reps)) {
        return range['points'];
      }
    }
    return 0; // Default points if no range matches
  }

  bool _isInRange(String range, int reps) {
    if (range.startsWith('> ')) {
      int value = int.parse(range.substring(2));
      return reps > value;
    } else if (range.startsWith('< ')) {
      int value = int.parse(range.substring(2));
      return reps < value;
    } else if (range.contains('-')) {
      List<String> parts = range.split(' - ');
      int start = int.parse(parts[0]);
      int end = int.parse(parts[1]);
      return reps >= start && reps <= end;
    }
    return false;
  }

  void startTimer() {
    setState(() {
      isTimerRunning = true;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        final seconds = duration.inSeconds - 1;
        if (seconds < 0) {
          stopTimer();
        } else {
          duration = Duration(seconds: seconds);
        }
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
    stopTimer();
    setState(() {
      duration = Duration(minutes: 1);
    });
  }

  void _updatePullUpReps() async {
    if (_selectedRegNo == null) return;

    // Update the reps for the current student in the classes list
    for (var classItem in classes) {
      for (var i = 0; i < classItem.students.length; i++) {
        if (classItem.students[i].regNo == _selectedRegNo) {
          setState(() {
            classItem.students[i] =
                classItem.students[i].copyWith(pullUpReps: reps);
          });

          // Update the reps in the database
          await DatabaseHelper.instance
              .updatePullUpReps(classItem.students[i].regNo, reps,widget.testType);

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
}

extension ListExtensions<E> on List<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
