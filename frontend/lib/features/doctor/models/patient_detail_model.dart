class PatientDetailModel {
  final String id;
  final String name;
  final int? age;
  final String? gender;
  final String? opNumber;
  final String? phone;
  final Map<String, dynamic>? nextOfKin;
  final Map<String, dynamic>? medicalConfig;
  final List<dynamic>? medicalHistory;
  final Map<String, dynamic>? weeklyDosage;
  final List<dynamic>? inrHistory;

  const PatientDetailModel({
    required this.id,
    required this.name,
    this.age,
    this.gender,
    this.opNumber,
    this.phone,
    this.nextOfKin,
    this.medicalConfig,
    this.medicalHistory,
    this.weeklyDosage,
    this.inrHistory,
  });

  factory PatientDetailModel.fromJson(Map<String, dynamic> json) {
    final demographics = json['demographics'] as Map<String, dynamic>?;
    final medicalConfig = json['medical_config'] as Map<String, dynamic>?;
    final weeklyDosage = json['weekly_dosage'] as Map<String, dynamic>?;
    final dynamic ageVal = demographics?['age'];
    
    return PatientDetailModel(
      id: (json['_id'] ?? '') as String,
      name: (demographics?['name'] ?? 'Unknown') as String,
      age: ageVal is int ? ageVal : null,
      gender: demographics?['gender'] as String?,
      opNumber: json['login_id'] as String?,
      phone: demographics?['phone'] as String?,
      nextOfKin: demographics?['next_of_kin'] as Map<String, dynamic>?,
      medicalConfig: medicalConfig,
      medicalHistory: json['medical_history'] as List<dynamic>?,
      weeklyDosage: weeklyDosage,
      inrHistory: json['inr_history'] as List<dynamic>?,
    );
  }
}
