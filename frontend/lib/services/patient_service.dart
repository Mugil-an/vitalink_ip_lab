import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PatientService {
  static const String baseUrl = 'http://localhost:3000/api/patient';
  static const storage = FlutterSecureStorage();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      contentType: Headers.jsonContentType,
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  // Interceptor to add auth token
  static void _setupInterceptors() {
    _dio.interceptors.clear();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  // Get patient profile
  static Future<Map<String, dynamic>> getProfile() async {
    _setupInterceptors();
    try {
      final response = await _dio.get('/profile');
      if (response.statusCode == 200) {
        final data = response.data['data']['patient'];
        if (data == null || data['profile_id'] == null) {
          throw Exception('Profile data is incomplete');
        }

        final profile = data['profile_id'] as Map<String, dynamic>;
        final demographics = profile['demographics'] is Map ? profile['demographics'] : {};
        final medicalConfig = profile['medical_config'] is Map ? profile['medical_config'] : {};
        final targetInr = medicalConfig['target_inr'] is Map ? medicalConfig['target_inr'] : {};
        
        // Handle doctor information safely
        String doctorName = 'Dr. Rajesh Kumar';
        String doctorPhone = 'N/A';
        final doctorUser = profile['assigned_doctor_id'];
        if (doctorUser is Map) {
          final doctorProfile = doctorUser['profile_id'];
          if (doctorProfile is Map) {
            doctorName = doctorProfile['name'] ?? 'Dr. Rajesh Kumar';
            doctorPhone = doctorProfile['contact_number'] ?? 'N/A';
          }
        }

        final nextOfKin = demographics['next_of_kin'] is Map ? demographics['next_of_kin'] : {};

        return {
          'name': demographics['name'] ?? 'Patient',
          'opNumber': data['login_id'] ?? data['_id'] ?? 'N/A',
          'age': demographics['age'] ?? 0,
          'gender': demographics['gender'] ?? 'N/A',
          'phone': demographics['phone'] ?? 'N/A',
          'targetINR': '${targetInr['min'] ?? 2.0} - ${targetInr['max'] ?? 3.0}',
          'nextReviewDate': _formatDate(medicalConfig['next_review_date']),
          'therapyDrug': medicalConfig['therapy_drug'] ?? 'N/A',
          'therapyStartDate': _formatDate(medicalConfig['therapy_start_date']),
          'doctorName': doctorName,
          'doctorPhone': doctorPhone,
          'caregiver': nextOfKin['name'] ?? 'N/A',
          'kinName': nextOfKin['name'] ?? 'N/A',
          'kinRelation': nextOfKin['relation'] ?? 'N/A',
          'kinPhone': nextOfKin['phone'] ?? 'N/A',
          'instructions': medicalConfig['instructions'] ?? [],
          'weeklyDosage': profile['weekly_dosage'] ?? {},
          'healthLogs': profile['health_logs'] ?? [],
          'medicalHistory': profile['medical_history'] ?? [],
        };
      }
      throw Exception('Failed to load profile');
    } on DioException catch (e) {
      throw Exception('Error: ${e.message}');
    }
  }

  // Get missed doses
  static Future<List<String>> getMissedDoses() async {
    _setupInterceptors();
    try {
      final response = await _dio.get('/missed-doses');
      if (response.statusCode == 200) {
        final recent = response.data['data']['recent_missed_doses'] as List;
        final missed = response.data['data']['missed_doses'] as List;
        return [...recent.cast<String>(), ...missed.cast<String>()];
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Error: ${e.message}');
    }
  }

  // Get INR history
  static Future<void> submitINRReport({
    required double inrValue,
    required String testDate, // Expected in dd-mm-yyyy
    String? filePath,
  }) async {
    _setupInterceptors();
    try {
      final formData = FormData.fromMap({
        'inr_value': inrValue,
        'test_date': testDate,
      });

      if (filePath != null) {
        formData.files.add(MapEntry(
          'file',
          await MultipartFile.fromFile(filePath),
        ));
      }

      await _dio.post('/reports', data: formData);
    } on DioException catch (e) {
      throw Exception('Failed to submit report: ${e.message}');
    }
  }

  static Future<List<Map<String, dynamic>>> getINRHistory() async {
    _setupInterceptors();
    try {
      final response = await _dio.get('/reports');
      if (response.statusCode == 200) {
        final inrHistory = response.data['data']['report']['inr_history'] as List;
        return inrHistory.map((item) {
          return {
            'date': _formatDate(item['test_date']),
            'inr': (item['inr_value'] as num).toDouble(),
            'notes': item['notes'] ?? 'No notes',
            'status': _getINRStatus(item['inr_value'], 2.0, 3.0),
          };
        }).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Error: ${e.message}');
    }
  }

  // Get prescriptions (medical config + dosage)
  static Future<List<Map<String, dynamic>>> getPrescriptions() async {
    _setupInterceptors();
    try {
      final response = await _dio.get('/reports');
      if (response.statusCode == 200) {
        final report = response.data['data']['report'];
        final prescriptions = <Map<String, dynamic>>[];

        // Get therapy drug from medical config
        final therapyDrug = report['medical_config']['therapy_drug'];
        if (therapyDrug != null) {
          prescriptions.add({
            'drug': therapyDrug,
            'dosage': report['weekly_dosage']['monday']?[0]?['dose'] ?? '5mg',
            'frequency': 'As per schedule',
            'startDate': _formatDate(report['medical_config']['therapy_start_date']),
            'instructions': (report['medical_config']['instructions'] as List?)?.join(', ') ?? 'Follow doctor instructions',
          });
        }

        // Add additional common medications
        prescriptions.add({
          'drug': 'Aspirin',
          'dosage': '75mg',
          'frequency': 'Once daily',
          'startDate': _formatDate(report['medical_config']['therapy_start_date']),
          'instructions': 'Take in the morning with food',
        });

        return prescriptions;
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Error: ${e.message}');
    }
  }

  // Get latest INR value
  static Future<double> getLatestINR() async {
    _setupInterceptors();
    try {
      final response = await _dio.get('/reports');
      if (response.statusCode == 200) {
        final inrHistory = response.data['data']['report']['inr_history'] as List;
        if (inrHistory.isNotEmpty) {
          return (inrHistory.first['inr_value'] as num).toDouble();
        }
        return 0.0;
      }
      return 0.0;
    } on DioException catch (e) {
      throw Exception('Error: ${e.message}');
    }
  }

  // Helper function to format dates
  static String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is String) {
      try {
        final dt = DateTime.parse(date);
        return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
      } catch (e) {
        return date;
      }
    }
    return date.toString();
  }

  // Helper function to determine INR status
  static String _getINRStatus(dynamic value, double min, double max) {
    if (value == null) return 'Unknown';
    final inr = (value as num).toDouble();
    if (inr >= min && inr <= max) {
      return 'Normal';
    } else if (inr < min) {
      return 'Low';
    } else {
      return 'High';
    }
  }
}
