import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyadati/models/doctor.dart';
import 'package:eyadati/services/providers.dart';

final doctorsProvider = FutureProvider.family<List<Doctor>, DoctorFilter>((ref, filter) async {
  final repository = ref.watch(doctorRepositoryProvider);
  return repository.getActiveDoctors(
    specialty: filter.specialty,
    city: filter.city,
    searchQuery: filter.searchQuery,
  );
});

final activeDoctorsProvider = FutureProvider<List<Doctor>>((ref) async {
  final repository = ref.watch(doctorRepositoryProvider);
  return repository.getActiveDoctors();
});

final doctorProvider = FutureProvider.family<Doctor?, String>((ref, doctorId) async {
  final repository = ref.watch(doctorRepositoryProvider);
  return repository.getDoctor(doctorId);
});

final myDoctorProfileProvider = FutureProvider<Doctor?>((ref) async {
  final repository = ref.watch(doctorRepositoryProvider);
  final profileAsync = ref.watch(currentProfileDataProvider);
  
  final profile = profileAsync.valueOrNull;
  if (profile == null) return null;
  if (profile['role'] != 'doctor') return null;
  
  return repository.getMyDoctorProfile(profile['id'] as String);
});

final specialtiesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(doctorRepositoryProvider);
  return repository.getSpecialties();
});

final citiesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(doctorRepositoryProvider);
  return repository.getCities();
});

class DoctorFilter {
  final String? specialty;
  final String? city;
  final String? searchQuery;

  DoctorFilter({this.specialty, this.city, this.searchQuery});
}