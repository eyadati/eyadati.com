import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/inputs/app_search_field.dart';
import '../../../../core/widgets/cards/empty_state_card.dart';
import '../providers/providers.dart';

class DoctorsBrowsePage extends ConsumerStatefulWidget {
  const DoctorsBrowsePage({super.key});

  @override
  ConsumerState<DoctorsBrowsePage> createState() => _DoctorsBrowsePageState();
}

class _DoctorsBrowsePageState extends ConsumerState<DoctorsBrowsePage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(doctorsProvider.notifier).loadDoctors();
      ref.read(favoritesProvider.notifier).loadFavorites();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(doctorsProvider.notifier).refresh();
    await ref.read(favoritesProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final doctorsState = ref.watch(doctorsProvider);
    final favoritesState = ref.watch(favoritesProvider);

    final filteredDoctors = doctorsState.doctors.where((d) {
      final query = doctorsState.searchQuery.toLowerCase();
      if (query.isEmpty) return true;
      return d.name.toLowerCase().contains(query) ||
          d.specialty.toLowerCase().contains(query) ||
          (d.location?.toLowerCase().contains(query) ?? false);
    }).toList();

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
              controller: _searchController,
              onChanged: (value) {
                ref.read(doctorsProvider.notifier).searchDoctors(value);
              },
            ),
          ),
          Expanded(
            child: doctorsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDoctors.isEmpty
                    ? Center(
                        child: EmptyStateCard(
                          icon: Icons.search_off,
                          title: 'Aucun médecin trouvé',
                          message: 'Essayez une autre recherche',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: filteredDoctors.length,
                          itemBuilder: (context, index) {
                            final doctor = filteredDoctors[index];
                            final isFav = favoritesState.favoriteDoctorIds.contains(doctor.id);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: _DoctorListCard(
                                doctor: doctor,
                                isFavorite: isFav,
                                onTap: () => context.push(
                                  '/patient/doctors/${doctor.id}',
                                ),
                                onFavoriteToggle: () => ref
                                    .read(favoritesProvider.notifier)
                                    .toggleFavorite(doctor.id),
                              ),
                            );
                          },
                        ),
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

class _DoctorListCard extends StatelessWidget {
  final Doctor doctor;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const _DoctorListCard({
    required this.doctor,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
                      const SizedBox(width: 4),
                      Text(
                        doctor.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${doctor.reviewCount})',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      if (doctor.location != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on, size: 12, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Text(
                          doctor.location!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onFavoriteToggle,
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? AppColors.error : AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${doctor.consultationFee.toInt()} MAD',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
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