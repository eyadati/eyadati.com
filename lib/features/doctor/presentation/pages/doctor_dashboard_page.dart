import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_breakpoints.dart';
import 'package:eyadati/core/routing/route_names.dart';
import 'package:eyadati/core/theme/text_styles.dart';
import 'package:eyadati/core/utils/supabase_client.dart';
import 'package:eyadati/services/notification_service.dart';
import 'package:eyadati/features/doctor/presentation/pages/doctor_calendar_page.dart';
import 'package:eyadati/features/doctor/presentation/providers/doctor_provider.dart';
import 'package:eyadati/features/doctor/presentation/providers/doctor_call_provider.dart';
import 'package:eyadati/features/doctor/presentation/widgets/doctor_notification_sidebar.dart';
import 'package:eyadati/features/doctor/presentation/widgets/doctor_add_appointment_dialog.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DoctorDashboardPage extends ConsumerStatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  ConsumerState<DoctorDashboardPage> createState() =>
      _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends ConsumerState<DoctorDashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ValueNotifier<DateTime> _selectedDate = ValueNotifier(DateTime.now());
  String? _lastProcessedLogId;
  bool _notificationInitialized = false;
  StreamSubscription? _fcmSubscription;

  void _showAddAppointmentDialog() {
    showDialog(
      context: context,
      builder: (ctx) => DoctorAddAppointmentDialog(
        initialDate: _selectedDate.value,
      ),
    );
  }

  void _initNotificationService() {
    if (_notificationInitialized) return;
    _notificationInitialized = true;

    final isMobile = AppBreakpoints.isMobile(MediaQuery.of(context).size.width);
    notificationService.init(isMobile: isMobile);

    _fcmSubscription = notificationService.onMessage.listen((message) {
      final phone = message.data['phone'];
      final name = message.data['name'] ?? '';
      if (phone == null || phone.isEmpty) return;
      if (!mounted || !AppBreakpoints.isMobile(MediaQuery.of(context).size.width)) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('📞 Call patient'),
          content: Text('Call ${name.isNotEmpty ? name : "patient"} at $phone?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Dismiss')),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                launchUrl(Uri.parse('tel:$phone'));
              },
              child: Text('Call now', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    });
  }

  void _handleIncomingCallLog() {
    final logs = ref.read(callLogProvider).logs;
    if (logs.isEmpty) return;
    final latest = logs.last;
    if (latest.id == _lastProcessedLogId) return;
    _lastProcessedLogId = latest.id;
    if (!AppBreakpoints.isMobile(MediaQuery.of(context).size.width)) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📞 Call patient'),
        content: Text('Call ${latest.patientName ?? "patient"} at ${latest.patientPhone}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Dismiss')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              launchUrl(Uri.parse('tel:${latest.patientPhone}'));
            },
            child: Text('Call now', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initNotificationService();
    });
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allAppointments = ref.watch(doctorProvider.select((s) => s.allAppointments));
    final subscriptionEnd = ref.watch(doctorProvider.select((s) => s.subscriptionEnd));
    final errorMessage = ref.watch(doctorProvider.select((s) => s.errorMessage));
    final isLoading = ref.watch(doctorProvider.select((s) => s.isLoading));
    final pending = allAppointments
        .where((a) => a.status == 'upcoming' && a.bookingType == 'online')
        .toList();

    ref.listen<CallLogState>(callLogProvider, (previous, next) {
      if (next.logs.length > (previous?.logs.length ?? 0)) {
        _handleIncomingCallLog();
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      endDrawer: DoctorNotificationSidebar(appointments: pending),
      body: Column(
        children: [
          if (subscriptionEnd != null && subscriptionEnd.isBefore(DateTime.now()))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.error,
              child: Row(
                children: [
                  const Icon(Icons.block, color: AppColors.white, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Abonnement expiré — Renouvelez pour continuer',
                      style: TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(RouteNames.doctorSubscription),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      backgroundColor: AppColors.white.withValues(alpha: 0.2),
                    ),
                    child: const Text('Renouveler', style: TextStyle(color: AppColors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: errorMessage != null
                ? _buildErrorView(errorMessage)
                : Skeletonizer(
                    enabled: isLoading,
                    child: DoctorCalendarPage(
                      onBellPressed: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
                      selectedDateNotifier: _selectedDate,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= AppBreakpoints.mobile) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            onPressed: _showAddAppointmentDialog,
            backgroundColor: AppColors.primary,
            child: const Icon(LucideIcons.plus, color: Colors.white),
          );
        },
      ),
    );
  }

  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(doctorProvider.notifier).clearError();
                ref.read(doctorProvider.notifier).refresh();
              },
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
