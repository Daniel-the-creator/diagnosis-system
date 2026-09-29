import 'package:flutter_test/flutter_test.dart';
import 'package:diagnosis_system/core/constants/route_constants.dart';
import 'package:diagnosis_system/views/admin/admin_dashboard_view.dart';
import 'package:diagnosis_system/views/doctor/doctor_dashboard_view.dart';
import 'package:diagnosis_system/views/gate/gate_dashboard_view.dart';
import 'package:diagnosis_system/views/registration/registration_dashboard_view.dart';

void main() {
  group('Dashboard Navigation Consistency Tests', () {
    test('AdminDashboardView sidebarItems contains all 8 operational sections', () {
      final items = AdminDashboardView.sidebarItems;
      expect(items.length, equals(8));
      expect(items[0].route, equals(AppRoutes.adminDashboard));
      expect(items[1].route, equals(AppRoutes.gateDashboard));
      expect(items[2].route, equals(AppRoutes.registrationDashboard));
      expect(items[3].route, equals(AppRoutes.doctorDashboard));
    });

    test('DoctorDashboardView admin sidebar contains all 8 Phase 2 operational sections', () {
      final adminSidebar = DoctorDashboardView.adminSidebar;
      expect(adminSidebar.length, equals(8));
      expect(adminSidebar[0].route, equals(AppRoutes.adminDashboard));
      expect(adminSidebar[1].route, equals(AppRoutes.gateDashboard));
      expect(adminSidebar[2].route, equals(AppRoutes.registrationDashboard));
      expect(adminSidebar[3].route, equals(AppRoutes.doctorDashboard));
      expect(adminSidebar[3].label, equals('Consultation Queue'));
      expect(adminSidebar[4].route, equals(AppRoutes.diagnosticDashboard));
      expect(adminSidebar[5].route, equals(AppRoutes.accountDashboard));
      expect(adminSidebar[6].route, equals(AppRoutes.pharmacyDashboard));
      expect(adminSidebar[7].route, equals(AppRoutes.admissionDashboard));
    });

    test('DoctorDashboardView staff sidebar contains only consultation queue', () {
      final staffSidebar = DoctorDashboardView.staffSidebar;
      expect(staffSidebar.length, equals(1));
      expect(staffSidebar[0].route, equals(AppRoutes.doctorDashboard));
      expect(staffSidebar[0].label, equals('Consultation Queue'));
    });

    test('GateDashboardView admin sidebar matches expected routes and labels', () {
      final adminSidebar = GateDashboardView.adminSidebar;
      expect(adminSidebar.length, equals(4));
      expect(adminSidebar.map((i) => i.route).toList(), [
        AppRoutes.adminDashboard,
        AppRoutes.gateDashboard,
        AppRoutes.registrationDashboard,
        AppRoutes.doctorDashboard,
      ]);
      expect(adminSidebar[3].label, equals('Consultation Queue'));
    });

    test('RegistrationDashboardView admin sidebar matches expected routes and labels', () {
      final adminSidebar = RegistrationDashboardView.adminSidebar;
      expect(adminSidebar.length, equals(4));
      expect(adminSidebar.map((i) => i.route).toList(), [
        AppRoutes.adminDashboard,
        AppRoutes.gateDashboard,
        AppRoutes.registrationDashboard,
        AppRoutes.doctorDashboard,
      ]);
      expect(adminSidebar[3].label, equals('Consultation Queue'));
    });
  });
}
