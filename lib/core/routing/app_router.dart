import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/select_role_page.dart';
import '../../features/patient/presentation/pages/patient_home_page.dart';
import '../../features/patient/presentation/pages/doctors_browse_page.dart';
import '../../features/patient/presentation/pages/doctor_details_page.dart';
import '../../features/patient/presentation/pages/booking_page.dart';
import '../../features/patient/presentation/pages/patient_appointments_page.dart';
import '../../features/patient/presentation/pages/favorites_page.dart';
import '../../features/patient/presentation/pages/patient_profile_page.dart';
import '../../features/doctor/presentation/pages/doctor_dashboard_page.dart';
import '../../features/doctor/presentation/pages/doctor_schedule_page.dart';
import '../../features/doctor/presentation/pages/doctor_appointments_page.dart';
import '../../features/doctor/presentation/pages/doctor_profile_page.dart';
import '../../features/doctor/presentation/pages/doctor_subscription_page.dart';
import '../../features/doctor/presentation/pages/doctor_settings_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == RouteNames.login ||
          state.matchedLocation == RouteNames.register ||
          state.matchedLocation == RouteNames.forgotPassword ||
          state.matchedLocation == RouteNames.selectRole ||
          state.matchedLocation == RouteNames.splash;

      if (!isLoggedIn && !isAuthRoute) {
        return RouteNames.login;
      }

      if (isLoggedIn && isAuthRoute) {
        return authState.isDoctor ? RouteNames.doctorDashboard : RouteNames.patientHome;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: RouteNames.selectRole,
        builder: (context, state) => const SelectRolePage(),
      ),
      GoRoute(
        path: RouteNames.patientHome,
        builder: (context, state) => const PatientHomePage(),
      ),
      GoRoute(
        path: RouteNames.patientDoctors,
        builder: (context, state) => const DoctorsBrowsePage(),
      ),
      GoRoute(
        path: RouteNames.patientDoctorDetails,
        builder: (context, state) => DoctorDetailsPage(
          doctorId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RouteNames.patientBookAppointment,
        builder: (context, state) => BookingPage(
          doctorId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RouteNames.patientAppointments,
        builder: (context, state) => const PatientAppointmentsPage(),
      ),
      GoRoute(
        path: RouteNames.patientFavorites,
        builder: (context, state) => const FavoritesPage(),
      ),
      GoRoute(
        path: RouteNames.patientProfile,
        builder: (context, state) => const PatientProfilePage(),
      ),
      GoRoute(
        path: RouteNames.doctorDashboard,
        builder: (context, state) => const DoctorDashboardPage(),
      ),
      GoRoute(
        path: RouteNames.doctorSchedule,
        builder: (context, state) => const DoctorSchedulePage(),
      ),
      GoRoute(
        path: RouteNames.doctorAppointments,
        builder: (context, state) => const DoctorAppointmentsPage(),
      ),
      GoRoute(
        path: RouteNames.doctorProfile,
        builder: (context, state) => const DoctorProfilePage(),
      ),
      GoRoute(
        path: RouteNames.doctorSubscription,
        builder: (context, state) => const DoctorSubscriptionPage(),
      ),
      GoRoute(
        path: RouteNames.doctorSettings,
        builder: (context, state) => const DoctorSettingsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});