class PatientModel {
  final String id;
  final String name;
  final int? age;
  final String? gender;
  final String? opNumber;

  const PatientModel({
    required this.id,
    required this.name,
    this.age,
    this.gender,
    this.opNumber,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    final demographics = json['demographics'] as Map<String, dynamic>?;
    final dynamic ageVal = demographics?['age'];
    return PatientModel(
      id: (json['_id'] ?? '') as String,
      name: (demographics?['name'] ?? 'Unknown') as String,
      age: ageVal is int ? ageVal : null,
      gender: demographics?['gender'] as String?,
      opNumber: json['login_id'] as String?,
    );
  }
}
