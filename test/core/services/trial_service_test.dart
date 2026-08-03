import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/constants/verification_storage_keys.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';
import 'package:waretrack_mini/core/services/trial_service.dart';

void main() {
  group('resolveTrialStatus', () {
    test('active when the stored endtime is in the future', () async {
      final storage = InMemoryLocalStorage();
      await storage.writeString(
        kTrialEndTime,
        DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      );
      final service = TrialService(storage);

      expect(await service.resolveTrialStatus(), TrialGateResult.active);
    });

    test('expired when the stored endtime is in the past', () async {
      final storage = InMemoryLocalStorage();
      await storage.writeString(
        kTrialEndTime,
        DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(),
      );
      final service = TrialService(storage);

      expect(await service.resolveTrialStatus(), TrialGateResult.expired);
    });

    test('endtime exactly now counts as expired ("at or past")', () async {
      final storage = InMemoryLocalStorage();
      await storage.writeString(
        kTrialEndTime,
        DateTime.now().toIso8601String(),
      );
      final service = TrialService(storage);

      expect(await service.resolveTrialStatus(), TrialGateResult.expired);
    });

    test('unknown when no endtime has ever been cached', () async {
      final storage = InMemoryLocalStorage();
      final service = TrialService(storage);

      expect(await service.resolveTrialStatus(), TrialGateResult.unknown);
    });

    test('unknown when the cached endtime fails to parse', () async {
      final storage = InMemoryLocalStorage();
      await storage.writeString(kTrialEndTime, 'not-a-date');
      final service = TrialService(storage);

      expect(await service.resolveTrialStatus(), TrialGateResult.unknown);
    });

    test(
      'never mutates the stored endtime — only AuthService may update it',
      () async {
        final storage = InMemoryLocalStorage();
        final endTime = DateTime.now().add(const Duration(days: 1));
        await storage.writeString(kTrialEndTime, endTime.toIso8601String());
        final service = TrialService(storage);

        await service.resolveTrialStatus();
        await service.resolveTrialStatus();

        expect(
          await storage.readString(kTrialEndTime),
          endTime.toIso8601String(),
        );
      },
    );
  });

  group('server-issued end time (code-verify datachar03)', () {
    test('passed end time expires the gate even when server says active', () {
      return _expectGate(
        endTime: DateTime.now().subtract(_oneMinute),
        auth: _activeServer(),
        expected: TrialGateResult.expired,
      );
    });

    test('passed end time expires the gate offline with no cached expire '
        'date', () {
      return _expectGate(
        endTime: DateTime.now().subtract(_oneMinute),
        auth: _FakeAuthService(offline: true),
        expected: TrialGateResult.expired,
      );
    });

    test('passed end time expires the gate even when the server errors', () {
      return _expectGate(
        endTime: DateTime.now().subtract(_oneMinute),
        auth: _FakeAuthService(errorMessage: 'Server error'),
        expected: TrialGateResult.expired,
      );
    });

    test('future end time keeps the gate active', () {
      return _expectGate(
        endTime: DateTime.now().add(_oneMinute),
        auth: _activeServer(),
        expected: TrialGateResult.active,
      );
    });

    test('future end time outlives an already-elapsed TrialDuration '
        'fallback', () async {
      // The whole point of sourcing the window from the API: a device whose
      // enum-based fallback window ran out long ago must still be active when
      // the server issued a later end time.
      final storage = InMemoryLocalStorage();
      await storage.writeString(
        kTrialFirstLaunchDate,
        _launchedAgo(TrialDuration.current.length + _oneMinute),
      );
      await storage.writeString(
        kTrialEndTime,
        DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      );
      final service = TrialService(_activeServer(), storage);

      expect(await service.resolveTrialStatus(), TrialGateResult.active);
    });

    test('unparseable stored end time falls back to TrialDuration', () async {
      final storage = InMemoryLocalStorage();
      await storage.writeString(kTrialEndTime, 'not-a-date');
      await storage.writeString(
        kTrialFirstLaunchDate,
        _launchedAgo(TrialDuration.current.length + _oneMinute),
      );
      final service = TrialService(_activeServer(), storage);

      expect(await service.resolveTrialStatus(), TrialGateResult.expired);
    });
  });
}

const Duration _oneMinute = Duration(minutes: 1);

/// A stored first-launch stamp [ago] in the past, so window tests can be
/// expressed relative to [TrialDuration.current] rather than to a hard-coded
/// duration that breaks whenever `current` is swapped.
String _launchedAgo(Duration ago) =>
    DateTime.now().subtract(ago).toIso8601String();

/// Resolves the gate against a storage holding only a server-issued
/// [endTime], so the assertion isolates the `datachar03` window from the
/// [TrialDuration] fallback.
Future<void> _expectGate({
  required DateTime endTime,
  required AuthService auth,
  required TrialGateResult expected,
}) async {
  final storage = InMemoryLocalStorage();
  await storage.writeString(kTrialEndTime, endTime.toIso8601String());

  expect(await TrialService(auth, storage).resolveTrialStatus(), expected);
}

_FakeAuthService _activeServer() => _FakeAuthService(
  trialStatus: TrialStatusModel(
    isActive: true,
    expireDate: DateTime.now().add(const Duration(days: 30)),
    message: 'ok',
  ),
);

final class _FakeAuthService implements AuthService {
  _FakeAuthService({this.trialStatus, this.offline = false, this.errorMessage});

  final TrialStatusModel? trialStatus;
  final bool offline;
  final String? errorMessage;

  @override
  Future<UserModel> codeVerify(String code) => throw UnimplementedError();

  @override
  Future<TrialStatusModel> verifyDeviceTrial() async {
    if (offline) throw const ApiOfflineException();
    final message = errorMessage;
    if (message != null) throw Exception(message);
    return trialStatus!;
  }
}

