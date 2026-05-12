import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/doctor.dart';

class DoctorRepository {
  final SupabaseClient _client;

  DoctorRepository(this._client);

  Future<List<Doctor>> getActiveDoctors({
    String? specialty,
    String? city,
    String? searchQuery,
    int? limit,
  }) async {
    try {
      var query = _client
          .from('doctors')
          .select()
          .eq('manual_pause', false)
          .gt('subscription_end', DateTime.now().toIso8601String());

      if (specialty != null && specialty.isNotEmpty) {
        query = query.ilike('specialty', '%$specialty%');
      }

      if (city != null && city.isNotEmpty) {
        query = query.ilike('city', '%$city%');
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('specialty.ilike.%$searchQuery%,address.ilike.%$searchQuery%,bio.ilike.%$searchQuery%');
      }

      final response = await query.order('created_at', ascending: false);

      if (limit != null) {
        return (response as List)
            .take(limit)
            .map((json) => Doctor.fromDatabase(json))
            .toList();
      }

      return (response as List)
          .map((json) => Doctor.fromDatabase(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Doctor?> getDoctor(String doctorId) async {
    try {
      final response = await _client
          .from('doctors')
          .select()
          .eq('id', doctorId)
          .maybeSingle();

      if (response == null) return null;
      return Doctor.fromDatabase(response);
    } catch (e) {
      return null;
    }
  }

  Future<Doctor?> getMyDoctorProfile(String userId) async {
    try {
      final response = await _client
          .from('doctors')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return Doctor.fromDatabase(response);
    } catch (e) {
      return null;
    }
  }

  Future<DoctorResult> createDoctorProfile({
    required String userId,
    required String specialty,
    required String address,
    String? city,
    String? mapsLink,
    String? bio,
    int appointmentDuration = 20,
    int consultationDuration = 40,
    int openingAt = 9,
    int closingAt = 17,
    int? breakStart,
    int? breakEnd,
    List<String> workingDays = const ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'],
  }) async {
    try {
      final data = {
        'id': userId,
        'specialty': specialty,
        'address': address,
        'city': city,
        'maps_link': mapsLink,
        'bio': bio,
        'appointment_duration': appointmentDuration,
        'consultation_duration': consultationDuration,
        'opening_at': openingAt,
        'closing_at': closingAt,
        'break_start': breakStart,
        'break_end': breakEnd,
        'working_days': workingDays,
        'subscription_end': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      };

      final response = await _client
          .from('doctors')
          .insert(data)
          .select()
          .maybeSingle();

      if (response == null) {
        return DoctorResult.failure('Failed to create doctor profile');
      }

      return DoctorResult.success(Doctor.fromDatabase(response));
    } catch (e) {
      return DoctorResult.failure('Failed to create doctor profile');
    }
  }

  Future<DoctorResult> updateDoctorProfile({
    required String doctorId,
    String? specialty,
    String? address,
    String? city,
    String? mapsLink,
    double? latitude,
    double? longitude,
    String? bio,
    String? photoUrl,
    int? appointmentDuration,
    int? consultationDuration,
    int? openingAt,
    int? closingAt,
    int? breakStart,
    int? breakEnd,
    List<String>? workingDays,
    bool? manualPause,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (specialty != null) updates['specialty'] = specialty;
      if (address != null) updates['address'] = address;
      if (city != null) updates['city'] = city;
      if (mapsLink != null) updates['maps_link'] = mapsLink;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;
      if (bio != null) updates['bio'] = bio;
      if (photoUrl != null) updates['photo_url'] = photoUrl;
      if (appointmentDuration != null) {
        updates['appointment_duration'] = appointmentDuration;
      }
      if (consultationDuration != null) {
        updates['consultation_duration'] = consultationDuration;
      }
      if (openingAt != null) updates['opening_at'] = openingAt;
      if (closingAt != null) updates['closing_at'] = closingAt;
      if (breakStart != null) updates['break_start'] = breakStart;
      if (breakEnd != null) updates['break_end'] = breakEnd;
      if (workingDays != null) updates['working_days'] = workingDays;
      if (manualPause != null) updates['manual_pause'] = manualPause;

      if (updates.isEmpty) {
        return DoctorResult.failure('No fields to update');
      }

      final response = await _client
          .from('doctors')
          .update(updates)
          .eq('id', doctorId)
          .select()
          .maybeSingle();

      if (response == null) {
        return DoctorResult.failure('Failed to update doctor profile');
      }

      return DoctorResult.success(Doctor.fromDatabase(response));
    } catch (e) {
      return DoctorResult.failure('Failed to update doctor profile');
    }
  }

  Future<bool> pauseProfile(String doctorId, bool pause) async {
    try {
      await _client
          .from('doctors')
          .update({'manual_pause': pause})
          .eq('id', doctorId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getSpecialties() async {
    try {
      final response = await _client
          .from('doctors')
          .select('specialty')
          .eq('manual_pause', false)
          .gt('subscription_end', DateTime.now().toIso8601String());

      final specialties = (response as List)
          .map((e) => e['specialty'] as String)
          .toSet()
          .toList();
      specialties.sort();
      return specialties;
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> getCities() async {
    try {
      final response = await _client
          .from('doctors')
          .select('city')
          .eq('manual_pause', false)
          .gt('subscription_end', DateTime.now().toIso8601String());

      final cities = (response as List)
          .map((e) => e['city'] as String?)
          .where((city) => city != null && city.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      cities.sort();
      return cities;
    } catch (e) {
      return [];
    }
  }
}

class DoctorResult {
  final bool isSuccess;
  final Doctor? doctor;
  final String? error;

  DoctorResult._({
    required this.isSuccess,
    this.doctor,
    this.error,
  });

  factory DoctorResult.success(Doctor doctor) {
    return DoctorResult._(isSuccess: true, doctor: doctor);
  }

  factory DoctorResult.failure(String error) {
    return DoctorResult._(isSuccess: false, error: error);
  }
}
