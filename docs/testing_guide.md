# Eyadati - Testing Guide

## Unit Testing

### Auth Repository Tests

```dart
void main() {
  group('AuthRepository', () {
    test('signIn with valid credentials returns success', () async {
      // Arrange
      final authRepo = AuthRepository(mockClient);
      
      // Act
      final result = await authRepo.signIn(
        email: 'test@example.com',
        password: 'password123',
      );
      
      // Assert
      expect(result.isSuccess, true);
      expect(result.user, isNotNull);
    });
    
    test('signIn with invalid credentials returns failure', () async {
      // Arrange
      final authRepo = AuthRepository(mockClient);
      
      // Act
      final result = await authRepo.signIn(
        email: 'invalid@example.com',
        password: 'wrongpassword',
      );
      
      // Assert
      expect(result.isSuccess, false);
      expect(result.error, isNotNull);
    });
    
    test('signUp with empty email returns validation error', () async {
      // Arrange
      final authRepo = AuthRepository(mockClient);
      
      // Act
      final result = await authRepo.signUp(
        email: '',
        password: 'password123',
        fullName: 'Test User',
        role: 'patient',
      );
      
      // Assert
      expect(result.isSuccess, false);
      expect(result.error, contains('Email'));
    });
  });
}
```

### Appointment Repository Tests

```dart
void main() {
  group('AppointmentRepository', () {
    test('createAppointment with valid data succeeds', () async {
      // Arrange
      final repo = AppointmentRepository(mockClient);
      
      // Act
      final result = await repo.createAppointment(
        doctorId: validDoctorId,
        scheduledAt: DateTime.now().add(Duration(days: 1)),
        duration: 20,
        patientName: 'John Doe',
      );
      
      // Assert
      expect(result.isSuccess, true);
      expect(result.appointment, isNotNull);
    });
    
    test('createAppointment in past returns error', () async {
      // Arrange
      final repo = AppointmentRepository(mockClient);
      
      // Act
      final result = await repo.createAppointment(
        doctorId: validDoctorId,
        scheduledAt: DateTime.now().subtract(Duration(days: 1)),
        duration: 20,
        patientName: 'John Doe',
      );
      
      // Assert
      expect(result.isSuccess, false);
      expect(result.error, contains('past'));
    });
    
    test('cancelAppointment for non-existent id returns failure', () async {
      // Arrange
      final repo = AppointmentRepository(mockClient);
      
      // Act
      final result = await repo.cancelAppointment(invalidAppointmentId);
      
      // Assert
      expect(result.isSuccess, false);
    });
  });
}
```

### Validation Tests

```dart
void main() {
  group('InputValidator', () {
    test('validateEmail with valid email returns null', () {
      expect(InputValidator.validateEmail('test@example.com'), isNull);
      expect(InputValidator.validateEmail('user.name@domain.co'), isNull);
    });
    
    test('validateEmail with invalid email returns error', () {
      expect(InputValidator.validateEmail(''), isNotNull);
      expect(InputValidator.validateEmail('invalid'), isNotNull);
      expect(InputValidator.validateEmail('@nodomain'), isNotNull);
    });
    
    test('validatePassword with short password returns error', () {
      expect(InputValidator.validatePassword('12345'), isNotNull);
      expect(InputValidator.validatePassword('123456'), isNull);
    });
    
    test('validateAppointmentDate with past date returns error', () {
      final pastDate = DateTime.now().subtract(Duration(hours: 1));
      expect(InputValidator.validateAppointmentDate(pastDate), isNotNull);
    });
    
    test('validateAppointmentDate with future date returns null', () {
      final futureDate = DateTime.now().add(Duration(days: 1));
      expect(InputValidator.validateAppointmentDate(futureDate), isNull);
    });
    
    test('validateDuration with valid duration returns null', () {
      expect(InputValidator.validateDuration(20), isNull);
      expect(InputValidator.validateDuration(60), isNull);
    });
    
    test('validateDuration with invalid duration returns error', () {
      expect(InputValidator.validateDuration(0), isNotNull);
      expect(InputValidator.validateDuration(-1), isNotNull);
      expect(InputValidator.validateDuration(200), isNotNull);
    });
  });
  
  group('SecurityValidator', () {
    test('isValidUuid with valid UUID returns true', () {
      expect(SecurityValidator.isValidUuid('550e8400-e29b-41d4-a716-446655440000'), isTrue);
    });
    
    test('isValidUuid with invalid UUID returns false', () {
      expect(SecurityValidator.isValidUuid('invalid'), isFalse);
      expect(SecurityValidator.isValidUuid('123'), isFalse);
      expect(SecurityValidator.isValidUuid(''), isFalse);
    });
    
    test('sanitizeHtml removes script tags', () {
      expect(SecurityValidator.sanitizeHtml('<script>alert()</script>'), equals(''));
    });
  });
}
```

## Integration Testing

### Database Tests

```dart
void main() {
  group('Database Integration', () {
    setUp(() async {
      // Setup test database
    });
    
    tearDown(() async {
      // Clean up test data
    });
    
    test('profiles table auto-creates on signup', () async {
      // Create user via auth
      final user = await createTestUser();
      
      // Verify profile was created
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      
      expect(profile['role'], equals('patient'));
    });
    
    test('RLS prevents unauthorized access', () async {
      // Create two users
      final user1 = await createTestUser();
      final user2 = await createTestUser();
      
      // User 1 creates appointment
      final appointment = await createAppointment(user1.id);
      
      // User 2 should not be able to view user 1's appointment
      final result = await supabase
          .from('appointments')
          .select()
          .eq('id', appointment.id)
          .maybeSingle();
      
      expect(result, isNull);
    });
  });
}
```

## Manual Testing Checklist

### Authentication
- [ ] Sign up with email/password
- [ ] Sign in with valid credentials
- [ ] Sign in with invalid credentials
- [ ] Password reset flow
- [ ] Email confirmation
- [ ] Sign out

### Patient Flow
- [ ] Browse doctors list
- [ ] Filter by specialty
- [ ] Filter by city
- [ ] Search doctors
- [ ] View doctor details
- [ ] Book appointment
- [ ] View my appointments
- [ ] Cancel appointment
- [ ] Add to favorites
- [ ] Remove from favorites

### Doctor Flow
- [ ] View dashboard
- [ ] View appointments
- [ ] Create manual appointment
- [ ] Update appointment status
- [ ] Update profile
- [ ] Toggle pause mode

### Security
- [ ] Cannot access other users' appointments
- [ ] Cannot access other doctors' profiles
- [ ] Cannot create appointments for others
- [ ] Cannot modify other users' favorites
- [ ] Input validation working
- [ ] SQL injection protected

## Performance Testing

### Load Testing

```bash
# Using Apache Bench
ab -n 1000 -c 10 https://your-domain.com/api/doctors

# Using k6
k6 run tests/load_test.js
```

### Metrics to Monitor
- Response time (p50, p95, p99)
- Error rate
- Database query time
- API rate limit status
