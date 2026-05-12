class AppAuthState {
  final bool isAuthenticated;
  final bool isDoctor;
  final bool isLoading;
  final String? errorMessage;
  final String? userId;
  final String? email;
  final String? role;

  const AppAuthState({
    this.isAuthenticated = false,
    this.isDoctor = false,
    this.isLoading = false,
    this.errorMessage,
    this.userId,
    this.email,
    this.role,
  });

  AppAuthState copyWith({
    bool? isAuthenticated,
    bool? isDoctor,
    bool? isLoading,
    String? errorMessage,
    String? userId,
    String? email,
    String? role,
  }) {
    return AppAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isDoctor: isDoctor ?? this.isDoctor,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }
}