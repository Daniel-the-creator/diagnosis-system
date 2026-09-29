import 'dart:math';
import 'package:intl/intl.dart';

/// Generates unique hospital (medical record) numbers.
/// Format: HN-YYYY-XXXXXX (e.g. HN-2026-000001)
class HospitalNumberGenerator {
  HospitalNumberGenerator._();

  static final Random _random = Random.secure();

  /// Generates a candidate hospital number.
  /// Uniqueness must be verified by the calling repository against Firestore.
  static String generate() {
    final year = DateTime.now().year;
    final seq = _random.nextInt(900000) + 100000; // 100000–999999
    return 'HN-$year-$seq';
  }

  /// Formats a sequential number with zero-padding.
  static String formatSequential(int seq) {
    final year = DateTime.now().year;
    final padded = seq.toString().padLeft(6, '0');
    return 'HN-$year-$padded';
  }

  /// Returns today's date string for counter documents.
  static String todayKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }
}
