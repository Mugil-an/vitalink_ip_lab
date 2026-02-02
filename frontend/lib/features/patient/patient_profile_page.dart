import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/core/widgets/index.dart';
import 'package:frontend/core/di/app_dependencies.dart';
import 'package:frontend/core/storage/secure_storage.dart';
import 'package:frontend/app/routers.dart';
import 'package:frontend/services/patient_service.dart';
import 'package:flutter_tanstack_query/flutter_tanstack_query.dart';
import 'package:intl/intl.dart';

class PatientProfilePage extends StatefulWidget {
  const PatientProfilePage({super.key});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final int _currentNavIndex = 4;

  @override
  Widget build(BuildContext context) {
    return UseQuery<Map<String, dynamic>>(
      options: QueryOptions<Map<String, dynamic>>(
        queryKey: const ['patient', 'profile_full'],
        queryFn: () async {
          final profile = await PatientService.getProfile();
          final history = await PatientService.getINRHistory();
          final latest = await PatientService.getLatestINR();
          return {
            'profile': profile,
            'history': history,
            'latest': latest,
          };
        },
      ),
      builder: (context, query) {
        if (query.isLoading) {
          return const PatientScaffold(
            pageTitle: '@ Profile Page',
            currentNavIndex: 0,
            onNavChanged: _dummyOnNavChanged,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (query.isError) {
          return PatientScaffold(
            pageTitle: '@ Profile Page',
            currentNavIndex: 0,
            onNavChanged: (index) => _handleNav(index),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${query.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => query.refetch(), child: const Text('Retry')),
                ],
              ),
            ),
          );
        }

        if (!query.hasData) {
          return const PatientScaffold(
            pageTitle: '@ Profile Page',
            currentNavIndex: 0,
            onNavChanged: _dummyOnNavChanged,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = query.data!;
        final profile = data['profile'] as Map<String, dynamic>;
        final history = data['history'] as List<Map<String, dynamic>>;
        final latestINR = data['latest'] as double;

        return PatientScaffold(
          pageTitle: '@ Profile Page',
          currentNavIndex: _currentNavIndex,
          onNavChanged: (index) => _handleNav(index),
          bodyDecoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFC8B5E1), Color(0xFFF8C7D7)],
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async => query.refetch(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Header Section
                  _buildTopSummary(profile),
                  const SizedBox(height: 17),

                  // Latest INR Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Latest INR :  ${latestINR.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'AS OF : ${DateFormat('MMMM d, yyyy  h:mm a').format(DateTime.now())}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 17),

                  // Information Table
                  _buildInfoTable(profile),
                  const SizedBox(height: 17),

                  // Medical History Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Medical History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (profile['medicalHistory']?.isEmpty ?? true)
                          const Text('No medical history available', style: TextStyle(color: Colors.black54))
                        else
                          ...(profile['medicalHistory'] as List).map((h) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.circle, size: 6, color: Colors.black54),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${h['diagnosis']} for ${h['duration_value']} ${h['duration_unit']}',
                                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 17),

                  // INR Trend Graph
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'INR Trend',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _buildINRChart(history),
                  const SizedBox(height: 17),

                  // Prescription Section
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'Prescription',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _buildPrescriptionTable(profile),
                  const SizedBox(height: 17),

                  // Health Logs / Summary Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: _buildHealthLogs(profile),
                  ),
                  const SizedBox(height: 17),

                  // Final Contact Table
                  _buildContactTable(profile),
                  const SizedBox(height: 17),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void _dummyOnNavChanged(int index) {}

  void _handleNav(int index) {
    if (index == _currentNavIndex) return;
    switch (index) {
      case 0: Navigator.of(context).pushReplacementNamed(AppRoutes.patientHome); break;
      case 1: Navigator.of(context).pushReplacementNamed(AppRoutes.patientUpdateINR); break;
      case 2: Navigator.of(context).pushReplacementNamed(AppRoutes.patientTakeDosage); break;
      case 3: Navigator.of(context).pushReplacementNamed(AppRoutes.patientHealthReports); break;
      case 4: break;
    }
  }

  Widget _buildTopSummary(Map<String, dynamic> profile) {
    final instructions = profile['instructions'] as List? ?? [];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile['name'] ?? 'Patient Name',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '(Age: ${profile['age']}, Gender: ${profile['gender']?[0]})',
                      style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showUpdateProfileDialog(profile),
                icon: const Icon(Icons.edit, color: Color(0xFF0084FF)),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.black12, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Target INR :', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
              Text(profile['targetINR'] ?? '0 - 0', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.black12, height: 1),
          const SizedBox(height: 16),
          _summaryRow('Next Review Date', profile['nextReviewDate'] ?? 'N/A'),
          const SizedBox(height: 16),
          const Divider(color: Colors.black12, height: 1),
          const SizedBox(height: 20),
          const Text('Instructions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 12),
          if (instructions.isEmpty)
            const Text('No instructions provided', style: TextStyle(color: Colors.black54, fontSize: 13))
          else
            ...instructions.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(i, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87))),
                  const Text('18 Oct 2025, 18:08', style: TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildInfoTable(Map<String, dynamic> profile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(2),
          },
          border: TableBorder.symmetric(inside: const BorderSide(color: Colors.black12)),
          children: [
            _tableRow('Doctor', profile['doctorName'] ?? 'N/A'),
            _tableRow('Caregiver', profile['caregiver'] ?? 'N/A'),
            _tableRow('Therapy', profile['therapyDrug'] ?? 'N/A'),
            _tableRow('Therapy Start Date', profile['therapyStartDate'] ?? 'N/A'),
            _tableRow('Next Review Date', profile['nextReviewDate'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionTable(Map<String, dynamic> profile) {
    final dosage = profile['weeklyDosage'] as Map? ?? {};
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(2),
          },
          border: TableBorder.symmetric(inside: const BorderSide(color: Colors.black12)),
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Color(0x0D000000)), // black with 0.05 opacity
              children: [
                Padding(padding: EdgeInsets.all(12), child: Text('Day', style: TextStyle(fontWeight: FontWeight.w800))),
                Padding(padding: EdgeInsets.all(12), child: Text('Dose', style: TextStyle(fontWeight: FontWeight.w800))),
              ],
            ),
            ...days.map((d) => _tableRow(d.substring(0, 3).toUpperCase(), '${dosage[d] ?? 0}')),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthLogs(Map<String, dynamic> profile) {
    final logs = profile['healthLogs'] as List? ?? [];
    String sideEffects = 'None';
    String lifestyle = 'None';
    String medication = 'None';
    String illness = 'None';

    for(var log in logs) {
      if(log['type'] == 'SIDE_EFFECT') sideEffects = log['description'];
      if(log['type'] == 'LIFESTYLE') lifestyle = log['description'];
      if(log['type'] == 'OTHER_MEDS') medication = log['description'];
      if(log['type'] == 'ILLNESS') illness = log['description'];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _healthLogRow('SIDE EFFECTS', sideEffects),
        _healthLogRow('LIFESTYLE CHANGES', lifestyle),
        _healthLogRow('OTHER MEDICATION', medication),
        _healthLogRow('PROLONGED ILLNESS', illness),
      ],
    );
  }

  Widget _healthLogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
    );
  }

  Widget _buildContactTable(Map<String, dynamic> profile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(2),
          },
          border: TableBorder.symmetric(inside: const BorderSide(color: Colors.black12)),
          children: [
            _tableRow('Contact', profile['phone'] ?? 'N/A'),
            _tableRow('Kin Name', profile['kinName'] ?? 'N/A'),
            _tableRow('Kin Contact', profile['kinPhone'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildINRChart(List<Map<String, dynamic>> inrHistory) {
    if (inrHistory.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('Insufficient data for graph', style: TextStyle(color: Colors.black54))),
      );
    }

    final spots = inrHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['inr'])).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22, getTitlesWidget: (val, meta) {
              if (val.toInt() >= 0 && val.toInt() < inrHistory.length) {
                return Text(inrHistory[val.toInt()]['date'].split('-')[0], style: const TextStyle(fontSize: 10));
              }
              return const SizedBox();
            })),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFFC04848),
              barWidth: 4,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: const Color(0xFFC04848).withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
      ],
    );
  }

  TableRow _tableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(value, style: const TextStyle(color: Colors.black87)),
        ),
      ],
    );
  }

  void _showUpdateProfileDialog(Map<String, dynamic> profile) {
    final nameController = TextEditingController(text: profile['name']);
    final ageController = TextEditingController(text: profile['age']?.toString() ?? '');
    final phoneController = TextEditingController(text: profile['phone'] ?? '');
    final caregiverController = TextEditingController(text: profile['caregiver'] ?? '');
    final kinNameController = TextEditingController(text: profile['kinName'] ?? '');
    final kinPhoneController = TextEditingController(text: profile['kinPhone'] ?? '');
    final therapyDrugController = TextEditingController(text: profile['therapyDrug'] ?? '');
    final therapyStartDateController = TextEditingController(text: profile['therapyStartDate'] ?? '');
    
    String? selectedGender = profile['gender'];

    showDialog(
      context: context,
      builder: (dialogContext) => UseMutation<void, Map<String, dynamic>>(
        options: MutationOptions<void, Map<String, dynamic>>(
          mutationFn: (variables) => PatientService.updateProfile(
            demographics: variables['demographics'],
            medicalConfig: variables['medical_config'],
          ),
          onSuccess: (data, variables) {
            Navigator.pop(dialogContext);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            // Invalidate multiple queries to refetch updated data
            final queryClient = QueryClientProvider.of(context);
            queryClient.invalidateQueries(['patient', 'profile_full']);
            queryClient.invalidateQueries(['patient', 'records_full']);
            queryClient.invalidateQueries(['patient', 'home_data']);
          },
          onError: (error, variables) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${error.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
        builder: (context, mutation) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Update Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField('Name', nameController),
                  const SizedBox(height: 16),
                  _buildTextField('Age', ageController, keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  _buildTextField('Phone', phoneController, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  const Text(
                    'Gender',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StatefulBuilder(
                    builder: (context, setState) => DropdownButtonFormField<String>(
                      value: selectedGender,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setState(() => selectedGender = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField('Caregiver', caregiverController),
                  const SizedBox(height: 16),
                  _buildTextField('Kin Name', kinNameController),
                  const SizedBox(height: 16),
                  _buildTextField('Kin Phone', kinPhoneController, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildTextField('Therapy Drug', therapyDrugController),
                  const SizedBox(height: 16),
                  _buildTextField('Therapy Start Date (DD-MM-YYYY)', therapyStartDateController),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                onPressed: mutation.isLoading
                    ? null
                    : () {
                        final demographics = <String, dynamic>{};
                        final medicalConfig = <String, dynamic>{};

                        if (nameController.text.isNotEmpty) {
                          demographics['name'] = nameController.text;
                        }
                        if (ageController.text.isNotEmpty) {
                          demographics['age'] = int.tryParse(ageController.text) ?? 0;
                        }
                        if (selectedGender != null) {
                          demographics['gender'] = selectedGender;
                        }
                        if (phoneController.text.isNotEmpty) {
                          demographics['phone'] = phoneController.text;
                        }
                        if (caregiverController.text.isNotEmpty) {
                          demographics['caregiver'] = caregiverController.text;
                        }
                        if (kinNameController.text.isNotEmpty) {
                          demographics['kin_name'] = kinNameController.text;
                        }
                        if (kinPhoneController.text.isNotEmpty) {
                          demographics['kin_phone'] = kinPhoneController.text;
                        }
                        if (therapyDrugController.text.isNotEmpty) {
                          medicalConfig['therapy_drug'] = therapyDrugController.text;
                        }
                        if (therapyStartDateController.text.isNotEmpty) {
                          medicalConfig['therapy_start_date'] = therapyStartDateController.text;
                        }

                        mutation.mutate({
                          'demographics': demographics,
                          'medical_config': medicalConfig,
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0084FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: mutation.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => LogoutDialog(
        onLogout: () async {
          final SecureStorage secureStorage = AppDependencies.secureStorage;
          await secureStorage.clearAll();
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.login,
              (route) => false,
            );
          }
        },
      ),
    );
  }
}
