import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:waretrack_mini/core/api_services/api_connection_guard.dart';

void main() {
  final guard = ApiConnectionGuard(checkReachability: () async => true);

  for (final networkError in <Object>[
    const SocketException('offline'),
    TimeoutException('timed out'),
    http.ClientException('connection failed'),
  ]) {
    test('normalizes ${networkError.runtimeType} after request starts', () {
      expect(
        guard.run<void>(() async => throw networkError),
        throwsA(isA<ApiOfflineException>()),
      );
    });
  }
}
