import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eyadati/core/routing/route_names.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_spacing.dart';
import 'package:eyadati/l10n/app_localizations.dart';
import '../providers/providers.dart';

class PatientAppointmentsPage extends ConsumerStatefulWidget {
  const PatientAppointmentsPage({super.key});

  @override
  ConsumerState<PatientAppointmentsPage> createState() => _PatientAppointmentsPageState();
}

class _PatientAppointmentsPageState extends ConsumerState<PatientAppointmentsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(patientProvider.notifier).loadPatientData());
  }

  @override
  Widget build(BuildContext context) {
    final patientState = ref.watch(patientProvider);
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.appointmentsMyAppointments),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: l10n.appointmentsUpcoming),
              Tab(text: l10n.appointmentsPast),
              Tab(text: l10n.appointmentsCancelled),
            ],
          ),
        ),
        body: patientState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (patientState.hasSufficientHistory)
                    _buildAttendanceRateBar(patientState.attendanceRate),
                  if (patientState.noShowCount == 1)
                    _buildNoShowBanner(
                      patientState.noShowCount,
                      AppColors.textHint,
                      AppColors.background,
                      Icons.info_outline,
                    )
                  else if (patientState.noShowCount == 2)
                    _buildNoShowBanner(
                      patientState.noShowCount,
                      AppColors.warning,
                      AppColors.warning.withValues(alpha: 0.15),
                      Icons.warning_amber,
                    )
                  else if (patientState.noShowCount >= 3)
                    _buildNoShowBanner(
                      patientState.noShowCount,
                      AppColors.error,
                      AppColors.error.withValues(alpha: 0.1),
                      Icons.block,
                    ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildAppointmentsList(
                          patientState.upcomingAppointments,
                          l10n.appointmentsNoUpcoming,
                          context,
                          ref,
                          showCancel: true,
                        ),
                        _buildAppointmentsList(
                          patientState.pastAppointments,
                          l10n.appointmentsNoPast,
                          context,
                          ref,
                          showCancel: false,
                        ),
                        _buildAppointmentsList(
                          patientState.cancelledAppointments,
                          l10n.appointmentsNoCancelled,
                          context,
                          ref,
                          showCancel: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Widget _buildAppointmentsList(
    List<PatientAppointmentViewModel> appointments,
    String emptyMessage,
    BuildContext context,
    WidgetRef ref, {
    bool showCancel = false,
  }) {
    if (appointments.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(patientProvider.notifier).refreshAppointments(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _AppointmentCard(
              appointment: appointment,
              showCancel: showCancel,
              onCancel: () => _showCancelDialog(context, ref, appointment),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCancelDialog(BuildContext context, WidgetRef ref, PatientAppointmentViewModel appointment) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.doctorAppointmentsCancelAppointment),
        content: Text(l10n.cancelAppointmentConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonNo),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.cancelConfirmYes),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final success = await ref.read(patientProvider.notifier).cancelAppointment(appointment.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? l10n.appointmentCancelled : l10n.cancelAppointmentError),
      ),
    );
  }

  Widget _buildAttendanceRateBar(double rate) {
    final pct = (rate * 100).round();
    final Color barColor;
    if (rate > 0.75) {
      barColor = const Color(0xFF16A34A);
    } else if (rate >= 0.50) {
      barColor = const Color(0xFFD97706);
    } else {
      barColor = const Color(0xFFDC2626);
    }
    final String label;
    if (rate > 0.75) {
      label = 'Bon';
    } else if (rate >= 0.50) {
      label = 'Moyen';
    } else {
      label = 'Faible';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color: barColor.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: barColor, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Fiabilité : $pct% ($label)',
            style: TextStyle(fontSize: 12, color: barColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildNoShowBanner(
    int count,
    Color color,
    Color bgColor,
    IconData icon,
  ) {
    String message;
    if (count >= 3) {
      message = 'Vous avez été absent à $count rendez-vous. Vous ne pouvez plus réserver en ligne. Contactez le cabinet.';
    } else if (count == 2) {
      message = 'Attention : vous avez $count absences non justifiées. Après 3 absences, vous serez bloqué.';
    } else {
      message = 'Note : vous avez $count absence non justifiée.';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color: bgColor,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BottomNavigationBar(
      currentIndex: 2,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go(RouteNames.patientHome);
            break;
          case 1:
            context.push(RouteNames.patientDoctors);
            break;
          case 2:
            break;
          case 3:
            context.push(RouteNames.patientFavorites);
            break;
          case 4:
            context.push(RouteNames.patientProfile);
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      items: [
        BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.navHome),
        BottomNavigationBarItem(icon: const Icon(Icons.search), label: l10n.navDoctors),
        BottomNavigationBarItem(icon: const Icon(Icons.calendar_today), label: l10n.navAppointments),
        BottomNavigationBarItem(icon: const Icon(Icons.favorite), label: l10n.navFavorites),
        BottomNavigationBarItem(icon: const Icon(Icons.person), label: l10n.navProfile),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final PatientAppointmentViewModel appointment;
  final bool showCancel;
  final VoidCallback onCancel;

  const _AppointmentCard({
    required this.appointment,
    required this.showCancel,
    required this.onCancel,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return 'DR';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  _getInitials(appointment.doctorName),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      appointment.doctorSpecialty,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: appointment.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                '${appointment.dateTime.day}/${appointment.dateTime.month}/${appointment.dateTime.year}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 16, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                '${appointment.dateTime.hour.toString().padLeft(2, '0')}:${appointment.dateTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.timer, size: 16, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                '${appointment.duration} min',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              if (appointment.mapsLink != null && appointment.mapsLink!.isNotEmpty ||
                  appointment.doctorPhone != null && appointment.doctorPhone!.isNotEmpty) ...[
                const Spacer(),
                if (appointment.doctorPhone != null && appointment.doctorPhone!.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: appointment.doctorPhone!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.clipboardCopied),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      launchUrl(Uri.parse('tel:${appointment.doctorPhone}'));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone, size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            l10n.bookingCallOffice,
                            style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (appointment.mapsLink != null && appointment.mapsLink!.isNotEmpty)
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse(appointment.mapsLink!), mode: LaunchMode.externalApplication),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, size: 14, color: AppColors.secondary),
                          SizedBox(width: 4),
                          Text(
                            'Ouvrir',
                            style: TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
          if (appointment.isConsultation) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Consultation',
                style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
              ),
            ),
          ],
          if (showCancel && appointment.status != 'cancelled') ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: Text(l10n.appointmentsCancel),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'upcoming':
        bgColor = const Color(0xFFE3F2FD);
        textColor = AppColors.primary;
        label = l10n.appointmentsUpcoming;
        break;
      case 'completed':
        bgColor = const Color(0xFFE8F5E9);
        textColor = AppColors.secondary;
        label = l10n.appointmentsStatusCompleted;
        break;
      case 'cancelled':
        bgColor = const Color(0xFFFFEBEE);
        textColor = AppColors.error;
        label = l10n.appointmentsStatusCancelled;
        break;
      case 'absent':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        label = 'Absent';
        break;
      default:
        bgColor = AppColors.background;
        textColor = AppColors.textSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}