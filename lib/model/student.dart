import 'package:intl/intl.dart';
import '../data/csv_data.dart';

class Student {
  final int regNo;
  final String name;
  final int age;
  final String gender;
  // final String id;
  final String classVal;
  final String dob;
  final String attendanceStatus;
  final int sitUpReps;
  final int broadJumpCm;
  final int sitAndReachCm;
  final int pullUpReps;
  final double shuttleRunSec;
  final int runTime;
  int level;
  final String pftTestDate;

  Student({
    required this.regNo,
    required this.name,
    required this.age,
    required this.gender,
    // required this.id,
    required this.classVal,
    required this.dob,
    required this.attendanceStatus,
    required this.sitUpReps,
    required this.broadJumpCm,
    required this.sitAndReachCm,
    required this.pullUpReps,
    required this.shuttleRunSec,
    required this.runTime,
    required this.pftTestDate,
    this.level = 0,
  });


  // Factory method to create a Student from CsvData
  factory Student.fromCsvData(CsvData csvData) {

    int calculateAge(String dob) {
      DateTime birthDate = DateFormat('M/d/yyyy').parse(dob); // Update the date format here
      DateTime today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    }

    return Student(
      regNo: csvData.id,
      name: csvData.name,
      age: calculateAge(csvData.dob), // Implement this function as needed
      gender: csvData.gender,
      // id: csvData.id,
      classVal: csvData.classVal,
      dob: csvData.dob,
      attendanceStatus: csvData.attendanceStatus,
      sitUpReps: csvData.sitUpReps,
      broadJumpCm: csvData.broadJumpCm,
      sitAndReachCm: csvData.sitAndReachCm,
      pullUpReps: csvData.pullUpReps,
      shuttleRunSec: csvData.shuttleRunSec,
      runTime: csvData.runTime,
      pftTestDate: csvData.pftTestDate,
    );
  }

  // Method to create a copy of the Student with updated fields
  Student copyWith({
    int? regNo,
    String? name,
    int? age,
    String? gender,
    // String? id,
    String? classVal,
    String? dob,
    String? attendanceStatus,
    int? sitUpReps,
    int? broadJumpCm,
    int? sitAndReachCm,
    int? pullUpReps,
    double? shuttleRunSec,
    int? runTime,
    String? pftTestDate,
    int? level,
  }) {
    return Student(
      regNo: regNo ?? this.regNo,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      // id: id ?? this.id,
      classVal: classVal ?? this.classVal,
      dob: dob ?? this.dob,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      sitUpReps: sitUpReps ?? this.sitUpReps,
      broadJumpCm: broadJumpCm ?? this.broadJumpCm,
      sitAndReachCm: sitAndReachCm ?? this.sitAndReachCm,
      pullUpReps: pullUpReps ?? this.pullUpReps,
      shuttleRunSec: shuttleRunSec ?? this.shuttleRunSec,
      runTime: runTime ?? this.runTime,
      pftTestDate: pftTestDate ?? this.pftTestDate,
      level: level ?? this.level,
    );
  }
}