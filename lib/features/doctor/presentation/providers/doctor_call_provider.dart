import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eyadati/core/utils/supabase_client.dart';
import 'package:eyadati/models/call_log.dart';

class CallLogState {
  final List<CallLog> logs;
  final bool isLoading;
  final String? error;

  const CallLogState({
    this.logs = const [],
    this.isLoading = false,
    this.error,
  });

  CallLogState copyWith({
    List<CallLog>? logs,
    bool? isLoading,
    String? error,
  }) {
    return CallLogState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final callLogProvider = StateNotifierProvider<CallLogNotifier, CallLogState>((ref) {
  return CallLogNotifier();
});

class CallLogNotifier extends StateNotifier<CallLogState> {
  RealtimeChannel? _channel;
  StreamSubscription? _authSubscription;

  SupabaseClient get _client => SupabaseInitializer.client;

  CallLogNotifier() : super(const CallLogState()) {
    _init();
  }

  void _init() {
    final user = _client.auth.currentUser;
    if (user != null) {
      _subscribe(user.id);
    }
    _authSubscription = _client.auth.onAuthStateChange.listen((data) {
      if (data.session?.user != null) {
        _subscribe(data.session!.user.id);
      } else {
        _unsubscribe();
      }
    });
  }

  void _subscribe(String userId) {
    _unsubscribe();
    _channel = _client
        .channel('call_logs_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'call_logs',
          callback: (payload) {
            final record = payload.newRecord;
            final log = CallLog.fromJson(record);
            state = state.copyWith(logs: [...state.logs, log]);
          },
        )
        .subscribe();
  }

  void _unsubscribe() {
    _channel?.unsubscribe();
    _channel = null;
  }

  Future<void> requestCall({
    required String patientPhone,
    String? patientName,
    String? patientId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      await _client.from('call_logs').insert({
        'doctor_id': user.id,
        'patient_phone': patientPhone,
        'patient_name': patientName,
        'patient_id': patientId,
      });
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _unsubscribe();
    _authSubscription?.cancel();
    super.dispose();
  }
}
