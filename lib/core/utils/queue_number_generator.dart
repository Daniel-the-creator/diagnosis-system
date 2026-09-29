import 'package:intl/intl.dart';

/// Queue number prefix map — maps department code to display prefix.
const Map<String, String> _prefixMap = {
  'GATE': 'GATE',
  'REG': 'REG',
  'GEN': 'DOC',
  'PED': 'DOC',
  'SUR': 'DOC',
  'LAB': 'LAB',
  'XR': 'XR',
  'SCAN': 'SCAN',
  'ACC': 'ACC',
  'PHM': 'PHM',
  'ADM': 'ADM',
  'DIS': 'DIS',
  'DOC': 'DOC',
};

/// Generates queue number strings and counter document IDs.
class QueueNumberGenerator {
  QueueNumberGenerator._();

  /// Returns the queue prefix for a given department code.
  static String getPrefix(String departmentCode) {
    return _prefixMap[departmentCode.toUpperCase()] ?? departmentCode.toUpperCase();
  }

  /// Formats a counter integer into a queue number string.
  /// e.g. prefix='REG', counter=3 → 'REG-003'
  static String format(String prefix, int counter) {
    return '$prefix-${counter.toString().padLeft(3, '0')}';
  }

  /// Returns the Firestore document ID for a queue counter.
  /// e.g. 'REG_2026-09-14'
  static String counterId(String departmentCode) {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final prefix = getPrefix(departmentCode);
    return '${prefix}_$date';
  }

  /// Returns today's date string.
  static String todayDate() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }
}
