import 'dart:async';

import 'package:flutter/material.dart';

Future<void> waitForScannerRouteVisible(ModalRoute<dynamic>? route) async {
  await WidgetsBinding.instance.endOfFrame;
  if (route == null) {
    return;
  }

  await Future.wait([
    _waitForAnimationStatus(route.animation, AnimationStatus.completed),
    _waitForAnimationStatus(
      route.secondaryAnimation,
      AnimationStatus.dismissed,
    ),
  ]);
}

Future<void> _waitForAnimationStatus(
  Animation<double>? animation,
  AnimationStatus expectedStatus,
) async {
  if (animation == null || animation.status == expectedStatus) {
    return;
  }

  final completer = Completer<void>();

  void listener(AnimationStatus status) {
    if (status != expectedStatus || completer.isCompleted) {
      return;
    }

    animation.removeStatusListener(listener);
    completer.complete();
  }

  animation.addStatusListener(listener);
  await completer.future;
}
