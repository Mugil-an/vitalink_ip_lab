import 'package:flutter/material.dart';
import 'package:flutter_tanstack_query/flutter_tanstack_query.dart';
import 'package:frontend/core/di/app_dependencies.dart';
import 'package:frontend/core/widgets/index.dart';
import 'package:frontend/features/doctor/data/doctor_repository.dart';
import 'package:frontend/features/doctor/models/patient_model.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:frontend/features/doctor/add_patient_page.dart';

class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  int _currentNavIndex = 0;
  bool _isTableView = false;
  final TextEditingController _searchController = TextEditingController();
  final DoctorRepository _doctorRepository = AppDependencies.doctorRepository;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PatientModel> _filteredPatients(List<PatientModel> patients) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return patients;
    return patients
        .where((p) =>
            p.name.toLowerCase().contains(query) ||
            (p.opNumber ?? '').toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DoctorScaffold(
      pageTitle: _titleForIndex(_currentNavIndex),
      currentNavIndex: _currentNavIndex,
      onNavChanged: (index) {
        setState(() => _currentNavIndex = index);
      },
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFC8B5E1), Color(0xFFF8C7D7)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            layoutBuilder: (current, previousChildren) => Stack(
              alignment: Alignment.topCenter,
              children: [
                ...previousChildren,
                if (current != null)
                  Align(alignment: Alignment.topCenter, child: current),
              ],
            ),
            child: () {
              switch (_currentNavIndex) {
                case 1:
                  return const AddPatientForm();
                case 2:
                  return const _PlaceholderPage(label: 'Patients');
                case 3:
                  return const _PlaceholderPage(label: 'Reports');
                case 4:
                  return const _PlaceholderPage(label: 'Profile');
                case 0:
                default:
                  return _PatientsView(
                    repository: _doctorRepository,
                    isTableView: _isTableView,
                    onToggleView: (table) => setState(() => _isTableView = table),
                    searchController: _searchController,
                    filterPatients: _filteredPatients,
                  );
              }
            }(),
          ),
        ),
      ),
    );
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 1:
        return '@ Add Patient Page';
      case 2:
        return '@ Patients';
      case 3:
        return '@ Reports';
      case 4:
        return '@ Profile';
      case 0:
      default:
        return '@ Doctor Dashboard';
    }
  }
}

class _PatientsView extends StatelessWidget {
  const _PatientsView({
    required this.repository,
    required this.isTableView,
    required this.onToggleView,
    required this.searchController,
    required this.filterPatients,
  });

  final DoctorRepository repository;
  final bool isTableView;
  final ValueChanged<bool> onToggleView;
  final TextEditingController searchController;
  final List<PatientModel> Function(List<PatientModel>) filterPatients;

  @override
  Widget build(BuildContext context) {
    return UseQuery<List<PatientModel>>(
      options: QueryOptions<List<PatientModel>>(
        queryKey: const ['doctor', 'patients'],
        queryFn: repository.getPatients,
      ),
      builder: (context, query) {
        final patients = query.data ?? <PatientModel>[];
        final filtered = filterPatients(patients);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ToggleBar(
                isTableView: isTableView,
                onToggle: onToggleView,
              ),
              const SizedBox(height: 12),
              _SearchBar(
                controller: searchController,
                count: filtered.length,
              ),
              const SizedBox(height: 16),
              if (query.isLoading)
                const Center(child: CircularProgressIndicator()),
              if (query.isError)
                Text(
                  query.error.toString(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (!query.isLoading && !query.isError)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  child:
                      isTableView ? _TableView(filtered) : _CardView(filtered),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.count});
  final TextEditingController controller;
  final int count;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: const Icon(Icons.search, color: Color(0xFF6B7280)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        hintText: '$count Viewing Patients',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide.none,
        ),
      ),
    ).decorated(
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

class _ToggleBar extends StatelessWidget {
  const _ToggleBar({required this.isTableView, required this.onToggle});
  final bool isTableView;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _TogglePill(
                label: 'Cards',
                isActive: !isTableView,
                onTap: () => onToggle(false),
              ),
              _TogglePill(
                label: 'Table',
                isActive: isTableView,
                onTap: () => onToggle(true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardView extends StatelessWidget {
  const _CardView(this.patients);
  final List<PatientModel> patients;

  @override
  Widget build(BuildContext context) {
    if (patients.isEmpty) return const _EmptyState();
    return Column(
      children: [
        for (final patient in patients)
          _PatientCard(patient: patient)
              .animate(const Duration(milliseconds: 300), Curves.easeOut)
              .padding(bottom: 12),
      ],
    );
  }
}

class _TableView extends StatelessWidget {
  const _TableView(this.patients);
  final List<PatientModel> patients;

  @override
  Widget build(BuildContext context) {
    if (patients.isEmpty) return const _EmptyState();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('OP #')),
          DataColumn(label: Text('Age')),
          DataColumn(label: Text('Gender')),
        ],
        rows: patients
            .map(
              (p) => DataRow(
                cells: [
                  DataCell(Text(p.name)),
                  DataCell(Text(p.opNumber ?? '-')),
                  DataCell(Text(p.age?.toString() ?? '-')),
                  DataCell(Text(p.gender ?? '-')),
                ],
              ),
            )
            .toList(),
      )
          .decorated(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          )
          .padding(all: 4),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Icon(Icons.search_off, size: 36, color: Colors.black54),
        SizedBox(height: 8),
        Text('No patients found'),
      ],
    )
        .center()
        .padding(vertical: 32)
        .decorated(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );
  }
}

class _PatientCard extends StatelessWidget {
  final PatientModel patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return <Widget>[
      Text(
        patient.name,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
      ),
      const SizedBox(height: 4),
      Text('OP #: ${patient.opNumber ?? 'N/A'}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
      Text('Age: ${patient.age ?? '-'}, Gender: ${patient.gender ?? '-'}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
      const SizedBox(height: 10),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () {},
          child: const Text('Show Options'),
        ),
      ),
    ]
        .toColumn(crossAxisAlignment: CrossAxisAlignment.start)
        .padding(all: 14)
        .decorated(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        );
  }
}

class _TogglePill extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TogglePill({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF7643) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.design_services, color: Colors.black54, size: 36),
          const SizedBox(height: 8),
          Text('$label coming soon', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      )
          .padding(all: 18)
          .decorated(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
    );
  }
}
