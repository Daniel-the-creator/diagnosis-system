import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// General application utilities.
class AppUtils {
  AppUtils._();

  /// Shows a styled SnackBar.
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red.shade700
            : isSuccess
                ? Colors.green.shade700
                : null,
        duration: duration,
      ),
    );
  }

  /// Returns initials from a full name.
  static String getInitials(String fullName) {
    if (fullName.isEmpty) return '?';
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Returns a human-readable role label.
  static String getRoleLabel(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'hospital_admin':
        return 'Hospital Administrator';
      case 'gate_officer':
        return 'Gate Officer';
      case 'registration_officer':
        return 'Registration Officer';
      case 'doctor':
        return 'Doctor / Consultant';
      default:
        return role;
    }
  }

  /// Returns a human-readable patient type label.
  static String getPatientTypeLabel(String type) {
    switch (type) {
      case 'EMERGENCY':
        return 'Emergency';
      case 'REGULAR':
        return 'Regular';
      default:
        return type;
    }
  }

  /// Formats a Firestore Timestamp or DateTime to a display string.
  static String formatDateTime(DateTime? dt, {String format = 'dd MMM yyyy, HH:mm'}) {
    if (dt == null) return '—';
    return DateFormat(format).format(dt);
  }

  static String formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  static String formatTime(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('HH:mm').format(dt);
  }

  static String formatAge(DateTime? dob) {
    if (dob == null) return '—';
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return '$age yrs';
  }

  /// Returns time elapsed since a given DateTime.
  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Returns waiting time as formatted string.
  static String waitingTime(DateTime? createdAt) {
    if (createdAt == null) return '—';
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min';
    }
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return '${h}h ${m}m';
  }

  /// Validates email format.
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  /// Validates phone number (basic).
  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[0-9]{7,15}$').hasMatch(phone.replaceAll(' ', ''));
  }

  /// Capitalises first letter of each word.
  static String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
    }).join(' ');
  }
}
