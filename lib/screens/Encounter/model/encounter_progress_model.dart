class EncounterProgressModel {
  final int existingEncounters;
  final int totalRequired;
  final int remaining;
  final bool canCreateMore;
  final String encounterType; // 'session', 'day', or 'standard'
  final List<EncounterSummary> encountersList;

  EncounterProgressModel({
    required this.existingEncounters,
    required this.totalRequired,
    required this.remaining,
    required this.canCreateMore,
    required this.encounterType,
    required this.encountersList,
  });

  factory EncounterProgressModel.fromJson(Map<String, dynamic> json) {
    return EncounterProgressModel(
      existingEncounters: json['existing_encounters'] ?? 0,
      totalRequired: json['total_required'] ?? 1,
      remaining: json['remaining'] ?? 0,
      canCreateMore: json['can_create_more'] ?? false,
      encounterType: json['encounter_type'] ?? 'standard',
      encountersList: (json['encounters_list'] as List? ?? [])
          .map((e) => EncounterSummary.fromJson(e))
          .toList(),
    );
  }
}

class EncounterSummary {
  final int id;
  final String encounterDate;
  final int? sessionNumber;
  final int? dayNumber;
  final bool isCompleted;
  final int status;

  EncounterSummary({
    required this.id,
    required this.encounterDate,
    this.sessionNumber,
    this.dayNumber,
    required this.isCompleted,
    required this.status,
  });

  factory EncounterSummary.fromJson(Map<String, dynamic> json) {
    return EncounterSummary(
      id: json['id'] ?? 0,
      encounterDate: json['encounter_date'] ?? '',
      sessionNumber: json['session_number'],
      dayNumber: json['day_number'],
      isCompleted: json['is_completed'] ?? false,
      status: json['status'] ?? 0,
    );
  }
}
