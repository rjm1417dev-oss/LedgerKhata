String digitsOnly(String v) => v.replaceAll(RegExp(r'[^0-9]'), '');
String phoneChars(String v) => v.replaceAll(RegExp(r'[^0-9+\- ]'), '');

String? phoneError(String v) {
  final d = digitsOnly(v);
  if (d.isEmpty) return 'Enter a phone number';
  if (d.length < 10 || d.length > 13) return 'Enter a valid phone number';
  return null;
}

String? emailError(String v) {
  final e = v.trim();
  if (e.isEmpty) return 'Enter your email address';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) {
    return 'Enter a valid email address';
  }
  return null;
}

String? passwordError(String v) {
  if (v.isEmpty) return 'Enter a password';
  if (v.length < 6) return 'Password must be at least 6 characters';
  return null;
}
