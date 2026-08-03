abstract interface class ApiClient {
  Future<T> get<T>(String path);
  Future<T> post<T>(String path, {Object? body});
}

final class NoOpApiClient implements ApiClient {
  const NoOpApiClient();

  @override
  Future<T> get<T>(String path) {
    throw UnimplementedError(
      'No API client implementation has been configured.',
    );
  }

  @override
  Future<T> post<T>(String path, {Object? body}) {
    throw UnimplementedError(
      'No API client implementation has been configured.',
    );
  }
}
