class DoctorProfileModel {
  final String id;
  final String name;
  final String department;
  final String? contactNumber;
  final String? profilePictureUrl;
  final int patientsCount;

  const DoctorProfileModel({
    required this.id,
    required this.name,
    required this.department,
    this.contactNumber,
    this.profilePictureUrl,
    required this.patientsCount,
  });

  factory DoctorProfileModel.fromJson(Map<String, dynamic> json) {
    final doctor = json['doctor'] as Map<String, dynamic>?;
    final profileId = doctor?['profile_id'] as Map<String, dynamic>?;
    
    return DoctorProfileModel(
      id: (profileId?['_id'] ?? '') as String,
      name: (profileId?['name'] ?? 'Unknown') as String,
      department: (profileId?['department'] ?? 'General') as String,
      contactNumber: profileId?['contact_number'] as String?,
      profilePictureUrl: profileId?['profile_picture_url'] as String?,
      patientsCount: (json['patients_count'] ?? 0) as int,
    );
  }
}
