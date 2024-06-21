import 'package:intl/intl.dart';

extension ListExtensions<E> on List<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

DateTime getCurrentDateTime() {
  final now = DateTime.now().toUtc();
  final formatter = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'");
  print("Currrent Date Time: ${formatter.format(now)}");
  return now;
}

String getFormattedCurrentDateTime() {
  final now = DateTime.now().toUtc();
  final formatter = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'");
  return formatter.format(now);
}

