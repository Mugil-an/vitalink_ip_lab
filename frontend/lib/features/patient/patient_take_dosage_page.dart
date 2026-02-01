import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/index.dart';
import 'package:frontend/app/routers.dart';
import 'package:frontend/services/patient_service.dart';
import 'package:flutter_tanstack_query/flutter_tanstack_query.dart';

class PatientTakeDosagePage extends StatefulWidget {
  const PatientTakeDosagePage({super.key});

  @override
  State<PatientTakeDosagePage> createState() => _PatientTakeDosagePageState();
}

class _PatientTakeDosagePageState extends State<PatientTakeDosagePage> {
  final int _currentNavIndex = 2;
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return UseQuery<Map<String, dynamic>>(
      options: QueryOptions<Map<String, dynamic>>(
        queryKey: const ['patient', 'dosage_full'],
        queryFn: () async {
          final profile = await PatientService.getProfile();
          final missedDosesStrings = await PatientService.getMissedDoses();
          
          // Reconstruct upcoming doses from weeklyDosage
          final weeklyDosage = profile['weeklyDosage'] as Map<String, dynamic>? ?? {};
          final upcomingDoses = _generateUpcomingDoses(weeklyDosage);
          
          return {
            'profile': profile,
            'missed': missedDosesStrings.map((d) => {'date': d, 'dose': 5.0, 'reason': 'Auto-detected', 'status': 'Missed'}).toList(),
            'upcoming': upcomingDoses,
          };
        },
      ),
      builder: (context, query) {
        if (query.isLoading) {
          return const PatientScaffold(
            pageTitle: 'Dosage Management',
            currentNavIndex: 2,
            onNavChanged: _dummyOnNavChanged,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (query.isError) {
          return PatientScaffold(
            pageTitle: 'Dosage Management',
            currentNavIndex: 2,
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
            pageTitle: 'Dosage Management',
            currentNavIndex: 2,
            onNavChanged: _dummyOnNavChanged,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = query.data!;
        final upcomingDoses = data['upcoming'] as List<Map<String, dynamic>>;
        final missedDoses = data['missed'] as List<Map<String, dynamic>>;

        return UseMutation<void, Map<String, dynamic>>(
          options: MutationOptions<void, Map<String, dynamic>>(
            mutationFn: (variables) => PatientService.markDoseAsTaken(
              date: variables['date'],
              dose: variables['dose'],
            ),
            onSuccess: (data, variables) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dose marked as taken!'), backgroundColor: Colors.green),
              );
              query.refetch();
            },
            onError: (error, variables) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${error.toString()}'), backgroundColor: Colors.red),
              );
            },
          ),
          builder: (context, mutation) {
            return PatientScaffold(
              pageTitle: 'Dosage Management',
              currentNavIndex: _currentNavIndex,
              bodyDecoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFC8B5E1), Color(0xFFF8C7D7)],
                ),
              ),
              onNavChanged: (index) => _handleNav(index),
              body: RefreshIndicator(
                onRefresh: () async => query.refetch(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tabs
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildTabItem(0, 'Upcoming (${upcomingDoses.length})'),
                            _buildTabItem(1, 'Missed (${missedDoses.length})'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Content based on selected tab
                      if (_selectedTabIndex == 0)
                        _buildUpcomingDoses(upcomingDoses, mutation)
                      else
                        _buildMissedDoses(missedDoses),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static void _dummyOnNavChanged(int index) {}

  void _handleNav(int index) {
    if (index == _currentNavIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.patientProfile);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.patientUpdateINR);
        break;
      case 2:
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(AppRoutes.patientRecords);
        break;
    }
  }

  Widget _buildTabItem(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: isSelected
                ? Border(
                    bottom: BorderSide(
                      color: Colors.pink[400]!,
                      width: 3,
                    ),
                  )
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.pink[400] : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _generateUpcomingDoses(Map<String, dynamic> weeklyDosage) {
    final List<Map<String, dynamic>> doses = [];
    final now = DateTime.now();
    final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final dayName = dayNames[(date.weekday - 1) % 7];
      final value = weeklyDosage[dayName];
      double doseAmount = 0.0;
      
      if (value is num) {
        doseAmount = value.toDouble();
      } else if (value is String) {
        doseAmount = double.tryParse(value) ?? 0.0;
      }
      
      if (doseAmount > 0) {
        doses.add({
          'id': 'upcoming_$i',
          'date': date,
          'dose': doseAmount,
          'scheduledTime': '08:00 AM', // Default
          'status': i == 0 ? 'Pending' : 'Upcoming',
          'taken': false,
        });
      }
    }
    return doses;
  }

  Widget _buildUpcomingDoses(List<Map<String, dynamic>> doses, MutationResult<void, Map<String, dynamic>> mutation) {
    if (doses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No upcoming doses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: doses.map((dose) {
        final isToday = _isToday(dose['date']);

        return _DosageCard(
          dose: dose,
          isToday: isToday,
          onMarkAsTaken: () => _showMarkAsTakenDialog(dose, mutation),
          onSnooze: () => _snoozeDose(dose),
        );
      }).toList(),
    );
  }

  Widget _buildMissedDoses(List<Map<String, dynamic>> doses) {
    if (doses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.task_alt, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No missed doses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: doses.map((dose) {
        return _MissedDoseCard(
          dose: dose,
          onMarkRecovered: () => _markMissedDoseRecovered(dose),
        );
      }).toList(),
    );
  }

  void _showMarkAsTakenDialog(Map<String, dynamic> dose, MutationResult<void, Map<String, dynamic>> mutation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Dose as Taken'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm taking dosage:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              'Date:',
              PatientService.formatDate(dose['date']),
            ),
            _DetailRow('Dose:', '${dose['dose']} mg'),
            _DetailRow('Time:', dose['scheduledTime']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              mutation.mutate({
                'date': PatientService.formatDate(dose['date']),
                'dose': dose['dose'],
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _snoozeDose(Map<String, dynamic> dose) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Snooze Reminder'),
        content: const Text(
          'You will be reminded again in 1 hour.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reminder snoozed for 1 hour'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Snooze'),
          ),
        ],
      ),
    );
  }

  void _markMissedDoseRecovered(Map<String, dynamic> dose) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Missed Dose'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reason for missing this dose:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              dose['reason'],
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add any additional notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Missed dose reported to your doctor'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _DosageCard extends StatelessWidget {
  final Map<String, dynamic> dose;
  final bool isToday;
  final VoidCallback onMarkAsTaken;
  final VoidCallback onSnooze;

  const _DosageCard({
    required this.dose,
    required this.isToday,
    required this.onMarkAsTaken,
    required this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isToday ? Colors.pink.withValues(alpha: 0.3) : Colors.grey.shade200,
          width: isToday ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with dose amount and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${dose['dose']} mg',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      dose['status'],
                      style: TextStyle(
                        fontSize: 12,
                        color: dose['status'] == 'Pending'
                            ? Colors.orange[600]
                            : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isToday ? Colors.pink.withValues(alpha: 0.1) : null,
                    border: isToday
                        ? Border.all(color: Colors.pink)
                        : Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isToday ? 'TODAY' : 'UPCOMING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isToday ? Colors.pink[600] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 12),

            // Date and time
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  PatientService.formatDate(dose['date']),
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  dose['scheduledTime'],
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onMarkAsTaken,
                    icon: const Icon(Icons.check),
                    label: const Text('Mark as Taken'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSnooze,
                    icon: const Icon(Icons.schedule),
                    label: const Text('Snooze'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MissedDoseCard extends StatelessWidget {
  final Map<String, dynamic> dose;
  final VoidCallback onMarkRecovered;

  const _MissedDoseCard({
    required this.dose,
    required this.onMarkRecovered,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.red.withValues(alpha: 0.02),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with dose amount and warning
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${dose['dose']} mg',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'MISSED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                Icon(Icons.warning_rounded, color: Colors.red[400], size: 24),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.red.withValues(alpha: 0.3)),
            const SizedBox(height: 12),

            // Date and reason
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  PatientService.formatDate(dose['date']),
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dose['reason'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Report button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onMarkRecovered,
                icon: const Icon(Icons.report_problem),
                label: const Text('Report to Doctor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
