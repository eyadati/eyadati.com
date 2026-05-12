import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/buttons/icon_button_tile.dart';
import '../providers/providers.dart';

class DoctorProfilePage extends ConsumerWidget {
  const DoctorProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorState = ref.watch(doctorProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      doctorState.name.isNotEmpty 
                          ? doctorState.name.substring(0, 2).toUpperCase() 
                          : 'DR',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    doctorState.name.isNotEmpty ? doctorState.name : 'Docteur',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    doctorState.specialty.isNotEmpty ? doctorState.specialty : 'Spécialité',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(label: 'Patients', value: '${doctorState.totalPatients}'),
                      _StatItem(label: 'Rendez-vous', value: '${doctorState.weekAppointments}'),
                      _StatItem(label: 'Revenus', value: '${doctorState.earnings} MAD'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            IconButtonTile(
              title: 'Modifier le profil',
              icon: Icons.edit_outlined,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.sm),
            IconButtonTile(
              title: 'Services et tarifs',
              icon: Icons.attach_money,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.sm),
            IconButtonTile(
              title: 'Horaires de travail',
              icon: Icons.schedule,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.sm),
            IconButtonTile(
              title: 'Abonnement',
              icon: Icons.card_membership,
              onTap: () => context.push(RouteNames.doctorSubscription),
            ),
            const SizedBox(height: AppSpacing.sm),
            IconButtonTile(
              title: 'Paramètres',
              icon: Icons.settings_outlined,
              onTap: () => context.push(RouteNames.doctorSettings),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.logout),
              label: const Text('Déconnexion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 3,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go(RouteNames.doctorDashboard);
            break;
          case 1:
            context.push(RouteNames.doctorSchedule);
            break;
          case 2:
            context.push(RouteNames.doctorAppointments);
            break;
          case 3:
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}