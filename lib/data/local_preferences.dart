import 'package:shared_preferences/shared_preferences.dart';

/// Always read the platform, not a potentially stale process-local preference cache.
Future<String?> readLocalString(
  SharedPreferences preferences,
  String key,
) async {
  await preferences.reload();
  return preferences.getString(key);
}

/// SharedPreferences updates its cache before awaiting the platform write.
/// Refresh after failure so an unpersisted value cannot appear on the next load.
Future<void> writeLocalString(
  SharedPreferences preferences,
  String key,
  String value, {
  required String failureMessage,
}) async {
  try {
    if (!await preferences.setString(key, value)) {
      throw StateError(failureMessage);
    }
  } catch (error, stack) {
    try {
      await preferences.reload();
    } catch (_) {
      /* The next fresh read will fail rather than expose the cache. */
    }
    Error.throwWithStackTrace(error, stack);
  }
}
