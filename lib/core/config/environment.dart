class Environment {
  final String name;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool enableLogging;
  final bool enableDebugMode;
  final String apiUrl;

  const Environment({
    required this.name,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.enableLogging = false,
    this.enableDebugMode = false,
    this.apiUrl = '',
  });

  bool get isProduction => name == 'production';
  bool get isStaging => name == 'staging';
  bool get isDevelopment => name == 'development';
}

class Environments {
  static const Environment development = Environment(
    name: 'development',
    supabaseUrl: 'http://localhost:54321',
    supabaseAnonKey: 'your-local-anon-key',
    enableLogging: true,
    enableDebugMode: true,
  );

  static const Environment staging = Environment(
    name: 'staging',
    supabaseUrl: 'https://your-staging-project.supabase.co',
    supabaseAnonKey: 'your-staging-anon-key',
    enableLogging: true,
    enableDebugMode: false,
  );

  static const Environment production = Environment(
    name: 'production',
    supabaseUrl: 'https://erkldarqweehvwgpncrg.supabase.co',
    supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVya2xkYXJxd2VlaHZ3Z3BuY3JnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5MTIyMDgsImV4cCI6MjA3NzQ4ODIwOH0.rQPh6hFnn6sz78rLa8_AWU3NV__-EgX8wDOTXbyeQ7o',
    enableLogging: true,
    enableDebugMode: false,
  );

  static Environment fromName(String name) {
    switch (name.toLowerCase()) {
      case 'production':
        return production;
      case 'staging':
        return staging;
      default:
        return development;
    }
  }
}
