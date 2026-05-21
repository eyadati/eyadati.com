import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/cards/empty_state_card.dart';
import '../providers/providers.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(favoritesProvider.notifier).loadFavorites());
  }

  @override
  Widget build(BuildContext context) {
    final favoritesState = ref.watch(favoritesProvider);
    final doctorsState = ref.watch(doctorsProvider);

    final favoriteDoctors = doctorsState.doctors
        .where((d) => favoritesState.favoriteDoctorIds.contains(d.id))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes favoris'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: favoritesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteDoctors.isEmpty
              ? Center(
                  child: EmptyStateCard(
                    icon: Icons.favorite_border,
                    title: 'Aucun favori',
                    message: 'Ajoutez des médecins à vos favoris',
                    actionLabel: 'Parcourir les médecins',
                    onAction: () => context.push(RouteNames.patientDoctors),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: favoriteDoctors.length,
                  itemBuilder: (context, index) {
                    final doctor = favoriteDoctors[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _FavoriteDoctorCard(
                        doctor: doctor,
                        onTap: () => context.push('/patient/doctors/${doctor.id}'),
                        onRemove: () => ref.read(favoritesProvider.notifier).toggleFavorite(doctor.id),
                      ),
                    );
                  },
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
            context.go(RouteNames.patientHome);
            break;
          case 1:
            context.push(RouteNames.patientDoctors);
            break;
          case 2:
            context.push(RouteNames.patientAppointments);
            break;
          case 3:
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

class _FavoriteDoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteDoctorCard({
    required this.doctor,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                doctor.name.length > 4 ? doctor.name.substring(4, 6) : 'DR',
                style: const TextStyle(
                  fontSize: 16,
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
                    doctor.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    doctor.specialty,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (doctor.city != null) ...[
                        const Icon(Icons.location_on, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          doctor.city!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.favorite, color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }
}