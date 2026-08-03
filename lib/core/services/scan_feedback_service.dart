import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum _FeedbackPriority { success, differentProduct, error }

final class _FeedbackEvent {
  const _FeedbackEvent(this.id, this.priority);

  final Object id;
  final _FeedbackPriority priority;
}

class ScanFeedbackService {
  static const Duration _soundLifetime = Duration(milliseconds: 1200);
  static const Duration _samePriorityDebounce = Duration(milliseconds: 450);

  final Map<String, Future<AudioPool>> _pools = {};

  _FeedbackEvent? _lastEvent;
  _FeedbackPriority? _lastPriority;
  DateTime? _lastSoundAt;

  Future<void> playScanSuccess({Object? eventId}) async {
    await Future.wait([
      _playEventSound(
        'audios/ok.mp3',
        priority: _FeedbackPriority.success,
        eventId: eventId,
      ),
      vibrateOnSuccess(),
    ]);
  }

  Future<void> playProductScanSuccess({Object? eventId}) async {
    await Future.wait([
      _playEventSound(
        'audios/sok.mp3',
        priority: _FeedbackPriority.success,
        eventId: eventId,
        debounceSamePriority: false,
      ),
      vibrateOnSuccess(),
    ]);
  }

  Future<void> playScanError({Object? eventId}) async {
    await _playEventSound(
      'audios/ng.mp3',
      priority: _FeedbackPriority.error,
      eventId: eventId,
    );
  }

  Future<void> playDifferentProduct({Object? eventId}) async {
    await Future.wait([
      _playEventSound(
        'audios/keikoku.wav',
        priority: _FeedbackPriority.differentProduct,
        eventId: eventId,
        debounceSamePriority: false,
      ),
      vibrateOnSuccess(),
    ]);
  }

  Future<void> playDatabaseSuccess({Object? eventId}) async {
    await _playEventSound(
      'audios/kakutei.mp3',
      priority: _FeedbackPriority.success,
      eventId: eventId,
    );
  }

  Future<void> _playEventSound(
    String assetPath, {
    required _FeedbackPriority priority,
    Object? eventId,
    bool debounceSamePriority = true,
  }) async {
    if (eventId != null && _isDuplicateOrLowerPriority(eventId, priority)) {
      return;
    }

    final now = DateTime.now();
    final lastSoundAt = _lastSoundAt;
    if (debounceSamePriority &&
        _lastPriority == priority &&
        lastSoundAt != null &&
        now.difference(lastSoundAt) < _samePriorityDebounce) {
      return;
    }

    if (eventId != null) {
      _lastEvent = _FeedbackEvent(eventId, priority);
    }
    _lastPriority = priority;
    _lastSoundAt = now;

    final pool = await _poolFor(assetPath);
    final stop = await pool.start();
    unawaited(Future<void>.delayed(_soundLifetime).then((_) => stop()));
  }

  Future<AudioPool> _poolFor(String assetPath) {
    return _pools.putIfAbsent(
      assetPath,
      () => AudioPool.createFromAsset(
        path: assetPath,
        minPlayers: 2,
        maxPlayers: 4,
        playerMode: PlayerMode.lowLatency,
      ),
    );
  }

  bool _isDuplicateOrLowerPriority(Object eventId, _FeedbackPriority priority) {
    final lastEvent = _lastEvent;
    if (lastEvent == null || !identical(lastEvent.id, eventId)) {
      return false;
    }

    return lastEvent.priority.index >= priority.index;
  }

  Future<void> vibrateOnSuccess() async {
    await HapticFeedback.mediumImpact();
  }
}
