import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyadati/models/appointment_data.dart';
import 'package:eyadati/models/patient_summary.dart';
import 'package:eyadati/models/patient_note.dart';
import 'package:eyadati/core/utils/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientHistoryState {
  final List<PatientSummary> patients;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;
  final Set<String> expandedPatientIds;
  final Map<String, List<PatientNote>> notesByPatient;
  final Map<String, bool> notesLoading;

  const PatientHistoryState({
    this.patients = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
    this.expandedPatientIds = const {},
    this.notesByPatient = const {},
    this.notesLoading = const {},
  });

  List<PatientSummary> get filteredPatients {
    if (searchQuery.isEmpty) return patients;
    final q = searchQuery.toLowerCase();
    return patients.where((p) {
      return p.patientName.toLowerCase().contains(q) ||
          (p.patientPhone?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  PatientHistoryState copyWith({
    List<PatientSummary>? patients,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    Set<String>? expandedPatientIds,
    Map<String, List<PatientNote>>? notesByPatient,
    Map<String, bool>? notesLoading,
  }) {
    return PatientHistoryState(
      patients: patients ?? this.patients,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      expandedPatientIds: expandedPatientIds ?? this.expandedPatientIds,
      notesByPatient: notesByPatient ?? this.notesByPatient,
      notesLoading: notesLoading ?? this.notesLoading,
    );
  }
}

final patientHistoryProvider =
    StateNotifierProvider<PatientHistoryNotifier, PatientHistoryState>((ref) {
  return PatientHistoryNotifier();
});

class PatientHistoryNotifier extends StateNotifier<PatientHistoryState> {
  RealtimeChannel? _notesChannel;

  PatientHistoryNotifier() : super(const PatientHistoryState()) {
    loadPatients();
  }

  SupabaseClient get _client => SupabaseInitializer.client;

  @override
  void dispose() {
    _notesChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToNotes(String patientId) {
    _notesChannel?.unsubscribe();
    _notesChannel = _client
        .channel('patient_notes_$patientId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'patient_notes',
          callback: (payload) {
            final pid = payload.newRecord['patient_id'] as String?;
            if (pid == patientId) {
              _loadNotesForPatient(patientId);
            }
          },
        )
        .subscribe();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> loadPatients() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final data = await _client
          .from('appointments')
          .select('''
            id,
            scheduled_at,
            duration,
            status,
            is_consultation,
            booking_type,
            notes,
            patient_id,
            patient_name_snapshot,
            patient_phone_snapshot,
            patient:profiles!patient_id (
              id,
              full_name,
              phone,
              avatar_url
            )
          ''')
          .eq('doctor_id', user.id)
          .eq('booking_type', 'online')
          .not('patient_id', 'is', null)
          .order('scheduled_at', ascending: false);

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final row in data as List) {
        final pid = row['patient_id'] as String;
        grouped.putIfAbsent(pid, () => []);
        grouped[pid]!.add(row);
      }

      final summaries = <PatientSummary>[];
      for (final entry in grouped.entries) {
        final rows = entry.value;
        final first = rows.first;
        final patientData = first['patient'] as Map<String, dynamic>?;

        final visits = rows.map((r) {
          final start = DateTime.parse(r['scheduled_at'] as String);
          final dur = r['duration'] as int? ?? 30;
          return AppointmentData(
            id: r['id'] as String,
            startTime: start,
            endTime: start.add(Duration(minutes: dur)),
            patientName: patientData?['full_name'] as String? ??
                (r['patient_name_snapshot'] as String? ?? ''),
            patientAvatar: patientData?['avatar_url'] as String?,
            patientPhone: patientData?['phone'] as String? ??
                (r['patient_phone_snapshot'] as String?),
            status: r['status'] as String,
            isConsultation: r['is_consultation'] as bool? ?? false,
            notes: r['notes'] as String?,
            duration: dur,
            patientId: entry.key,
            bookingType: 'online',
            doctorId: user.id,
          );
        }).toList();

        final lastVisit = rows
            .map((r) => DateTime.parse(r['scheduled_at'] as String))
            .reduce((a, b) => a.isAfter(b) ? a : b);

        summaries.add(PatientSummary(
          patientId: entry.key,
          patientName: patientData?['full_name'] as String? ??
              (first['patient_name_snapshot'] as String? ?? 'Patient'),
          patientPhone: patientData?['phone'] as String? ??
              (first['patient_phone_snapshot'] as String?),
          patientAvatar: patientData?['avatar_url'] as String?,
          visitCount: rows.length,
          lastVisitDate: lastVisit,
          visits: visits,
        ));
      }

      summaries.sort((a, b) => b.lastVisitDate.compareTo(a.lastVisitDate));

      state = state.copyWith(
        patients: summaries,
        isLoading: false,
        expandedPatientIds: {},
        notesByPatient: {},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> toggleExpand(String patientId) async {
    final expanded = Set<String>.from(state.expandedPatientIds);
    if (expanded.contains(patientId)) {
      expanded.remove(patientId);
      state = state.copyWith(expandedPatientIds: expanded);
    } else {
      expanded.add(patientId);
      state = state.copyWith(expandedPatientIds: expanded);
      if (!state.notesByPatient.containsKey(patientId)) {
        _loadNotesForPatient(patientId);
      }
      _subscribeToNotes(patientId);
    }
  }

  Future<void> _loadNotesForPatient(String patientId) async {
    state = state.copyWith(
      notesLoading: {...state.notesLoading, patientId: true},
    );
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final data = await _client
          .from('patient_notes')
          .select('''
            id,
            patient_id,
            doctor_id,
            appointment_id,
            note_text,
            created_at,
            updated_at,
            appointment:appointments!appointment_id (scheduled_at)
          ''')
          .eq('patient_id', patientId)
          .eq('doctor_id', user.id)
          .order('created_at', ascending: false);

      final notes = (data as List).map((row) {
        final appointment = row['appointment'] as Map<String, dynamic>?;
        return PatientNote(
          id: row['id'] as String,
          patientId: row['patient_id'] as String,
          doctorId: row['doctor_id'] as String,
          appointmentId: row['appointment_id'] as String,
          noteText: row['note_text'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          updatedAt: DateTime.parse(row['updated_at'] as String),
          appointmentDate: appointment?['scheduled_at'] as String?,
        );
      }).toList();

      state = state.copyWith(
        notesByPatient: {
          ...state.notesByPatient,
          patientId: notes,
        },
        notesLoading: {...state.notesLoading, patientId: false},
      );
    } catch (e) {
      state = state.copyWith(
        notesLoading: {...state.notesLoading, patientId: false},
      );
    }
  }

  Future<void> addNote({
    required String patientId,
    required String appointmentId,
    required String noteText,
  }) async {
    if (noteText.trim().isEmpty) return;
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      await _client.from('patient_notes').insert({
        'patient_id': patientId,
        'doctor_id': user.id,
        'appointment_id': appointmentId,
        'note_text': noteText.trim(),
      });

      _loadNotesForPatient(patientId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> updateNote({
    required String noteId,
    required String noteText,
    required String patientId,
  }) async {
    if (noteText.trim().isEmpty) return;
    try {
      await _client
          .from('patient_notes')
          .update({
            'note_text': noteText.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', noteId);

      _loadNotesForPatient(patientId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> deleteNote({
    required String noteId,
    required String patientId,
  }) async {
    try {
      await _client.from('patient_notes').delete().eq('id', noteId);
      _loadNotesForPatient(patientId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}
