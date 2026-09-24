// A course is considered OFFERED to students when it is ACTIVE and its
// registration window has not yet ended. Entries without explicit dates are
// kept rather than hidden.
bool isOfferedCourse(dynamic c) {
  if (c is! Map) return false;

  final status = (c['status']?.toString() ?? '').trim().toUpperCase();
  if (status.isNotEmpty && status != 'ACTIVE') return false;

  final regEnd = (c['registrationEndDate']?.toString() ?? '').trim();
  if (regEnd.isEmpty) return true;

  final end = DateTime.tryParse(regEnd);
  if (end == null) return true;

  return !DateTime.now().isAfter(end);
}