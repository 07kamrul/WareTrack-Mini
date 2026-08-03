import 'package:waretrack_mini/core/constants/verification_storage_keys.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';

enum TrialGateResult { active, expired, unknown }

/// Fallback trial length for the Trial build.
///
/// Only used until the server has told this device when its trial ends: the
/// `datachar03` end time cached from `POST /code-verify` (see [kTrialEndTime])
/// takes priority, and this enum covers the window before verification has
/// ever succeeded. [TrialService] enforces it client-side, counted from this
/// device's first-launch date (see [kTrialFirstLaunchDate]).
///
/// The active value is [current]; the others are kept defined so switching
/// the fallback length back is the same one-line swap.
enum TrialDuration {
  tenMinutes(Duration(minutes: 10)),
  oneHour(Duration(hours: 1)),
  threeDays(Duration(days: 3));

  const TrialDuration(this.length);

  /// How long the trial remains active, counted from first launch.
  final Duration length;

  /// The duration actually enforced by [TrialService].
  static const TrialDuration current = TrialDuration.tenMinutes;
}

/// Trial gate for the trial build.
///
/// Resolving the gate is a purely local comparison of device time against
/// this device's trial window — there is no server round-trip, so an
/// unreachable or erroring backend can never stop the trial from expiring on
/// schedule.
///
/// The window comes from the server-issued end time cached at [kTrialEndTime]
/// — the `datachar03` timestamp of the most recent successful code-verify
/// response. That value is the source of truth whenever it is present, and it
/// is refreshed only by a new successful code verification (see
/// AuthService.codeVerify), never by a routine trial check.
///
/// Until one has ever been issued — or when the cached value fails to parse —
/// the [TrialDuration] fallback counted from [kTrialFirstLaunchDate] still
/// bounds the window, so an install that never verifies cannot run forever.
/// While that fallback window is open the gate reports
/// [TrialGateResult.unknown] rather than claiming an active trial it has no
/// end time for; callers treat that the same as not-yet-verified.
///
/// The gate is one-way: nothing un-expires it.
class TrialService {
  const TrialService(this._storage);

  final LocalStorage _storage;

  Future<TrialGateResult> resolveTrialStatus() async {
    // The server-issued end time wins whenever one has been cached, so the
    // trial length is whatever `code-verify` said rather than a hardcoded
    // duration. [TrialDuration] only covers the gap before any successful
    // verification has supplied an end time.
    final endTime = await _readServerEndTime();
    final windowEnd = endTime ?? await _fallbackEndTime();

    // "At or past" the end time counts as expired, so an end time of exactly
    // now closes the gate rather than granting one more tick of access.
    if (!windowEnd.isAfter(DateTime.now())) return TrialGateResult.expired;

    // Still inside the fallback window with no end time ever issued: not
    // expired, but there is nothing to call an active trial either.
    return endTime == null ? TrialGateResult.unknown : TrialGateResult.active;
  }

  /// The trial end time the server issued via `code-verify`'s `datachar03`,
  /// or null when none has been cached or the cached value is unreadable —
  /// in which case the caller falls back to [TrialDuration].
  Future<DateTime?> _readServerEndTime() async {
    final stored = await _storage.readString(kTrialEndTime);
    if (stored == null || stored.isEmpty) return null;
    return DateTime.tryParse(stored);
  }

  Future<DateTime> _fallbackEndTime() async {
    final firstLaunch = await _getOrCreateFirstLaunchDate();
    return firstLaunch.add(TrialDuration.current.length);
  }

  /// Reads this device's stored first-launch date, or stamps it as now the
  /// very first time this is called. Never overwritten afterward, so the
  /// client-side window is fixed for the lifetime of this app install.
  Future<DateTime> _getOrCreateFirstLaunchDate() async {
    final stored = await _storage.readString(kTrialFirstLaunchDate);
    final parsed = stored == null ? null : DateTime.tryParse(stored);
    if (parsed != null) return parsed;

    final now = DateTime.now();
    await _storage.writeString(kTrialFirstLaunchDate, now.toIso8601String());
    return now;
  }
}
