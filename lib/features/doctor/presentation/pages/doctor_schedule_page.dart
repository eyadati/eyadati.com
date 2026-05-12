import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadati/core/routing/route_names.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_spacing.dart';
import 'package:eyadati/core/widgets/cards/empty_state_card.dart';
import '../providers/doctor_provider.dart';
import '../widgets/schedule_slot_card.dart';
import '../widgets/add_schedule_dialog.dart';

class DoctorSchedulePage extends ConsumerStatefulWidget {
  const DoctorSchedulePage({super.key});

  @override
  ConsumerState<DoctorSchedulePage> createState() => _DoctorSchedulePageState();
}

class _DoctorSchedulePageState extends ConsumerState<DoctorSchedulePage> {
  int _selectedDay = DateTime.now().weekday % 7;
  bool _isLoading = false;

  final List<String> _days = [
    'Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'
  ];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    await ref.read(doctorProvider.notifier).loadScheduleForDay(_selectedDay);
    setState(() => _isLoading = false);
  }

  void _showAddSlotDialog() {
    showDialog(
      context: context,
      builder: (context) => AddScheduleDialog(
        doctorId: ref.read(doctorProvider).userId ?? '',
        initialDay: _selectedDay,
        onSave: (day, start, end) async {
          await ref.read(doctorProvider.notifier).addScheduleSlot(
            dayOfWeek: day,
            startTime: start,
            endTime: end,
          );
          await _loadSchedule();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon planning'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.card,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    'Jours de travail',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final hasSlots = doctorState.scheduleSlots
                          .where((s) => s.dayOfWeek == index)
                          .isNotEmpty;
                      final isSelected = _selectedDay == index;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedDay = index);
                            _loadSchedule();
                          },
                          child: Container(
                            width: 48,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppColors.primary 
                                  : hasSlots 
                                      ? AppColors.secondary.withValues(alpha: 0.1)
                                      : AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hasSlots && !isSelected 
                                    ? AppColors.secondary 
                                    : Colors.transparent,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _days[index],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected 
                                        ? Colors.white 
                                        : hasSlots 
                                            ? AppColors.secondary 
                                            : AppColors.textSecondary,
                                  ),
                                ),
                                if (hasSlots) ...[
                                  const SizedBox(height: 2),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? Colors.white 
                                          : AppColors.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getDayFullName(_selectedDay),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddSlotDialog,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : doctorState.scheduleSlots.isEmpty
                    ? Center(
                        child: EmptyStateCard(
                          icon: Icons.schedule,
                          title: 'Aucun créneau',
                          message: 'Ajoutez vos horaires pour $_selectedDay',
                          actionLabel: 'Ajouter un créneau',
                          onAction: _showAddSlotDialog,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        itemCount: doctorState.scheduleSlots.length,
                        itemBuilder: (context, index) {
                          final slot = doctorState.scheduleSlots[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: ScheduleSlotCard(
                              slot: slot,
                              onEdit: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AddScheduleDialog(
                                    doctorId: slot.doctorId,
                                    initialDay: slot.dayOfWeek,
                                    initialStartTime: slot.startTime,
                                    initialEndTime: slot.endTime,
                                    existingSlot: slot,
                                    onSave: (day, start, end) async {
                                      await ref.read(doctorProvider.notifier).updateScheduleSlot(
                                        slotId: slot.id,
                                        startTime: start,
                                        endTime: end,
                                      );
                                      await _loadSchedule();
                                    },
                                  ),
                                );
                              },
                              onDelete: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Supprimer'),
                                    content: const Text('Voulez-vous supprimer ce créneau ?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Annuler'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.error,
                                        ),
                                        child: const Text('Supprimer'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref.read(doctorProvider.notifier).deleteScheduleSlot(slot.id);
                                  await _loadSchedule();
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  String _getDayFullName(int day) {
    const days = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
    return days[day];
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 1,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go(RouteNames.doctorDashboard);
            break;
          case 1:
            break;
          case 2:
            context.push(RouteNames.doctorAppointments);
            break;
          case 3:
            context.push(RouteNames.doctorProfile);
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Tableau'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Planning'),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Rendez-vous'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
    );
  }
}