import '../core/json_dates.dart';
import 'tracking_mode.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? username;
  final String? displayName;
  final DateTime? dateOfBirth;
  final int averageCycleLength;
  final int averagePeriodLength;
  final bool notificationsEnabled;
  // Time of day (24-hour) at which reminders fire. Defaults to 9:00 AM.
  final int reminderHour;
  final int reminderMinute;
  final DateTime createdAt;

  // Mode + setup
  final TrackingMode? trackingMode;
  final bool setupComplete;

  // Pregnancy-specific
  final DateTime? dueDate;
  final DateTime? lastMenstrualPeriod; // for pregnancy mode if no due date

  // Medical history (used in conception + pregnancy flows)
  final int? age;
  final bool? hasIrregularCycles;
  final bool? hasMedicalConditions;
  final List<String> medicalConditions;
  final int? previousPregnancies;
  final bool? takingPrenatalVitamins;

  // Partner sharing - uids of the partners this user has connected to
  // (read-only view of each partner's cycle). Same-device, fully offline.
  final List<String> linkedPartnerUids;

  /// Convenience: the most-recently linked partner, or null.
  String? get linkedPartnerUid =>
      linkedPartnerUids.isEmpty ? null : linkedPartnerUids.last;

  // Set true if this user signed in only to follow their partner's cycle
  // (does not track their own data). Drives a separate Home screen.
  final bool partnerOnlyMode;

  // True once the user has finished (or skipped) the in-app tutorial.
  // Defaults to false so new users see it; veterans can replay from Profile.
  final bool hasSeenTutorial;

  /// Which reminder types this person wants. Defaults on; she can mute any.
  final bool notifyPeriod;
  final bool notifyFertile;
  final bool notifyDailyLog;
  final bool notifyVitamins;
  final bool notifyTrimester;

  /// Visual look id - see [AppLook].
  final String themeId;

  /// Full editable theme prefs (colors, motif, text, corners).
  final Map<String, dynamic> themePrefs;

  const UserProfile({
    required this.uid,
    required this.email,
    this.username,
    this.displayName,
    this.dateOfBirth,
    this.averageCycleLength = 28,
    this.averagePeriodLength = 5,
    this.notificationsEnabled = true,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    required this.createdAt,
    this.trackingMode,
    this.setupComplete = false,
    this.dueDate,
    this.lastMenstrualPeriod,
    this.age,
    this.hasIrregularCycles,
    this.hasMedicalConditions,
    this.medicalConditions = const [],
    this.previousPregnancies,
    this.takingPrenatalVitamins,
    this.linkedPartnerUids = const [],
    this.partnerOnlyMode = false,
    this.hasSeenTutorial = false,
    this.notifyPeriod = true,
    this.notifyFertile = true,
    this.notifyDailyLog = true,
    this.notifyVitamins = true,
    this.notifyTrimester = true,
    this.themeId = 'blossom',
    this.themePrefs = const {},
  });

  String get firstName {
    final n = (displayName ?? username ?? '').trim();
    if (n.isEmpty) return '';
    return n.split(RegExp(r'\s+')).first;
  }

  String get greetingName => firstName.isEmpty ? 'love' : firstName;

  UserProfile copyWith({
    String? username,
    String? displayName,
    DateTime? dateOfBirth,
    int? averageCycleLength,
    int? averagePeriodLength,
    bool? notificationsEnabled,
    int? reminderHour,
    int? reminderMinute,
    TrackingMode? trackingMode,
    bool? setupComplete,
    DateTime? dueDate,
    DateTime? lastMenstrualPeriod,
    int? age,
    bool? hasIrregularCycles,
    bool? hasMedicalConditions,
    List<String>? medicalConditions,
    int? previousPregnancies,
    bool? takingPrenatalVitamins,
    List<String>? linkedPartnerUids,
    String? addLinkedPartnerUid,
    String? removeLinkedPartnerUid,
    bool clearLinkedPartner = false,
    bool? partnerOnlyMode,
    bool? hasSeenTutorial,
    bool? notifyPeriod,
    bool? notifyFertile,
    bool? notifyDailyLog,
    bool? notifyVitamins,
    bool? notifyTrimester,
    String? themeId,
    Map<String, dynamic>? themePrefs,
  }) {
    List<String> nextLinked;
    if (clearLinkedPartner) {
      nextLinked = const [];
    } else if (linkedPartnerUids != null) {
      nextLinked = linkedPartnerUids;
    } else if (addLinkedPartnerUid != null) {
      nextLinked = {...this.linkedPartnerUids, addLinkedPartnerUid}.toList();
    } else if (removeLinkedPartnerUid != null) {
      nextLinked = this
          .linkedPartnerUids
          .where((u) => u != removeLinkedPartnerUid)
          .toList();
    } else {
      nextLinked = this.linkedPartnerUids;
    }
    return UserProfile(
      uid: uid,
      email: email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      averageCycleLength: averageCycleLength ?? this.averageCycleLength,
      averagePeriodLength: averagePeriodLength ?? this.averagePeriodLength,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      createdAt: createdAt,
      trackingMode: trackingMode ?? this.trackingMode,
      setupComplete: setupComplete ?? this.setupComplete,
      dueDate: dueDate ?? this.dueDate,
      lastMenstrualPeriod: lastMenstrualPeriod ?? this.lastMenstrualPeriod,
      age: age ?? this.age,
      hasIrregularCycles: hasIrregularCycles ?? this.hasIrregularCycles,
      hasMedicalConditions: hasMedicalConditions ?? this.hasMedicalConditions,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      previousPregnancies: previousPregnancies ?? this.previousPregnancies,
      takingPrenatalVitamins:
          takingPrenatalVitamins ?? this.takingPrenatalVitamins,
      linkedPartnerUids: nextLinked,
      partnerOnlyMode: partnerOnlyMode ?? this.partnerOnlyMode,
      hasSeenTutorial: hasSeenTutorial ?? this.hasSeenTutorial,
      notifyPeriod: notifyPeriod ?? this.notifyPeriod,
      notifyFertile: notifyFertile ?? this.notifyFertile,
      notifyDailyLog: notifyDailyLog ?? this.notifyDailyLog,
      notifyVitamins: notifyVitamins ?? this.notifyVitamins,
      notifyTrimester: notifyTrimester ?? this.notifyTrimester,
      themeId: themeId ?? this.themeId,
      themePrefs: themePrefs ?? this.themePrefs,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'username': username,
        'displayName': displayName,
        'dateOfBirth': JsonDates.encode(dateOfBirth),
        'averageCycleLength': averageCycleLength,
        'averagePeriodLength': averagePeriodLength,
        'notificationsEnabled': notificationsEnabled,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'createdAt': JsonDates.encode(createdAt),
        'trackingMode': trackingMode?.id,
        'setupComplete': setupComplete,
        'dueDate': JsonDates.encode(dueDate),
        'lastMenstrualPeriod': JsonDates.encode(lastMenstrualPeriod),
        'age': age,
        'hasIrregularCycles': hasIrregularCycles,
        'hasMedicalConditions': hasMedicalConditions,
        'medicalConditions': medicalConditions,
        'previousPregnancies': previousPregnancies,
        'takingPrenatalVitamins': takingPrenatalVitamins,
        'linkedPartnerUids': linkedPartnerUids,
        'partnerOnlyMode': partnerOnlyMode,
        'hasSeenTutorial': hasSeenTutorial,
        'notifyPeriod': notifyPeriod,
        'notifyFertile': notifyFertile,
        'notifyDailyLog': notifyDailyLog,
        'notifyVitamins': notifyVitamins,
        'notifyTrimester': notifyTrimester,
        'themeId': themeId,
        'themePrefs': themePrefs,
      };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        uid: m['uid'] as String,
        email: m['email'] as String? ?? '',
        username: m['username'] as String?,
        displayName: m['displayName'] as String?,
        dateOfBirth: JsonDates.decode(m['dateOfBirth']),
        averageCycleLength: m['averageCycleLength'] as int? ?? 28,
        averagePeriodLength: m['averagePeriodLength'] as int? ?? 5,
        notificationsEnabled: m['notificationsEnabled'] as bool? ?? true,
        reminderHour: m['reminderHour'] as int? ?? 9,
        reminderMinute: m['reminderMinute'] as int? ?? 0,
        createdAt: JsonDates.decode(m['createdAt']) ?? DateTime.now(),
        trackingMode: TrackingMode.fromId(m['trackingMode'] as String?),
        setupComplete: m['setupComplete'] as bool? ?? false,
        dueDate: JsonDates.decode(m['dueDate']),
        lastMenstrualPeriod: JsonDates.decode(m['lastMenstrualPeriod']),
        age: m['age'] as int?,
        hasIrregularCycles: m['hasIrregularCycles'] as bool?,
        hasMedicalConditions: m['hasMedicalConditions'] as bool?,
        medicalConditions:
            List<String>.from(m['medicalConditions'] as List? ?? const []),
        previousPregnancies: m['previousPregnancies'] as int?,
        takingPrenatalVitamins: m['takingPrenatalVitamins'] as bool?,
        linkedPartnerUids: m['linkedPartnerUids'] != null
            ? List<String>.from(m['linkedPartnerUids'] as List)
            : (m['linkedPartnerUid'] is String &&
                    (m['linkedPartnerUid'] as String).isNotEmpty
                ? <String>[m['linkedPartnerUid'] as String]
                : const <String>[]),
        partnerOnlyMode: m['partnerOnlyMode'] as bool? ?? false,
        hasSeenTutorial: m['hasSeenTutorial'] as bool? ?? false,
        notifyPeriod: m['notifyPeriod'] as bool? ?? true,
        notifyFertile: m['notifyFertile'] as bool? ?? true,
        notifyDailyLog: m['notifyDailyLog'] as bool? ?? true,
        notifyVitamins: m['notifyVitamins'] as bool? ?? true,
        notifyTrimester: m['notifyTrimester'] as bool? ?? true,
        themeId: m['themeId'] as String? ?? 'blossom',
        themePrefs: m['themePrefs'] is Map
            ? Map<String, dynamic>.from(m['themePrefs'] as Map)
            : const {},
      );
}
