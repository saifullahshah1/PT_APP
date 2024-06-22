
class CsvData {
  final int no;
  final String name;
  final int id;
  final String classVal;
  final String gender;
  final String dob;
  final String attendanceStatus;
  final int sitUpReps;
  final int broadJumpCm;
  final int sitAndReachCm;
  final int pullUpReps;
  final double shuttleRunSec;
  final int runTime;
  final String pftTestDate;

  CsvData({
    required this.no,
    required this.name,
    required this.id,
    required this.classVal,
    required this.gender,
    required this.dob,
    required this.attendanceStatus,
    required this.sitUpReps,
    required this.broadJumpCm,
    required this.sitAndReachCm,
    required this.pullUpReps,
    required this.shuttleRunSec,
    required this.runTime,
    required this.pftTestDate,
  });

  factory CsvData.fromList(List<dynamic> row) {
    return CsvData(
      no: _parseInt(row[0]),
      name: row[1].toString(),
      id:  _parseInt(row[2]),
      classVal: row[3].toString(),
      gender: row[4].toString(),
      dob: row[5].toString(),
      attendanceStatus: row[6].toString(),
      sitUpReps: _parseInt(row[7]),
      broadJumpCm: _parseInt(row[8]),
      sitAndReachCm: _parseInt(row[9]),
      pullUpReps: _parseInt(row[10]),
      shuttleRunSec: _parseDouble(row[11]),
      runTime: _parseInt(row[12]),
      pftTestDate: row[13].toString(),
    );
  }

  factory CsvData.fromList2(Map<String, dynamic> json) {
    return CsvData(
      no: int.parse(json['no'] ?? '0'),
      name: json['name'] ?? '',
      id: int.parse(json['id'] ?? '0'),
      classVal: json['class'] ?? '',
      gender: json['gender'] ?? '',
      dob: json['dob'] ?? '',
      attendanceStatus: json['attendanceStatus'] ?? '',
      sitUpReps: json['sitUpReps'] ?? 0,
      broadJumpCm: json['broadJumpCm'] ?? 0,
      sitAndReachCm: json['sitAndReachCm'] ?? 0,
      pullUpReps: json['pullUpReps'] ?? 0,
      shuttleRunSec: (json['shuttleRunSec'] ?? 0).toDouble(), // Ensure it's double
      runTime: json['runTime'] ?? 0,
      pftTestDate: json['pftTestDate'] ?? '',
    );
  }


  static int _parseInt(dynamic value) {
    try {
      return int.parse(value.toString());
    } catch (e) {
      return -1; // or handle the error as needed
    }
  }

  static double _parseDouble(dynamic value) {
    try {
      return double.parse(value.toString());
    } catch (e) {
      return -1; // or handle the error as needed
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'no': no,
      'name': name,
      'id': id,
      'class': classVal,
      'gender': gender,
      'dob': dob,
      'attendanceStatus': attendanceStatus,
      'sitUpReps': sitUpReps,
      'broadJumpCm': broadJumpCm,
      'sitAndReachCm': sitAndReachCm,
      'pullUpReps': pullUpReps,
      'shuttleRunSec': shuttleRunSec,
      'runTime': runTime,
      'pftTestDate': pftTestDate,
    };
  }
}
