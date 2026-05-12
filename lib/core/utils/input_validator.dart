class InputValidator {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _phoneRegex = RegExp(
    r'^\+?[0-9]{8,15}$',
  );

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!_phoneRegex.hasMatch(cleaned)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.length > 100) {
      return 'Name must be less than 100 characters';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateAppointmentDate(DateTime? value) {
    if (value == null) {
      return 'Appointment date is required';
    }
    if (value.isBefore(DateTime.now())) {
      return 'Cannot book appointments in the past';
    }
    if (value.isBefore(DateTime.now().add(const Duration(minutes: 30)))) {
      return 'Appointments must be booked at least 30 minutes in advance';
    }
    return null;
  }

  static String? validateDuration(int? value) {
    if (value == null || value <= 0) {
      return 'Duration must be greater than 0';
    }
    if (value < 5) {
      return 'Duration must be at least 5 minutes';
    }
    if (value > 180) {
      return 'Duration cannot exceed 3 hours';
    }
    return null;
  }

  static String? validateWorkingHours(int? opening, int? closing) {
    if (opening == null || closing == null) {
      return 'Working hours are required';
    }
    if (opening < 0 || opening > 23) {
      return 'Invalid opening hour';
    }
    if (closing < 0 || closing > 23) {
      return 'Invalid closing hour';
    }
    if (opening >= closing) {
      return 'Opening time must be before closing time';
    }
    if (closing - opening < 1) {
      return 'Must work at least 1 hour';
    }
    return null;
  }

  static String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.length > 100) {
      return 'City name is too long';
    }
    return null;
  }

  static String? validateBio(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.length > 1000) {
      return 'Bio must be less than 1000 characters';
    }
    return null;
  }

  static bool isValidEmail(String value) => validateEmail(value) == null;
  static bool isValidPhone(String value) => validatePhone(value) == null;
  static bool isValidPassword(String value) => validatePassword(value) == null;
  static bool isValidFullName(String value) => validateFullName(value) == null;
}
