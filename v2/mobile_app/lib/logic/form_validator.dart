class FormValidator {
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) return 'Age is required';
    final val = int.tryParse(value);
    if (val == null) return 'Enter a valid number';
    if (val < 1 || val > 120) return 'Age must be between 1 and 120';
    return null;
  }

  static String? validateRestingBP(String? value) {
    if (value == null || value.isEmpty) return 'Resting BP is required';
    final val = double.tryParse(value);
    if (val == null) return 'Enter a valid number';
    if (val < 50 || val > 250) return 'Must be between 50 and 250 mmHg';
    return null;
  }

  static String? validateCholesterol(String? value) {
    if (value == null || value.isEmpty) return 'Cholesterol is required';
    final val = double.tryParse(value);
    if (val == null) return 'Enter a valid number';
    if (val < 0 || val > 1000) return 'Must be between 0 and 1000 mg/dL';
    return null;
  }

  static String? validateMaxHR(String? value) {
    if (value == null || value.isEmpty) return 'Max HR is required';
    final val = double.tryParse(value);
    if (val == null) return 'Enter a valid number';
    if (val < 40 || val > 250) return 'Must be between 40 and 250 bpm';
    return null;
  }

  static String? validateOldpeak(String? value) {
    if (value == null || value.isEmpty) return 'ST Depression is required';
    final val = double.tryParse(value);
    if (val == null) return 'Enter a valid number';
    if (val < -10.0 || val > 10.0) return 'Must be between -10.0 and 10.0';
    return null;
  }
}
