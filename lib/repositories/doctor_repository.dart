import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/doctor.dart';
import '../core/utils/input_validator.dart';
import '../core/utils/security_validator.dart';

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
        final sanitizedSpecialty = SecurityValidator.sanitizeHtml(specialty.trim());
        query = query.ilike('specialty', '%$sanitizedSpecialty%');
      }

      if (city != null && city.isNotEmpty) {
        final sanitizedCity = SecurityValidator.sanitizeHtml(city.trim());
        query = query.ilike('city', '%$sanitizedCity%');
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final sanitizedQuery = SecurityValidator.sanitizeHtml(searchQuery.trim());
        query = query.or('specialty.ilike.%$sanitizedQuery%,address.ilike.%$sanitizedQuery%,bio.ilike.%$sanitizedQuery%');
      }

      final response = await query.order('created_at', ascending: false);

      if (limit != null && limit > 0) {
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
      if (!SecurityValidator.isValidUuid(doctorId)) {
        return null;
      }

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
      if (!SecurityValidator.isValidUuid(userId)) {
        return null;
      }

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
      if (!SecurityValidator.isValidUuid(userId)) {
        return DoctorResult.failure('Invalid user ID');
      }

      final specialtyError = InputValidator.validateRequired(specialty, 'Specialty');
      if (specialtyError != null) {
        return DoctorResult.failure(specialtyError);
      }

      final addressError = InputValidator.validateRequired(address, 'Address');
      if (addressError != null) {
        return DoctorResult.failure(addressError);
      }

      final hoursError = InputValidator.validateWorkingHours(openingAt, closingAt);
      if (hoursError != null) {
        return DoctorResult.failure(hoursError);
      }

      final durationError = InputValidator.validateDuration(appointmentDuration);
      if (durationError != null) {
        return DoctorResult.failure(durationError);
      }

      final bioError = InputValidator.validateBio(bio);
      if (bioError != null) {
        return DoctorResult.failure(bioError);
      }

      final data = {
        'id': userId,
        'specialty': SecurityValidator.sanitizeHtml(specialty.trim()),
        'address': SecurityValidator.sanitizeHtml(address.trim()),
        'city': city?.trim(),
        'maps_link': mapsLink?.trim(),
        'bio': bio?.trim(),
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
    required String userId,
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
      if (!SecurityValidator.isValidUuid(doctorId)) {
        return DoctorResult.failure('Invalid doctor ID');
      }

      if (!SecurityValidator.isValidDoctorOwnership(userId, doctorId)) {
        return DoctorResult.failure('You can only update your own profile');
      }

      final updates = <String, dynamic>{};
      
      if (specialty != null) {
        final specialtyError = InputValidator.validateRequired(specialty, 'Specialty');
        if (specialtyError != null) {
          return DoctorResult.failure(specialtyError);
        }
        updates['specialty'] = SecurityValidator.sanitizeHtml(specialty.trim());
      }
      
      if (address != null) {
        final addressError = InputValidator.validateRequired(address, 'Address');
        if (addressError != null) {
          return DoctorResult.failure(addressError);
        }
        updates['address'] = SecurityValidator.sanitizeHtml(address.trim());
      }
      
      if (city != null) {
        final cityError = InputValidator.validateCity(city);
        if (cityError != null) {
          return DoctorResult.failure(cityError);
        }
        updates['city'] = city.trim();
      }
      
      if (mapsLink != null) {
        updates['maps_link'] = mapsLink.trim();
      }
      
      if (latitude != null) {
        updates['latitude'] = latitude;
      }
      
      if (longitude != null) {
        updates['longitude'] = longitude;
      }
      
      if (bio != null) {
        final bioError = InputValidator.validateBio(bio);
        if (bioError != null) {
          return DoctorResult.failure(bioError);
        }
        updates['bio'] = bio.trim();
      }
      
      if (photoUrl != null) {
        updates['photo_url'] = photoUrl.trim();
      }
      
      if (appointmentDuration != null) {
        final durationError = InputValidator.validateDuration(appointmentDuration);
        if (durationError != null) {
          return DoctorResult.failure(durationError);
        }
        updates['appointment_duration'] = appointmentDuration;
      }
      
      if (consultationDuration != null) {
        final durationError = InputValidator.validateDuration(consultationDuration);
        if (durationError != null) {
          return DoctorResult.failure(durationError);
        }
        updates['consultation_duration'] = consultationDuration;
      }
      
      if (openingAt != null || closingAt != null) {
        final hoursError = InputValidator.validateWorkingHours(
          openingAt ?? 9,
          closingAt ?? 17,
        );
        if (hoursError != null) {
          return DoctorResult.failure(hoursError);
        }
        if (openingAt != null) updates['opening_at'] = openingAt;
        if (closingAt != null) updates['closing_at'] = closingAt;
      }
      
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

  Future<DoctorResult> pauseProfile(String doctorId, String userId, bool pause) async {
    try {
      if (!SecurityValidator.isValidUuid(doctorId)) {
        return DoctorResult.failure('Invalid doctor ID');
      }

      if (!SecurityValidator.isValidDoctorOwnership(userId, doctorId)) {
        return DoctorResult.failure('You can only pause your own profile');
      }

      await _client
          .from('doctors')
          .update({'manual_pause': pause})
          .eq('id', doctorId);
      
      return DoctorResult.success(Doctor(
        id: doctorId,
        specialty: '',
        address: '',
        manualPause: pause,
      ));
    } catch (e) {
      return DoctorResult.failure('Failed to pause profile');
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
