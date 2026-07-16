import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyadati/core/utils/supabase_client.dart';

class PatientSearchResult {
  final String patientId;
  final String fullName;
  final String? phone;
  final int totalVisits;
  final int noShowCount;
  final int? reliabilityPct;

  PatientSearchResult({
    required this.patientId,
    required this.fullName,
    this.phone,
    this.totalVisits = 0,
    this.noShowCount = 0,
    this.reliabilityPct,
  });

  bool get hasSufficientHistory => totalVisits >= 3;
  double? get reliabilityRate => reliabilityPct != null ? reliabilityPct! / 100 : null;
}

class GlobalPatientSearchState {
  final String query;
  final List<PatientSearchResult> results;
  final bool isLoading;
  final String? errorMessage;

  const GlobalPatientSearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.errorMessage,
  });
}

class GlobalPatientSearchNotifier extends StateNotifier<GlobalPatientSearchState> {
  Timer? _debounce;
  int _requestId = 0;

  GlobalPatientSearchNotifier() : super(const GlobalPatientSearchState());

  void search(String query) {
    _debounce?.cancel();

    if (query.trim().length < 2) {
      state = GlobalPatientSearchState(query: query);
      return;
    }

    state = GlobalPatientSearchState(query: query, isLoading: true);

    final currentRequestId = ++_requestId;

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      await _performSearch(query.trim(), currentRequestId);
    });
  }

  void retry(String query) {
    search(query);
  }

  Future<void> _performSearch(String searchTerm, int requestId) async {
    try {
      final data = await SupabaseInitializer.client.rpc(
        'search_patients',
        params: {'search_term': searchTerm},
      );

      if (requestId < _requestId) return;

      final results = (data as List).map((row) {
        return PatientSearchResult(
          patientId: row['patient_id'] as String,
          fullName: row['full_name'] as String? ?? '',
          phone: row['phone'] as String?,
          totalVisits: (row['total_visits'] as num?)?.toInt() ?? 0,
          noShowCount: (row['no_show_count'] as num?)?.toInt() ?? 0,
          reliabilityPct: (row['reliability_pct'] as num?)?.toInt(),
        );
      }).toList();

      if (requestId < _requestId) return;

      state = GlobalPatientSearchState(query: searchTerm, results: results);
    } catch (e) {
      if (requestId < _requestId) return;

      state = GlobalPatientSearchState(
        query: searchTerm,
        results: state.results,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final globalPatientSearchProvider = StateNotifierProvider<GlobalPatientSearchNotifier, GlobalPatientSearchState>((ref) {
  return GlobalPatientSearchNotifier();
});
