import 'package:cloud_firestore/cloud_firestore.dart';

/// System-wide configuration persisted in Firestore (collection: 'settings', doc: 'general').
class SystemSettingsModel {
  // Hospital identity
  final String hospitalName;
  final String hospitalTagline;
  final String? logoUrl;
  final String address;
  final String phone;
  final String email;
  final String website;

  // Queue settings
  final String queueNumberingFormat; // e.g. "{PREFIX}-{NUMBER}"
  final bool enableAudioAnnouncements;
  final String announcementVoiceLanguage; // e.g. "en-US"
  final double announcementSpeechRate; // 0.5 to 1.5 (default 0.9)
  final int displayRefreshIntervalSeconds;
  final bool displayShowDepartment;

  // Workflow / payment requirements
  final bool requirePaymentBeforeDiagnostics;
  final bool requirePaymentBeforePharmacy;
  final bool autoCallNextPatient;

  // Operating hours
  final String openingTime; // "08:00"
  final String closingTime; // "20:00"
  final bool emergencyOpen24h;

  // Notification settings
  final bool enableSmsReminders;
  final bool enableEmailNotifications;
  final bool send24hAppointmentReminder;
  final bool send1hAppointmentReminder;

  final DateTime updatedAt;

  const SystemSettingsModel({
    this.hospitalName = 'MediFlow General Hospital & Diagnostic Centre',
    this.hospitalTagline = 'Compassionate Care, Precision Diagnostics',
    this.logoUrl,
    this.address = '14 Healthcare Boulevard, Medical District',
    this.phone = '+1 (800) 555-CARE',
    this.email = 'info@mediflow-hms.com',
    this.website = 'https://mediflow-hms.org',
    this.queueNumberingFormat = '{PREFIX}-{000}',
    this.enableAudioAnnouncements = true,
    this.announcementVoiceLanguage = 'en-US',
    this.announcementSpeechRate = 0.9,
    this.displayRefreshIntervalSeconds = 5,
    this.displayShowDepartment = true,
    this.requirePaymentBeforeDiagnostics = true,
    this.requirePaymentBeforePharmacy = false,
    this.autoCallNextPatient = false,
    this.openingTime = '08:00',
    this.closingTime = '20:00',
    this.emergencyOpen24h = true,
    this.enableSmsReminders = true,
    this.enableEmailNotifications = true,
    this.send24hAppointmentReminder = true,
    this.send1hAppointmentReminder = true,
    required this.updatedAt,
  });

  factory SystemSettingsModel.defaultSettings() => SystemSettingsModel(
        updatedAt: DateTime.now(),
      );

  factory SystemSettingsModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) return SystemSettingsModel.defaultSettings();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SystemSettingsModel(
      hospitalName: data['hospitalName'] as String? ?? 'MediFlow General Hospital & Diagnostic Centre',
      hospitalTagline: data['hospitalTagline'] as String? ?? 'Compassionate Care, Precision Diagnostics',
      logoUrl: data['logoUrl'] as String?,
      address: data['address'] as String? ?? '14 Healthcare Boulevard, Medical District',
      phone: data['phone'] as String? ?? '+1 (800) 555-CARE',
      email: data['email'] as String? ?? 'info@mediflow-hms.com',
      website: data['website'] as String? ?? 'https://mediflow-hms.org',
      queueNumberingFormat: data['queueNumberingFormat'] as String? ?? '{PREFIX}-{000}',
      enableAudioAnnouncements: data['enableAudioAnnouncements'] as bool? ?? true,
      announcementVoiceLanguage: data['announcementVoiceLanguage'] as String? ?? 'en-US',
      announcementSpeechRate: (data['announcementSpeechRate'] as num?)?.toDouble() ?? 0.9,
      displayRefreshIntervalSeconds: (data['displayRefreshIntervalSeconds'] as num?)?.toInt() ?? 5,
      displayShowDepartment: data['displayShowDepartment'] as bool? ?? true,
      requirePaymentBeforeDiagnostics: data['requirePaymentBeforeDiagnostics'] as bool? ?? true,
      requirePaymentBeforePharmacy: data['requirePaymentBeforePharmacy'] as bool? ?? false,
      autoCallNextPatient: data['autoCallNextPatient'] as bool? ?? false,
      openingTime: data['openingTime'] as String? ?? '08:00',
      closingTime: data['closingTime'] as String? ?? '20:00',
      emergencyOpen24h: data['emergencyOpen24h'] as bool? ?? true,
      enableSmsReminders: data['enableSmsReminders'] as bool? ?? true,
      enableEmailNotifications: data['enableEmailNotifications'] as bool? ?? true,
      send24hAppointmentReminder: data['send24hAppointmentReminder'] as bool? ?? true,
      send1hAppointmentReminder: data['send1hAppointmentReminder'] as bool? ?? true,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'hospitalName': hospitalName,
        'hospitalTagline': hospitalTagline,
        'logoUrl': logoUrl,
        'address': address,
        'phone': phone,
        'email': email,
        'website': website,
        'queueNumberingFormat': queueNumberingFormat,
        'enableAudioAnnouncements': enableAudioAnnouncements,
        'announcementVoiceLanguage': announcementVoiceLanguage,
        'announcementSpeechRate': announcementSpeechRate,
        'displayRefreshIntervalSeconds': displayRefreshIntervalSeconds,
        'displayShowDepartment': displayShowDepartment,
        'requirePaymentBeforeDiagnostics': requirePaymentBeforeDiagnostics,
        'requirePaymentBeforePharmacy': requirePaymentBeforePharmacy,
        'autoCallNextPatient': autoCallNextPatient,
        'openingTime': openingTime,
        'closingTime': closingTime,
        'emergencyOpen24h': emergencyOpen24h,
        'enableSmsReminders': enableSmsReminders,
        'enableEmailNotifications': enableEmailNotifications,
        'send24hAppointmentReminder': send24hAppointmentReminder,
        'send1hAppointmentReminder': send1hAppointmentReminder,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  SystemSettingsModel copyWith({
    String? hospitalName,
    String? hospitalTagline,
    String? logoUrl,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? queueNumberingFormat,
    bool? enableAudioAnnouncements,
    String? announcementVoiceLanguage,
    double? announcementSpeechRate,
    int? displayRefreshIntervalSeconds,
    bool? displayShowDepartment,
    bool? requirePaymentBeforeDiagnostics,
    bool? requirePaymentBeforePharmacy,
    bool? autoCallNextPatient,
    String? openingTime,
    String? closingTime,
    bool? emergencyOpen24h,
    bool? enableSmsReminders,
    bool? enableEmailNotifications,
    bool? send24hAppointmentReminder,
    bool? send1hAppointmentReminder,
    DateTime? updatedAt,
  }) =>
      SystemSettingsModel(
        hospitalName: hospitalName ?? this.hospitalName,
        hospitalTagline: hospitalTagline ?? this.hospitalTagline,
        logoUrl: logoUrl ?? this.logoUrl,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        website: website ?? this.website,
        queueNumberingFormat: queueNumberingFormat ?? this.queueNumberingFormat,
        enableAudioAnnouncements:
            enableAudioAnnouncements ?? this.enableAudioAnnouncements,
        announcementVoiceLanguage:
            announcementVoiceLanguage ?? this.announcementVoiceLanguage,
        announcementSpeechRate:
            announcementSpeechRate ?? this.announcementSpeechRate,
        displayRefreshIntervalSeconds:
            displayRefreshIntervalSeconds ?? this.displayRefreshIntervalSeconds,
        displayShowDepartment:
            displayShowDepartment ?? this.displayShowDepartment,
        requirePaymentBeforeDiagnostics:
            requirePaymentBeforeDiagnostics ?? this.requirePaymentBeforeDiagnostics,
        requirePaymentBeforePharmacy:
            requirePaymentBeforePharmacy ?? this.requirePaymentBeforePharmacy,
        autoCallNextPatient: autoCallNextPatient ?? this.autoCallNextPatient,
        openingTime: openingTime ?? this.openingTime,
        closingTime: closingTime ?? this.closingTime,
        emergencyOpen24h: emergencyOpen24h ?? this.emergencyOpen24h,
        enableSmsReminders: enableSmsReminders ?? this.enableSmsReminders,
        enableEmailNotifications:
            enableEmailNotifications ?? this.enableEmailNotifications,
        send24hAppointmentReminder:
            send24hAppointmentReminder ?? this.send24hAppointmentReminder,
        send1hAppointmentReminder:
            send1hAppointmentReminder ?? this.send1hAppointmentReminder,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
