String? safeInternalLocation(String? candidate) {
  if (candidate == null || candidate.isEmpty) return null;
  final uri = Uri.tryParse(candidate);
  if (uri == null || uri.hasScheme || uri.hasAuthority || !uri.path.startsWith('/') || uri.path.startsWith('//')) {
    return null;
  }
  if (const {'/login', '/register', '/onboarding', '/access-denied'}.contains(uri.path)) {
    return null;
  }
  return uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
}
