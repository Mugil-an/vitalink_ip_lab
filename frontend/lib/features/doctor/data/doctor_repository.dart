import 'package:frontend/core/constants/strings.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/doctor/models/patient_model.dart';

class DoctorRepository {
  DoctorRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<PatientModel>> getPatients() async {
    final response = await _apiClient.get(AppStrings.doctorPatientsPath);
    final patients = response['patients'];
    if (patients is List) {
      return patients.map((e) => PatientModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> addPatient(Map<String, dynamic> payload) async {
    await _apiClient.post(AppStrings.doctorPatientsPath, data: payload);
  }
}
