import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/index.dart';
import 'package:frontend/services/patient_service.dart';
import 'package:frontend/app/routers.dart';
import 'package:flutter_tanstack_query/flutter_tanstack_query.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  final int _currentNavIndex = 0;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UseQuery<Map<String, dynamic>>(
      options: QueryOptions<Map<String, dynamic>>(
        queryKey: const ['patient', 'home_data'],
        queryFn: () async {
          final profile = await PatientService.getProfile();
          final history = await PatientService.getINRHistory();
          final prescriptions = await PatientService.getPrescriptions();
          final latestINR = await PatientService.getLatestINR();

          return {
            'patientData': {
              ...profile,
              'latestINR': latestINR,
            },
            'medicalHistory': history,
            'prescriptions': prescriptions,
          };
        },
      ),
      builder: (context, query) {
        if (query.isLoading) {
          return PatientScaffold(
            pageTitle: '@ Patient Home',
            currentNavIndex: _currentNavIndex,
            onNavChanged: _handleNav,
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (query.isError) {
          return PatientScaffold(
            pageTitle: '@ Patient Home',
            currentNavIndex: _currentNavIndex,
            onNavChanged: _handleNav,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[400],
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error Loading Data',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      query.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => query.refetch(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = query.data!;
        final patientData = data['patientData'] as Map<String, dynamic>;
        final medicalHistory = data['medicalHistory'] as List<Map<String, dynamic>>;
        final prescriptions = data['prescriptions'] as List<Map<String, dynamic>>;

        return PatientScaffold(
          pageTitle: '@ Patient Home',
          currentNavIndex: _currentNavIndex,
          onNavChanged: _handleNav,
          body: RefreshIndicator(
            onRefresh: () async => query.refetch(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with title
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Viewing Your Profile',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Patient card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Patient name
                          Text(
                            patientData['name'] ?? 'Patient',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // OP Number and demographics
                          Text(
                            'OP #: ${patientData['opNumber'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Age: ${patientData['age'] ?? 'N/A'}, Gender: ${patientData['gender'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Medical info section
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InfoRow(
                                  'Target INR',
                                  patientData['targetINR'] ?? 'N/A',
                                ),
                                const SizedBox(height: 8),
                                _InfoRow(
                                  'Latest INR',
                                  patientData['latestINR']?.toString() ?? 'N/A',
                                ),
                                const SizedBox(height: 8),
                                _InfoRow(
                                  'Next Review',
                                  patientData['nextReviewDate'] ?? 'N/A',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Quick action buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pushReplacementNamed('/patient-update-inr');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink[400],
                                  ),
                                  child: const Text(
                                    'Update INR',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pushReplacementNamed(
                                        '/patient-take-dosage');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: const Text(
                                    'Dosage',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Latest INR Section
                  const Text(
                    'Latest INR Results',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'INR Value',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${patientData['latestINR'] ?? 'N/A'}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 32,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Status: Within Target Range (${patientData['targetINR'] ?? 'N/A'})',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Medical History Section
                  const Text(
                    'Medical History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  medicalHistory.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No medical history available',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: medicalHistory.length,
                          itemBuilder: (context, index) {
                            final history = medicalHistory[index];
                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          history['date'] ?? 'N/A',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: history['status'] == 'Normal'
                                                ? Colors.green.withOpacity(0.2)
                                                : Colors.orange.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            history['status'] ?? 'Unknown',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: history['status'] ==
                                                      'Normal'
                                                  ? Colors.green[700]
                                                  : Colors.orange[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'INR: ${history['inr'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      history['notes'] ?? 'No notes',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 24),

                  // Prescriptions Section
                  const Text(
                    'Current Prescriptions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  prescriptions.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No prescriptions available',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: prescriptions.length,
                          itemBuilder: (context, index) {
                            final prescription = prescriptions[index];
                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          prescription['drug'] ?? 'Unknown Drug',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.pink.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            prescription['dosage'] ?? 'N/A',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.pink[400],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    _InfoRow('Frequency',
                                        prescription['frequency'] ?? 'N/A'),
                                    const SizedBox(height: 6),
                                    _InfoRow(
                                        'Started', prescription['startDate'] ?? 'N/A'),
                                    const SizedBox(height: 8),
                                    Text(
                                      prescription['instructions'] ?? 'No instructions',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleNav(int index) {
    if (index == _currentNavIndex) return;
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.patientUpdateINR);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.patientTakeDosage);
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(AppRoutes.patientHealthReports);
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(AppRoutes.patientProfile);
        break;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
