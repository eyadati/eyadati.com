import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'doctor_sidebar.dart';
import 'doctor_calendar_view.dart';
import 'doctor_add_appointment_dialog.dart';
import '../../clinics/clinic_appointments.dart';
import '../../dashboard/shared/appointments_management.dart';

SupabaseClient get _supabase => Supabase.instance.client;

class DoctorWebDashboard extends StatefulWidget {
  final String clinicId;
  final Function(int)? onMenuChanged;

  const DoctorWebDashboard({
    super.key,
    required this.clinicId,
    this.onMenuChanged,
  });

  @override
  State<DoctorWebDashboard> createState() => _DoctorWebDashboardState();
}

class _DoctorWebDashboardState extends State<DoctorWebDashboard> {
  Map<String, dynamic>? _clinic;
  bool _isLoading = true;
  int _selectedMenu = 0;

  @override
  void initState() {
    super.initState();
    _loadClinic();
  }

  Future<void> _loadClinic() async {
    try {
      final response = await _supabase
          .from('clinics')
          .select()
          .eq('uid', widget.clinicId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _clinic = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading clinic: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_clinic == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('clinic_not_found'.tr()),
          ],
        ),
      );
    }

    return Row(
      children: [
        DoctorSidebar(
          clinicId: widget.clinicId,
          clinicData: _clinic,
          selectedIndex: _selectedMenu,
          onMenuSelected: (index) {
            setState(() => _selectedMenu = index);
            widget.onMenuChanged?.call(index);
          },
        ),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_selectedMenu) {
      case 0:
        return _buildDashboard();
      case 1:
        return DoctorCalendarView(
          clinicId: widget.clinicId,
          clinicData: _clinic,
        );
      case 2:
        return ClinicAppointments(clinicId: widget.clinicId);
      case 3:
        return ManagementScreen(clinicUid: widget.clinicId);
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _clinic?['doctor_name'] ?? _clinic?['name'] ?? 'Dashboard',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'welcome_back'.tr(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showAddAppointmentDialog(),
                icon: const Icon(LucideIcons.plus),
                label: Text('new_appointment'.tr()),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildStats(),
          const SizedBox(height: 32),
          _buildQuickActions(),
          const SizedBox(height: 32),
          _buildRecentAppointments(),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('today_appointments'.tr(), '12', LucideIcons.calendar, Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('completed'.tr(), '8', LucideIcons.checkCircle, Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('total_patients'.tr(), '156', LucideIcons.users, Colors.purple)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('pending'.tr(), '4', LucideIcons.clock, Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'quick_actions'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildActionCard(
              'add_appointment'.tr(),
              LucideIcons.calendarPlus,
              () => _showAddAppointmentDialog(),
            ),
            const SizedBox(width: 12),
            _buildActionCard(
              'view_schedule'.tr(),
              LucideIcons.calendar,
              () => setState(() => _selectedMenu = 1),
            ),
            const SizedBox(width: 12),
            _buildActionCard(
              'patients'.tr(),
              LucideIcons.users,
              () => setState(() => _selectedMenu = 2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'recent_appointments'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text('${index + 1}'),
                ),
                title: Text('Patient ${index + 1}'),
                subtitle: Text('10:${(index * 30).toString().padLeft(2, '0')} - ${_clinic?['specialty'] ?? ''}'),
                trailing: Chip(
                  label: Text('upcoming'.tr(), style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.blue.withAlpha(30),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => DoctorAddAppointmentDialog(
        clinicId: widget.clinicId,
        clinic: _clinic,
      ),
    );
  }
}