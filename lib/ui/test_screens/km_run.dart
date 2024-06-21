import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pt_app/utils/utils.dart';
import '../../data/db.dart';
import '../../model/class.dart';
import '../../model/student.dart';
import '../fitness_test_screen.dart';

class KmRunScreen extends StatefulWidget {
  final int testType;

  KmRunScreen({Key? key, required this.testType}) : super(key: key);

  @override
  _KmRunScreenState createState() => _KmRunScreenState();
}

class _KmRunScreenState extends State<KmRunScreen> {
  String? selectedClass;
  int? _selectedRegNo;

  // Define a map to store the selected color for each student
  Map<int, Color> selectedColors = {};

  List<Color> colors = [
    const Color(0xffA9A1FF),
    const Color(0xffFFA36F),
    const Color(0xff434343),
    const Color(0xffFF7D7D),
    const Color(0xffF1F1F1),
    const Color(0xffFF5C5C),
    const Color(0xffFF8E4F),
    const Color(0xff33D09D),
  ];

  bool _filterValue = false;
  bool _runOptionValue = false;
  bool isTimerRunning = false;
  Duration duration = const Duration(seconds: 0);
  Timer? timer;

  bool isLoading = true;
  Student? selectedStudent;
  List<Map<String, dynamic>> currentPointsTable = [];

  bool dataStored = false;

  List<Student>? _getSelectedClassStudentsMain() {
    return classes
        .firstWhereOrNull((cls) => cls.className == selectedClass)
        ?.students;
  }



  List<Student>? _getSelectedClassStudents() {
    List<Student>? students = classes
        .firstWhereOrNull((cls) => cls.className == selectedClass)
        ?.students;

    if (_filterValue) {
      if (_runOptionValue) {
        // Students aged >= 14
        students = students?.where((student) => student.age >= 14).toList();
      } else {
        // Students aged <= 13
        students = students?.where((student) => student.age <= 13).toList();
      }
    }
    return students;
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    // Automatically select the first class and the first student's regNo if available
    if (classes.isNotEmpty) {
      selectedClass = classes.first.className;
    }
    setState(() {
      isLoading = false; // Data loading completed
    }); // To refresh the UI after loading data
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

  bool _checkAllStudentsOnLastLap() {
    final students = _getSelectedClassStudents();
    if (students == null) return false;
    for (var student in students) {
      if (student.level < (_runOptionValue ? 6 : 4)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _storeDataInDb(List<Student> students) async {
    print("Size: ${students.length}");
    for (var student in students) {
      print(
          "Storing data in the database for student: ${student.regNo} \t ${student.level} \t ${student.runTime}");
    }

    //Store the data in the database
    await DatabaseHelper.instance.saveStudents(students, widget.testType);
  }

  void _handleStudentSelection(Student student) {
    int maxLevel =
        _runOptionValue ? 6 : 4; // Determine max level based on run option
    if (student.level == maxLevel) {
      setState(() {
        _selectedRegNo = student.regNo;
        selectedStudent = student;
      });
      return;
    }
    setState(() {
      _selectedRegNo = student.regNo;
      selectedColors.putIfAbsent(student.regNo, () => const Color(0xffF1F1F1));

      // Increment lap level only if it's less than the max level
      if (student.level < maxLevel && student.level >= 0) {
        final selectedStudents = _getSelectedClassStudents();
        final mainStudentList = _getSelectedClassStudentsMain();
        if (selectedStudents != null && mainStudentList != null) {
          final index = selectedStudents.indexWhere((s) => s.regNo == student.regNo);
          final indexMain = mainStudentList.indexWhere((s) => s.regNo == student.regNo);
          if (index != -1 && indexMain != -1) {
            selectedStudents[index].level++; // Update the level directly in the list

            if (_runOptionValue) {
              selectedColors[student.regNo] = _getColorForLevel(student.level);
            } else {
              selectedColors[student.regNo] = _getColorForLevelWithoutRunOption(student.level);
            }

            selectedStudents[index] = student.copyWith(
              runTime: selectedStudents != null && selectedStudents.isNotEmpty && selectedStudents[index].level == maxLevel
                  ? duration.inSeconds : student.runTime,
            );
            selectedStudent = selectedStudents[index];
            mainStudentList[indexMain] = selectedStudents[index];
          }
        }
      }

      if (_checkAllStudentsOnLastLap() && !dataStored) {
        dataStored = true;
        _storeDataInDb(_getSelectedClassStudentsMain()!);
      }
    });
  }

  void _handleUndo() {
    setState(() {
      final selectedStudents = _getSelectedClassStudents();
      if (selectedStudents != null && _selectedRegNo != null) {
        final index =
            selectedStudents.indexWhere((s) => s.regNo == _selectedRegNo);
        if (index != -1) {
          Student student = selectedStudents[index];

          // Undo operation: decrement level
          if (student.level > 0) {
            student.level -= 1;

            // Update color based on level
            if (_runOptionValue) {
              selectedColors[student.regNo] = _getColorForLevel(student.level);
            } else {
              selectedColors[student.regNo] = _getColorForLevelWithoutRunOption(student.level);
            }

            // Update the original Student object in the list
            selectedStudents[index] = student;
            selectedStudent = student; // Update selectedStudent

            // Ensure dataStored flag is updated
            if (dataStored) {
              dataStored = false;
            }
          }
        }
      }
    });
  }

  Color _getColorForLevel(int level) {
    switch (level) {
      case 0:
        return const Color(0xffF1F1F1);
      case 1:
        return const Color(0xffA9A1FF);
      case 2:
        return const Color(0xffFFA36F);
      case 3:
        return const Color(0xff434343);
      case 4:
        return const Color(0xffFF7D7D);
      case 5:
        return const Color(0xffFF8E4F);
      case 6:
        return const Color(0xff33D09D);
      default:
        return const Color(0xffF1F1F1); // Default color for unknown levels
    }
  }

  Color _getColorForLevelWithoutRunOption(int level) {
    switch (level) {
      case 0:
        return const Color(0xffF1F1F1);
      case 1:
        return const Color(0xffA9A1FF);
      case 2:
        return const Color(0xffFFA36F);
      case 3:
        return const Color(0xff434343);
      case 4:
        return const Color(0xffFF7D7D);
      default:
        return const Color(0xffF1F1F1); // Default color for unknown levels
    }
  }

  @override
  void dispose() {
    super.dispose();
    // Reset the levels and colors
    final students = _getSelectedClassStudents();
    if (students != null) {
      for (var student in students) {
        student.level = 0;
      }
    }
    selectedColors.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('1.6/2.4Km Run')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (selectedClass == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('1.6/2.4Km Run')),
        body: const Center(child: Text('No data available.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('1.6/2.4Km Run'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row for Class Selection and Filters
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Half - Class Selection
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Class",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
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
                                        _selectedRegNo = null;
                                        selectedStudent = null;
                                      });
                                    },
                                    items: classes
                                        .map<DropdownMenuItem<String>>(
                                            (Class classItem) {
                                      return DropdownMenuItem<String>(
                                        value: classItem.className,
                                        child: Text(
                                          classItem.className,
                                          style:
                                              const TextStyle(fontSize: 14.0),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 20.0,
                  ),
                  // Right Half - Filters
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filter Switch
                        Row(
                          children: [
                            const Text(
                              "Filter",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                              ),
                            ),
                            const SizedBox(width: 15.0),
                            Transform.scale(
                              scale: 0.8,
                              child: CupertinoSwitch(
                                value: _filterValue,
                                onChanged: (bool value) {
                                  setState(() {
                                    if (_filterValue) {
                                      _runOptionValue = false;
                                    }
                                    _filterValue = value;
                                    _selectedRegNo = null;
                                    selectedStudent = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        // km Run Switch
                        if (_filterValue) ...[
                          Row(
                            children: [
                              const Text(
                                "1.6 km",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                              ),
                              const SizedBox(width: 5.0),
                              Transform.scale(
                                scale: 0.8,
                                child: CupertinoSwitch(
                                  value: _runOptionValue,
                                  onChanged: (bool value) {
                                    setState(() {
                                      _runOptionValue = value;
                                      _selectedRegNo = null;
                                      selectedStudent = null;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 5.0),
                              const Text(
                                "2.4 km",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20.0),

              // Reg No.'s
              const Text(
                "Reg No.",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: GridView.builder(
                  itemCount: _getSelectedClassStudents()?.length ?? 0,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 9,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (context, index) {
                    final students = _getSelectedClassStudents()!;
                    final student = students[index];
                    Color boxColor = selectedColors[student.regNo] ??
                        const Color(0xffF1F1F1);

                    return GestureDetector(
                      onTap: () => _handleStudentSelection(student),
                      child: Container(
                        decoration: BoxDecoration(
                          color: boxColor,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: _selectedRegNo == student.regNo
                                ? const Color(0xff00C485)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${student.regNo}',
                            style: TextStyle(
                              color: boxColor == const Color(0xffF1F1F1)
                                  ? Colors.black
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Buttons
              Row(
                children: [
                  _buildLevelButton('L-1', colors[0], () {
                    // Action for L-1 button
                  }),
                  const SizedBox(width: 2.0),
                  _buildLevelButton('L-2', colors[1], () {
                    // Action for L-2 button
                  }),
                  const SizedBox(width: 2.0),
                  _buildLevelButton('L-3', colors[2], () {
                    // Action for L-3 button
                  }),
                  const SizedBox(width: 2.0),
                  _buildLevelButton('L-4', colors[3], () {
                    // Action for L-4 button
                  }),
                  if (_runOptionValue) ...{
                    const SizedBox(width: 2.0),
                    _buildLevelButton('L-5', colors[6], () {
                      // Action for L-3 button
                    }),
                    const SizedBox(width: 2.0),
                    _buildLevelButton('L-6', colors[7], () {
                      // Action for L-4 button
                    }),
                  },
                  const SizedBox(width: 2.0),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffF1F1F1),
                      elevation: 0,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        '${selectedStudent?.regNo ?? '0'} / ${selectedStudent?.level ?? 0}',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),

                  // Undo Button
                  ElevatedButton(
                    onPressed: _handleUndo,
                    style: ElevatedButton.styleFrom(backgroundColor: colors[5]),
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
                      child: Text(
                        'Undo',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Timer
              _buildTimer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 0,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
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
                    '${duration.inHours.toString().padLeft(2, '0')}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
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
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00C485),
                  ),
                  onPressed: startTimer,
                  child: const Text(
                    'Start',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0A0A0A),
                  ),
                  onPressed: resetTimer,
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
