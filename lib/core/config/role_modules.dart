import 'module_config.dart';

class UnsupportedRoleException implements Exception {
  const UnsupportedRoleException();
}

/// First matching module wins for accounts with multiple roles.
/// These names must match roles returned by GET auth/me; email is never a role.
AppModuleType? moduleForRoles(Iterable<String> roles) {
  final normalized = roles
      .map(
        (role) => role.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_'),
      )
      .toSet();
  const mapping = {
    'cdc_secretariat': AppModuleType.cdcSecretariat,
    'cdc_section': AppModuleType.cdcSection,
    'cefp': AppModuleType.cefp,
    'line_ministry': AppModuleType.lineMinistry,
    'private_sector': AppModuleType.privateSector,
    'pswg': AppModuleType.privateSector,
  };

  // Secretariat accounts can be returned with a role suffix such as
  // `cdc_secretariat_user` or `cdc_secretariat_admin`.
  if (normalized.any(
    (role) =>
        role == 'cdc' ||
        role == 'cdc_g_psf' ||
        role.startsWith('cdc_secretariat_'),
  )) {
    return AppModuleType.cdcSecretariat;
  }
  for (final entry in mapping.entries) {
    if (normalized.contains(entry.key)) return entry.value;
  }
  // The API also uses these display-role names for ministry accounts.
  if (normalized.any(
    (role) =>
        role == 'ministry' ||
        role == 'ministry_user' ||
        role == 'ministry_admin' ||
        role == 'government_agency' ||
        role == 'government_official',
  )) {
    return AppModuleType.lineMinistry;
  }
  // A module-specific role takes precedence over the generic admin fallback.
  return normalized.contains('admin') ? AppModuleType.cdcSecretariat : null;
}
