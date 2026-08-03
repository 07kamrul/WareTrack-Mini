import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:waretrack_mini/core/api_services/base_api.dart';

typedef ApiReachabilityCheck = Future<bool> Function();

final class ApiOfflineException implements Exception {
  const ApiOfflineException();
}

final class ApiConnectionGuard {
  ApiConnectionGuard({ApiReachabilityCheck? checkReachability})
    : _checkReachability = checkReachability ?? _canReachApi;

  static const Duration _connectionTimeout = Duration(seconds: 5);

  final ApiReachabilityCheck _checkReachability;

  Future<T> run<T>(Future<T> Function() request) async {
    if (!await _checkReachability()) {
      throw const ApiOfflineException();
    }

    try {
      return await request();
    } on SocketException {
      throw const ApiOfflineException();
    } on TimeoutException {
      throw const ApiOfflineException();
    } on http.ClientException {
      throw const ApiOfflineException();
    }
  }

  static Future<bool> _canReachApi() async {
    Socket? socket;
    try {
      final uri = Uri.parse(BaseApi.current.baseUrl);
      socket = await Socket.connect(
        uri.host,
        uri.hasPort ? uri.port : 443,
        timeout: _connectionTimeout,
      );
      return true;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } finally {
      socket?.destroy();
    }
  }
}

bool isApiOfflineError(Object error) {
  final message = error.toString().toLowerCase();
  return error is ApiOfflineException ||
      error is SocketException ||
      error is TimeoutException ||
      error is http.ClientException ||
      message.contains('apiofflineexception') ||
      message.contains('socketexception') ||
      message.contains('timeoutexception') ||
      message.contains('clientexception') ||
      message.contains('failed host lookup') ||
      message.contains('network is unreachable');
}
