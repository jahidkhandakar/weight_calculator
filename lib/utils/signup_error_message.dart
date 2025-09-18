String mapSignupError(Map<String, dynamic> res) {
  final code = res['code'] as int?;
  final msg = (res['message'] ?? '').toString().toLowerCase();
  final data = res['data'];

  if (code == 400 && data is Map<String, dynamic>) {
    // Common Django/DRF-style field errors
    if (data['username'] != null) return 'This phone number is already registered. Please log in.';
    if (data['password'] != null) return 'Password doesn’t meet the requirements.';
    if (data['confirm_password'] != null || msg.contains('match')) return 'Passwords do not match.';
    if (data['name'] != null) return 'Please enter your name.';
  }

  if (msg.contains('unique') || msg.contains('already')) {
    return 'This phone number is already registered. Please log in.';
  }
  if (msg.contains('invalid') || msg.contains('format')) {
    return 'Enter a valid Bangladeshi number, e.g., 017XXXXXXXX.';
  }
  if (msg.contains('password')) {
    return 'Password doesn’t meet the requirements.';
  }

  return 'Bad request. Please check the form and try again.';
}
