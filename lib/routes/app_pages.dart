import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../views/shared/splash_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/sign_up_view.dart';
import '../views/auth/forgot_password_view.dart';
import '../views/admin/admin_dashboard_view.dart';
import '../views/gate/gate_dashboard_view.dart';
import '../views/registration/registration_dashboard_view.dart';
import '../views/doctor/doctor_dashboard_view.dart';

// Phase 2 Views
import '../views/patient/patient_login_view.dart';
import '../views/patient/patient_sign_up_view.dart';
import '../views/patient/patient_dashboard_view.dart';
import '../views/diagnostic/diagnostic_dashboard_view.dart';
import '../views/billing/billing_dashboard_view.dart';
import '../views/pharmacy/pharmacy_dashboard_view.dart';
import '../views/admission/admission_dashboard_view.dart';
import '../views/display/digital_queue_display_view.dart';

import '../controllers/auth_controller.dart';
import '../controllers/gate_controller.dart';
import '../controllers/registration_controller.dart';
import '../controllers/doctor_controller.dart';
import '../controllers/admin_controller.dart';
import '../controllers/patient_controller.dart';
import '../controllers/visit_controller.dart';

// Phase 2 Controllers
import '../controllers/diagnostic_controller.dart';
import '../controllers/billing_controller.dart';
import '../controllers/pharmacy_controller.dart';
import '../controllers/admission_controller.dart';
import '../controllers/digital_queue_display_controller.dart';

import '../repositories/auth_repository.dart';
import '../repositories/patient_repository.dart';
import '../repositories/visit_repository.dart';
import '../repositories/queue_repository.dart';
import '../repositories/department_repository.dart';

// Phase 2 Repositories
import '../repositories/consultation_repository.dart';
import '../repositories/diagnostic_repository.dart';
import '../repositories/billing_repository.dart';
import '../repositories/pharmacy_repository.dart';
import '../repositories/admission_repository.dart';
import '../repositories/discharge_repository.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/notification_repository.dart';

import '../services/auth/auth_service.dart';
import '../services/firestore/firestore_service.dart';
import '../services/firestore/user_firestore_service.dart';
import '../services/firestore/patient_firestore_service.dart';
import '../services/firestore/visit_firestore_service.dart';
import '../services/firestore/queue_firestore_service.dart';
import '../services/firestore/department_firestore_service.dart';
import '../services/firestore/seed_service.dart';

// Phase 2 Services
import '../services/firestore/consultation_firestore_service.dart';
import '../services/firestore/diagnostic_firestore_service.dart';
import '../services/firestore/billing_firestore_service.dart';
import '../services/firestore/pharmacy_firestore_service.dart';
import '../services/firestore/admission_firestore_service.dart';
import '../services/firestore/discharge_firestore_service.dart';
import '../services/firestore/appointment_firestore_service.dart';
import '../services/firestore/notification_firestore_service.dart';
import '../services/workflow/workflow_engine_service.dart';

// Phase 3 Repositories & Services
import '../repositories/audit_repository.dart';
import '../repositories/staff_schedule_repository.dart';
import '../repositories/system_settings_repository.dart';
import '../services/firestore/audit_firestore_service.dart';
import '../services/firestore/staff_schedule_firestore_service.dart';
import '../services/firestore/system_settings_firestore_service.dart';
import '../services/analytics/analytics_service.dart';
import '../services/audio/audio_announcement_service.dart';
import '../services/appointment/appointment_reminder_service.dart';
import '../services/reports/report_export_service.dart';

import '../core/constants/route_constants.dart';

class AppPages {
  AppPages._();

  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: GlobalBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: GlobalBinding(),
    ),
    GetPage(
      name: AppRoutes.signUp,
      page: () => const SignUpView(),
      binding: GlobalBinding(),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
      binding: GlobalBinding(),
    ),
    GetPage(
      name: AppRoutes.adminDashboard,
      page: () => const AdminDashboardView(),
      binding: _AdminBinding(),
      middlewares: [_RoleMiddleware('admin')],
    ),
    GetPage(
      name: AppRoutes.gateDashboard,
      page: () => const GateDashboardView(),
      binding: _GateBinding(),
      middlewares: [_RoleMiddleware('gate')],
    ),
    GetPage(
      name: AppRoutes.registrationDashboard,
      page: () => const RegistrationDashboardView(),
      binding: _RegistrationBinding(),
      middlewares: [_RoleMiddleware('registration')],
    ),
    GetPage(
      name: AppRoutes.doctorDashboard,
      page: () => const DoctorDashboardView(),
      binding: _DoctorBinding(),
      middlewares: [_RoleMiddleware('doctor')],
    ),

    // ── Phase 2 Routes ──────────────────────────────────────────
    GetPage(
      name: AppRoutes.patientLogin,
      page: () => const PatientLoginView(),
      binding: GlobalBinding(),
    ),
    GetPage(
      name: AppRoutes.patientSignUp,
      page: () => const PatientSignUpView(),
      binding: GlobalBinding(),
    ),
    GetPage(
      name: AppRoutes.patientDashboard,
      page: () => const PatientDashboardView(),
      binding: GlobalBinding(),
      middlewares: [_RoleMiddleware('patient')],
    ),
    GetPage(
      name: AppRoutes.diagnosticDashboard,
      page: () => const DiagnosticDashboardView(),
      binding: _DiagnosticBinding(),
      middlewares: [_RoleMiddleware('diagnostic')],
    ),
    GetPage(
      name: AppRoutes.accountDashboard,
      page: () => const BillingDashboardView(),
      binding: _BillingBinding(),
      middlewares: [_RoleMiddleware('account')],
    ),
    GetPage(
      name: AppRoutes.pharmacyDashboard,
      page: () => const PharmacyDashboardView(),
      binding: _PharmacyBinding(),
      middlewares: [_RoleMiddleware('pharmacy')],
    ),
    GetPage(
      name: AppRoutes.admissionDashboard,
      page: () => const AdmissionDashboardView(),
      binding: _AdmissionBinding(),
      middlewares: [_RoleMiddleware('admission')],
    ),
    GetPage(
      name: AppRoutes.digitalQueueDisplay,
      page: () => const DigitalQueueDisplayView(),
      binding: _DisplayBinding(),
    ),
  ];
}

// ── Global Binding (services, repositories & auth controller) ────────────────────────────

class GlobalBinding extends Bindings {
  @override
  void dependencies() {
    // Phase 1 Core Services
    Get.lazyPut<FirestoreService>(
        () => FirestoreService(FirebaseFirestore.instance), fenix: true);
    Get.lazyPut<AuthService>(
        () => AuthService(FirebaseAuth.instance), fenix: true);
    Get.lazyPut<UserFirestoreService>(
        () => UserFirestoreService(Get.find()), fenix: true);
    Get.lazyPut<PatientFirestoreService>(
        () => PatientFirestoreService(Get.find()), fenix: true);
    Get.lazyPut<PatientFirestoreService?>(
        () => Get.find<PatientFirestoreService>(), fenix: true);
    Get.lazyPut<VisitFirestoreService>(
        () => VisitFirestoreService(Get.find()), fenix: true);
    Get.lazyPut<QueueFirestoreService>(
        () => QueueFirestoreService(Get.find()), fenix: true);
    Get.lazyPut<DepartmentFirestoreService>(
        () => DepartmentFirestoreService(Get.find()), fenix: true);

    // Phase 2 Firestore Services
    Get.lazyPut<ConsultationFirestoreService>(
        () => ConsultationFirestoreService(Get.find()), fenix: true);
    Get.lazyPut<DiagnosticFirestoreService>(
        () => DiagnosticFirestoreService(Get.find()), fenix: true);
    Get.lazyPut<BillingFirestoreService>(
        () => BillingFirestoreService(Get.find()), fenix: true);
    Get.lazyPut<PharmacyFirestoreService>(
        () => PharmacyFirestoreService(Get.find()), fenix: true);
    Get.lazyPut<AdmissionFirestoreService>(
        () => AdmissionFirestoreService(Get.find()), fenix: true);
    Get.lazyPut<DischargeFirestoreService>(
        () => DischargeFirestoreService(Get.find()), fenix: true);
    Get.lazyPut<AppointmentFirestoreService>(
        () => AppointmentFirestoreService(Get.find()), fenix: true);
    Get.lazyPut<NotificationFirestoreService>(
        () => NotificationFirestoreService(Get.find()), fenix: true);
    Get.lazyPut<WorkflowEngineService>(
        () => WorkflowEngineService(), fenix: true);

    // Phase 3 Services & Engines
    Get.lazyPut<AuditFirestoreService>(
        () => AuditFirestoreService(Get.find()), fenix: true);
    Get.lazyPut<StaffScheduleFirestoreService>(
        () => StaffScheduleFirestoreService(Get.find()), fenix: true);
    Get.lazyPut<SystemSettingsFirestoreService>(
        () => SystemSettingsFirestoreService(Get.find()), fenix: true);
    Get.lazyPut<AnalyticsService>(
        () => AnalyticsService(), fenix: true);
    Get.lazyPut<AudioAnnouncementService>(
        () => AudioAnnouncementService(), fenix: true);
    Get.lazyPut<AppointmentReminderService>(
        () => AppointmentReminderService(FirebaseFirestore.instance, Get.find()), fenix: true);
    Get.lazyPut<ReportExportService>(
        () => ReportExportService(), fenix: true);

    // Repositories
    Get.lazyPut<AuthRepository>(
        () => AuthRepository(
              Get.find<AuthService>(),
              Get.find<UserFirestoreService>(),
              Get.find<PatientFirestoreService>(),
            ),
        fenix: true);
    Get.lazyPut<PatientRepository>(
        () => PatientRepository(Get.find()), fenix: true);
    Get.lazyPut<VisitRepository>(
        () => VisitRepository(Get.find(), Get.find()), fenix: true);
    Get.lazyPut<QueueRepository>(
        () => QueueRepository(Get.find()), fenix: true);
    Get.lazyPut<DepartmentRepository>(
        () => DepartmentRepository(Get.find()), fenix: true);
    Get.lazyPut<SeedService>(
        () => SeedService(Get.find(), Get.find()), fenix: true);

    // Phase 2 Repositories
    Get.lazyPut<ConsultationRepository>(
        () => ConsultationRepository(Get.find()), fenix: true);
    Get.lazyPut<DiagnosticRepository>(
        () => DiagnosticRepository(Get.find()), fenix: true);
    Get.lazyPut<BillingRepository>(
        () => BillingRepository(Get.find()), fenix: true);
    Get.lazyPut<PharmacyRepository>(
        () => PharmacyRepository(Get.find()), fenix: true);
    Get.lazyPut<AdmissionRepository>(
        () => AdmissionRepository(Get.find()), fenix: true);
    Get.lazyPut<DischargeRepository>(
        () => DischargeRepository(Get.find()), fenix: true);
    Get.lazyPut<AppointmentRepository>(
        () => AppointmentRepository(Get.find()), fenix: true);
    Get.lazyPut<NotificationRepository>(
        () => NotificationRepository(Get.find()), fenix: true);

    // Phase 3 Repositories
    Get.lazyPut<AuditRepository>(
        () => AuditRepository(Get.find()), fenix: true);
    Get.lazyPut<StaffScheduleRepository>(
        () => StaffScheduleRepository(Get.find()), fenix: true);
    Get.lazyPut<SystemSettingsRepository>(
        () => SystemSettingsRepository(Get.find()), fenix: true);

    // Nullable repository aliases for safe GetX optional dependency resolution
    Get.lazyPut<ConsultationRepository?>(
        () => Get.find<ConsultationRepository>(), fenix: true);
    Get.lazyPut<DiagnosticRepository?>(
        () => Get.find<DiagnosticRepository>(), fenix: true);
    Get.lazyPut<PharmacyRepository?>(
        () => Get.find<PharmacyRepository>(), fenix: true);
    Get.lazyPut<AdmissionRepository?>(
        () => Get.find<AdmissionRepository>(), fenix: true);
    Get.lazyPut<BillingRepository?>(
        () => Get.find<BillingRepository>(), fenix: true);
    Get.lazyPut<NotificationRepository?>(
        () => Get.find<NotificationRepository>(), fenix: true);

    // Auth controller — permanent
    Get.put<AuthController>(
        AuthController(Get.find()), permanent: true);
  }
}

// ── Role Bindings ──────────────────────────────────────────────────────────

class _AdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminController>(
        () => AdminController(
              FirebaseFirestore.instance,
              authRepo: Get.find<AuthRepository>(),
              auditRepo: Get.find<AuditRepository>(),
              scheduleRepo: Get.find<StaffScheduleRepository>(),
              settingsRepo: Get.find<SystemSettingsRepository>(),
              analyticsService: Get.find<AnalyticsService>(),
              reportService: Get.find<ReportExportService>(),
            ));
    Get.lazyPut<PatientController>(
        () => PatientController(Get.find()));
  }
}

class _GateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GateController>(
        () => GateController(Get.find(), Get.find(), Get.find()));
    Get.lazyPut<PatientController>(
        () => PatientController(Get.find()));
    Get.lazyPut<VisitController>(
        () => VisitController(Get.find()));
  }
}

class _RegistrationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegistrationController>(() => RegistrationController(
        Get.find(), Get.find(), Get.find(), Get.find()));
    Get.lazyPut<PatientController>(() => PatientController(Get.find()));
  }
}

class _DoctorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DoctorController>(
        () => DoctorController(
              Get.find<PatientRepository>(),
              Get.find<QueueRepository>(),
              Get.find<VisitRepository>(),
              consultationRepo: Get.find<ConsultationRepository>(),
              diagnosticRepo: Get.find<DiagnosticRepository>(),
              pharmacyRepo: Get.find<PharmacyRepository>(),
              admissionRepo: Get.find<AdmissionRepository>(),
              billingRepo: Get.find<BillingRepository>(),
              notificationRepo: Get.find<NotificationRepository>(),
              appointmentRepo: Get.find<AppointmentRepository>(),
            ));
  }
}

class _DiagnosticBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DiagnosticController>(
        () => DiagnosticController(Get.find(), Get.find(), notificationRepo: Get.find()));
  }
}

class _BillingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BillingController>(
        () => BillingController(Get.find(), Get.find(), notificationRepo: Get.find()));
  }
}

class _PharmacyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PharmacyController>(
        () => PharmacyController(Get.find(), Get.find(), notificationRepo: Get.find()));
  }
}

class _AdmissionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdmissionController>(
        () => AdmissionController(Get.find(), Get.find(), notificationRepo: Get.find()));
  }
}

class _DisplayBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DigitalQueueDisplayController>(
        () => DigitalQueueDisplayController(
              Get.find(),
              Get.find<AudioAnnouncementService>(),
            ));
  }
}

// ── Role Middleware ────────────────────────────────────────────────────────

class _RoleMiddleware extends GetMiddleware {
  _RoleMiddleware(this.requiredRole);
  final String requiredRole;

  @override
  GetPage? onPageCalled(GetPage? page) {
    final auth = Get.find<AuthController>();
    if (!auth.isSignedIn.value) {
      final target = requiredRole == 'patient' ? AppRoutes.patientLogin : AppRoutes.login;
      Future.microtask(() => Get.offAllNamed(target));
      return page;
    }
    final user = auth.user;
    if (user == null) {
      final target = requiredRole == 'patient' ? AppRoutes.patientLogin : AppRoutes.login;
      Future.microtask(() => Get.offAllNamed(target));
      return page;
    }

    // Block inactive / pending-approval staff accounts from any dashboard
    if (!user.active) {
      Future.microtask(() => Get.offAllNamed(AppRoutes.login));
      return page;
    }

    bool allowed = false;
    switch (requiredRole) {
      case 'admin':
        allowed = user.isAdmin;
        break;
      case 'gate':
        allowed = user.isAdmin || user.isGateOfficer;
        break;
      case 'registration':
        allowed = user.isAdmin || user.isRegistrationOfficer;
        break;
      case 'doctor':
        allowed = user.isAdmin || user.isDoctor;
        break;
      case 'patient':
        allowed = user.isPatient;
        break;
      case 'diagnostic':
        allowed = user.isAdmin || user.isDiagnosticStaff;
        break;
      case 'account':
        allowed = user.isAdmin || user.isAccountOfficer;
        break;
      case 'pharmacy':
        allowed = user.isAdmin || user.isPharmacist;
        break;
      case 'admission':
        allowed = user.isAdmin || user.isAdmissionOfficer;
        break;
    }
    if (!allowed) {
      final fallback = user.isPatient ? AppRoutes.patientDashboard : AppRoutes.login;
      Future.microtask(() => Get.offAllNamed(fallback));
    }
    return page;
  }
}
