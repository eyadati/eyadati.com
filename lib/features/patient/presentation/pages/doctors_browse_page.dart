import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/inputs/app_search_field.dart';
import '../../../../core/widgets/cards/empty_state_card.dart';
import '../providers/providers.dart';
import '../widgets/doctor_card.dart';

class DoctorsBrowsePage extends ConsumerWidget {
  const DoctorsBrowsePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsState = ref.watch(doctorsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tous les médecins'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: AppSearchField(
              hint: 'Spécialité, nom du médecin...',
              controller: TextEditingController(),
              onChanged: (value) {
                ref.read(doctorsProvider.notifier).searchDoctors(value);
              },
            ),
          ),
          if (doctorsState.isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (doctorsState.doctors.isEmpty)
            Expanded(
              child: Center(
                child: EmptyStateCard(
                  icon: Icons.search_off,
                  title: 'Aucun médecin trouvé',
                  message: 'Essayez une autre recherche',
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: doctorsState.doctors.length,
                itemBuilder: (context, index) {
                  final doctor = doctorsState.doctors[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: DoctorCard(
                      doctor: doctor,
                      onTap: () => context.push(
                        '/patient/doctors/${doctor.id}',
                      ),
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

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 1,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go(RouteNames.patientHome);
            break;
          case 1:
            break;
          case 2:
            context.push(RouteNames.patientAppointments);
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
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Docteurs'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Rendez-vous'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoris'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
    );
  }
}