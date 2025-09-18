// lib/utils/errors/error_codes.dart

/// Known backend error codes your API may return.
/// Keep these in sync with your server team.
class BackendCodes {
  static const authInvalid = 'AUTH_INVALID';
  static const tokenExpired = 'TOKEN_EXPIRED';
  static const refreshInvalid = 'REFRESH_INVALID';

  static const noCattle = 'NO_CATTLE';
  static const noMarker = 'NO_MARKER';
  static const wrongObject = 'WRONG_OBJECT';
  static const invalidImage = 'INVALID_IMAGE';
}
