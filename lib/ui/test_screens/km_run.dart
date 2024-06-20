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
  ];

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

  bool dataStored = false;

  List<Student>? _getSelectedClassStudents() {
    return classes
        .firstWhereOrNull((cls) => cls.className == selectedClass)
        ?.students;
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

  bool _checkAllStudentsOnLap4() {
    final students = _getSelectedClassStudents();
    if (students == null) return false;
    for (var student in students) {
      if (student.level < 4) {
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
    if (student.level == 4) {
      setState(() {
        _selectedRegNo = student.regNo;
        selectedStudent = student;
      });
      return;
    }

    setState(() {
      _selectedRegNo = student.regNo;
      selectedColors.putIfAbsent(student.regNo, () => const Color(0xffF1F1F1));

      // Increment lap level only if it's less than 4
      if (student.level < 4 && student.level >= 0) {
        student = student.copyWith(level: student.level + 1);

        // Update color based on the new level
        switch (student.level) {
          case 0:
            selectedColors[student.regNo] = const Color(0xffF1F1F1);
            break;
          case 1:
            selectedColors[student.regNo] = const Color(0xffA9A1FF);
            break;
          case 2:
            selectedColors[student.regNo] = const Color(0xffFFA36F);
            break;
          case 3:
            selectedColors[student.regNo] = const Color(0xff434343);
            break;
          case 4:
            selectedColors[student.regNo] = const Color(0xffFF7D7D);
            break;
        }
      }

      // Update the selectedStudent after changing the level
      selectedStudent = student.copyWith(
          runTime: student.level == 4 ? duration.inSeconds : student.runTime);
      // Update the student in the list
      final selectedStudents = _getSelectedClassStudents()!;
      final index =
          selectedStudents.indexWhere((s) => s.regNo == student.regNo);
      if (index != -1) {
        selectedStudents[index] = selectedStudent!;
      }

      if (_checkAllStudentsOnLap4() && !dataStored) {
        dataStored = true;
        _storeDataInDb(_getSelectedClassStudents()!);
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

          // Undo operation: decrement level and update color
          if (student.level > 0) {
            student = student.copyWith(level: student.level - 1);
            switch (student.level) {
              case 0:
                selectedColors[student.regNo] = const Color(0xffF1F1F1);
                break;
              case 1:
                selectedColors[student.regNo] = const Color(0xffA9A1FF);
                break;
              case 2:
                selectedColors[student.regNo] = const Color(0xffFFA36F);
                break;
              case 3:
                selectedColors[student.regNo] = const Color(0xff434343);
                break;
            }
          }

          // Update the selected student and store in list
          selectedStudents[index] = student;
          selectedStudent = student; // Update selectedStudent

          // Reset dataStored flag if needed
          if (dataStored) {
            dataStored = false;
          }
        }
      }
    });
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
                    width: 10.0,
                  ),
                  // Right Half - Filters
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Filters",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        // Add your filter widgets here as needed
                        // Example filter widget:
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            // Implement filter logic
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20.0),

              // Rest of the Widgets Below Class Selection and Filters
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
                height: 500,
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
                            '${student.no}',
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
                        '${selectedStudent?.no ?? '0'} / ${selectedStudent?.level ?? 0}',
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
