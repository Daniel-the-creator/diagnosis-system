import 'package:flutter_test/flutter_test.dart';
import 'package:diagnosis_system/core/utils/hospital_number_generator.dart';
import 'package:diagnosis_system/core/utils/queue_number_generator.dart';
import 'package:diagnosis_system/core/utils/app_utils.dart';
import 'package:diagnosis_system/models/queue_item_model.dart';
import 'package:diagnosis_system/models/patient_model.dart';

void main() {
  group('HospitalNumberGenerator Tests', () {
    test('generate() returns format HN-YYYY-XXXXXX', () {
      final hn = HospitalNumberGenerator.generate();
      final year = DateTime.now().year;
      expect(hn.startsWith('HN-$year-'), isTrue);
      expect(hn.length, equals(14)); // HN-YYYY-XXXXXX = 2+1+4+1+6 = 14
    });

    test('formatSequential() formats with correct padding', () {
      final year = DateTime.now().year;
      expect(HospitalNumberGenerator.formatSequential(1),
          equals('HN-$year-000001'));
      expect(HospitalNumberGenerator.formatSequential(42),
          equals('HN-$year-000042'));
      expect(HospitalNumberGenerator.formatSequential(123456),
          equals('HN-$year-123456'));
    });

    test('todayKey() returns YYYY-MM-DD', () {
      final key = HospitalNumberGenerator.todayKey();
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key), isTrue);
    });
  });

  group('QueueNumberGenerator Tests', () {
    test('getPrefix() maps department codes accurately', () {
      expect(QueueNumberGenerator.getPrefix('REG'), equals('REG'));
      expect(QueueNumberGenerator.getPrefix('GEN'), equals('DOC'));
      expect(QueueNumberGenerator.getPrefix('LAB'), equals('LAB'));
      expect(QueueNumberGenerator.getPrefix('XR'), equals('XR'));
      expect(QueueNumberGenerator.getPrefix('UNKNOWN'), equals('UNKNOWN'));
    });

    test('format() pads queue numbers to 3 digits', () {
      expect(QueueNumberGenerator.format('REG', 1), equals('REG-001'));
      expect(QueueNumberGenerator.format('DOC', 15), equals('DOC-015'));
      expect(QueueNumberGenerator.format('LAB', 100), equals('LAB-100'));
    });

    test('counterId() combines prefix and today date', () {
      final id = QueueNumberGenerator.counterId('REG');
      final today = QueueNumberGenerator.todayDate();
      expect(id, equals('REG_$today'));
    });
  });

  group('AppUtils Tests', () {
    test('getInitials() handles single and multi-word names', () {
      expect(AppUtils.getInitials('Tolu Adeoye'), equals('TA'));
      expect(AppUtils.getInitials('Ayomide'), equals('A'));
      expect(AppUtils.getInitials('Marvelous Olufemi'), equals('MO'));
      expect(AppUtils.getInitials(''), equals('?'));
    });

    test('isValidEmail() validates correctly', () {
      expect(AppUtils.isValidEmail('doctor@gmail.com'), isTrue);
      expect(AppUtils.isValidEmail('patient@gmail.com'), isTrue);
      expect(AppUtils.isValidEmail('invalid-email'), isFalse);
      expect(AppUtils.isValidEmail('test@'), isFalse);
      expect(AppUtils.isValidEmail('@test.com'), isFalse);
    });

    test('isValidPhone() validates phone strings', () {
      expect(AppUtils.isValidPhone('+1234567890'), isTrue);
      expect(AppUtils.isValidPhone('08012345678'), isTrue);
      expect(AppUtils.isValidPhone('123'), isFalse);
      expect(AppUtils.isValidPhone('abc'), isFalse);
    });

    test('toTitleCase() converts case appropriately', () {
      expect(AppUtils.toTitleCase('tolu adeoye'), equals('Tolu Adeoye'));
      expect(AppUtils.toTitleCase('CARDIOLOGY CLINIC'),
          equals('Cardiology Clinic'));
      expect(AppUtils.toTitleCase(''), equals(''));
    });

    test('formatAge() calculates age accurately', () {
      final now = DateTime.now();
      final thirtyYearsAgo = DateTime(now.year - 30, now.month, now.day);
      expect(AppUtils.formatAge(thirtyYearsAgo), equals('30 yrs'));
      expect(AppUtils.formatAge(null), equals('—'));
    });
  });

  group('QueueStatus Tests', () {
    test('fromString() and toStatusString() roundtrip', () {
      for (final status in QueueStatus.values) {
        final str = status.toStatusString();
        final parsed = QueueStatus.fromString(str);
        expect(parsed, equals(status));
      }
    });

    test('displayLabel is non-empty for all statuses', () {
      for (final status in QueueStatus.values) {
        expect(status.displayLabel.isNotEmpty, isTrue);
      }
    });
  });

  group('PatientModel Tests', () {
    test('displayAge returns expected age string or placeholder', () {
      final now = DateTime.now();
      final patient = PatientModel(
        patientId: 'P001',
        hospitalNumber: 'HN-2026-000001',
        fullName: 'Tolu Adeoye',
        gender: 'Female',
        phone: '+1234567890',
        dateOfBirth: DateTime(now.year - 25, now.month, now.day),
        createdAt: now,
        updatedAt: now,
      );
      expect(patient.displayAge, equals('25 yrs'));

      final patientNoDob = PatientModel(
        patientId: 'P002',
        hospitalNumber: 'HN-2026-000002',
        fullName: 'saliu adewoye',
        gender: 'Male',
        phone: '+1234567891',
        dateOfBirth: null,
        createdAt: now,
        updatedAt: now,
      );
      expect(patientNoDob.displayAge, equals('—'));
    });

    test('copyWith updates specified fields only', () {
      final now = DateTime.now();
      final patient = PatientModel(
        patientId: 'P001',
        hospitalNumber: 'HN-2026-000001',
        fullName: 'Marvelous Olufemi',
        gender: 'Female',
        phone: '+1234567890',
        createdAt: now,
        updatedAt: now,
      );

      final updated = patient.copyWith(
          fullName: 'Daniel Ilesanmi', phone: '+2349064090800');
      expect(updated.patientId, equals(patient.patientId));
      expect(updated.fullName, equals('Daniel Ilesanmi'));
      expect(updated.phone, equals('+2349064090800'));
      expect(updated.hospitalNumber, equals(patient.hospitalNumber));
    });
  });
}
