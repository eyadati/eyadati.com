class AppAuthState {
  final bool isAuthenticated;
  final bool isDoctor;
  final bool isLoading;
  final bool isInitialized;
  final bool setupCompleted;
  final String? errorMessage;
  final String? userId;
  final String? email;
  final String? role;
  final String? userName;

  const AppAuthState({
    this.isAuthenticated = false,
    this.isDoctor = false,
    this.isLoading = false,
    this.isInitialized = false,
    this.setupCompleted = false,
    this.errorMessage,
    this.userId,
    this.email,
    this.role,
    this.userName,
  });

  AppAuthState copyWith({
    bool? isAuthenticated,
    bool? isDoctor,
    bool? isLoading,
    bool? isInitialized,
    bool? setupCompleted,
    String? errorMessage,
    String? userId,
    String? email,
    String? role,
    String? userName,
  }) {
    return AppAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isDoctor: isDoctor ?? this.isDoctor,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      setupCompleted: setupCompleted ?? this.setupCompleted,
      errorMessage: errorMessage,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      role: role ?? this.role,
      userName: userName ?? this.userName,
    );
  }
}
