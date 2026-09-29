/// Named route constants used across the application.
class AppRoutes {
  AppRoutes._();

  // ── Auth (Staff) ───────────────────────────────────────────────
  static const String splash = '/';
  static const String login = '/login';
  static const String signUp = '/signup';
  static const String forgotPassword = '/forgot-password';

  // ── Role-Based Dashboards (Staff) ──────────────────────────────
  static const String adminDashboard = '/admin/dashboard';
  static const String gateDashboard = '/gate/dashboard';
  static const String registrationDashboard = '/registration/dashboard';
  static const String doctorDashboard = '/doctor/dashboard';

  // ── Phase 2 — Staff Dashboards ─────────────────────────────────
  static const String diagnosticDashboard = '/diagnostic/dashboard';
  static const String accountDashboard = '/account/dashboard';
  static const String pharmacyDashboard = '/pharmacy/dashboard';
  static const String admissionDashboard = '/admission/dashboard';
  static const String digitalQueueDisplay = '/display/queue';

  // ── Phase 2 — Patient Auth ─────────────────────────────────────
  static const String patientLogin = '/patient/login';
  static const String patientSignUp = '/patient/signup';
  static const String patientForgotPassword = '/patient/forgot-password';

  // ── Phase 2 — Patient Portal ───────────────────────────────────
  static const String patientDashboard = '/patient/dashboard';
  static const String patientAppointments = '/patient/appointments';
  static const String patientBills = '/patient/bills';
  static const String patientResults = '/patient/results';
  static const String patientPrescriptions = '/patient/prescriptions';
  static const String patientProfile = '/patient/profile';

  // ── Queue ──────────────────────────────────────────────────────
  static const String queueManagement = '/queue/management';

  // ── Patient (Staff-facing) ─────────────────────────────────────
  static const String patientRegister = '/patient/register';
  static const String patientSearch = '/patient/search';

  // ── Visit ──────────────────────────────────────────────────────
  static const String visitCreate = '/visit/create';
  static const String visitDetail = '/visit/detail';
}
