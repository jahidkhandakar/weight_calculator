//* ----------------------- Phone helpers -------------------------
  // Validates and normalizes Bangladeshi phone numbers
  String? validateBdPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final okLocal = RegExp(r'^01\d{9}$').hasMatch(digits);
    final okIntl = RegExp(r'^8801\d{9}$').hasMatch(digits);
    if (okLocal || okIntl) return null;
    return 'Enter a valid BD number (e.g., 017XXXXXXXX)';
  }

  String normalizeBdPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('880') && digits.length == 13) {
      return '0${digits.substring(3)}'; // 88017... -> 017...
    }
    if (digits.startsWith('01') && digits.length == 11) return digits;
    return raw.trim();
  }