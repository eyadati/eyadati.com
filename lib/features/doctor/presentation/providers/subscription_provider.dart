import 'dart:html' as html;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyadati/core/utils/supabase_client.dart';
import 'package:eyadati/models/payment_history.dart';

class SubscriptionState {
  final DateTime? subscriptionEnd;
  final PaymentHistory? lastPayment;
  final String? planType;
  final bool isLoading;
  final bool isCreatingCheckout;
  final String? error;
  final String? checkoutUrl;

  const SubscriptionState({
    this.subscriptionEnd,
    this.lastPayment,
    this.planType,
    this.isLoading = false,
    this.isCreatingCheckout = false,
    this.error,
    this.checkoutUrl,
  });

  bool get isActive => subscriptionEnd != null && subscriptionEnd!.isAfter(DateTime.now());

  int get remainingDays {
    if (subscriptionEnd == null) return 0;
    final diff = subscriptionEnd!.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inDays;
  }

  String get statusLabel {
    if (subscriptionEnd == null) return 'Aucun abonnement';
    if (!isActive) return 'Expiré';
    if (remainingDays <= 7) return 'Expire bientôt';
    return 'Actif';
  }

  SubscriptionState copyWith({
    DateTime? subscriptionEnd,
    PaymentHistory? lastPayment,
    String? planType,
    bool? isLoading,
    bool? isCreatingCheckout,
    String? error,
    String? checkoutUrl,
  }) {
    return SubscriptionState(
      subscriptionEnd: subscriptionEnd ?? this.subscriptionEnd,
      lastPayment: lastPayment ?? this.lastPayment,
      planType: planType ?? this.planType,
      isLoading: isLoading ?? this.isLoading,
      isCreatingCheckout: isCreatingCheckout ?? this.isCreatingCheckout,
      error: error,
      checkoutUrl: checkoutUrl,
    );
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(const SubscriptionState()) {
    loadSubscription();
  }

  Future<void> loadSubscription() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = SupabaseInitializer.client.auth.currentUser;
      if (user == null) {
        state = state.copyWith(isLoading: false, error: 'Non authentifié');
        return;
      }

      final doctorResponse = await SupabaseInitializer.client
          .from('doctors')
          .select('subscription_end, plan_type')
          .eq('id', user.id)
          .maybeSingle();

      DateTime? subEnd;
      String? planType;
      if (doctorResponse != null) {
        if (doctorResponse['subscription_end'] != null) {
          subEnd = DateTime.parse(doctorResponse['subscription_end'] as String);
        }
        planType = doctorResponse['plan_type'] as String?;
      }

      PaymentHistory? lastPayment;
      final paymentResponse = await SupabaseInitializer.client
          .from('payment_history')
          .select()
          .eq('doctor_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (paymentResponse != null) {
        lastPayment = PaymentHistory.fromDatabase(paymentResponse);
      }

      state = state.copyWith(
        isLoading: false,
        subscriptionEnd: subEnd,
        planType: planType,
        lastPayment: lastPayment,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement: ${e.toString()}',
      );
    }
  }

  Future<String?> createCheckout({
    String? successUrl,
    String? failureUrl,
    String planType = 'monthly',
  }) async {
    state = state.copyWith(isCreatingCheckout: true, error: null, checkoutUrl: null);
    try {
      final session = SupabaseInitializer.client.auth.currentSession;
      if (session == null) {
        state = state.copyWith(
          isCreatingCheckout: false,
          error: 'Non authentifié',
        );
        return null;
      }

      final user = SupabaseInitializer.client.auth.currentUser!;
      final origin = html.window.location.origin;
      final baseUrl =
          successUrl?.replaceAll('/payment/success', '') ?? origin;

      final response = await SupabaseInitializer.client.functions.invoke(
        'create-checkout',
        body: {
          'doctor_id': user.id,
          'plan_type': planType,
          'success_url': successUrl ?? '$baseUrl/payment/success',
          'failure_url': failureUrl ?? '$baseUrl/payment/failure',
        },
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );

      final data = response.data as Map<String, dynamic>;
      final checkoutUrl = data['checkout_url'] as String?;

      if (checkoutUrl == null) {
        state = state.copyWith(
          isCreatingCheckout: false,
          error: 'Impossible de créer le paiement',
        );
        return null;
      }

      state = state.copyWith(
        isCreatingCheckout: false,
        checkoutUrl: checkoutUrl,
      );

      return checkoutUrl;
    } catch (e) {
      state = state.copyWith(
        isCreatingCheckout: false,
        error: 'Erreur: ${e.toString()}',
      );
      return null;
    }
  }

  void clearCheckoutUrl() {
    state = state.copyWith(checkoutUrl: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
