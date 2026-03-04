class PatientModel {
  final String id;
  final String name;
  final int? age;
  final String? gender;
  final String? opNumber;
  final String? condition;

  const PatientModel({
    required this.id,
    required this.name,
    this.age,
    this.gender,
    this.opNumber,
    this.condition,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    final demographics = json['demographics'] as Map<String, dynamic>?;
    final inrHistory = json['inr_history'] as List<dynamic>?;
    final dynamic ageVal = demographics?['age'];
    final condition = _deriveClinicalCondition(inrHistory);
    return PatientModel(
      id: (json['_id'] ?? '') as String,
      name: (demographics?['name'] ?? 'Unknown') as String,
      age: ageVal is int ? ageVal : null,
      gender: demographics?['gender'] as String?,
      opNumber: json['login_id'] as String?,
      condition: condition,
    );
  }

  static String _deriveClinicalCondition(List<dynamic>? inrHistory) {
    if (inrHistory == null || inrHistory.isEmpty) return 'Not Available';

    Map<String, dynamic>? latestEntry;
    DateTime? latestDate;

    for (final item in inrHistory) {
      if (item is! Map<String, dynamic>) continue;
      final entryDate = DateTime.tryParse(item['test_date']?.toString() ?? '');

      if (latestEntry == null) {
        latestEntry = item;
        latestDate = entryDate;
        continue;
      }

      if (entryDate != null &&
          (latestDate == null || entryDate.isAfter(latestDate))) {
        latestEntry = item;
        latestDate = entryDate;
      }
    }

    final isCritical = latestEntry?['is_critical'] == true;
    return isCritical ? 'Critical' : 'Not Critical';
  }
}
