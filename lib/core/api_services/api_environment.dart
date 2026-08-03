enum ApiEnvironment {
  demo440('https://demo440.colgis.jp/api'),
  demo440Trial('https://demo440.colgis.jp/api/test'),

  demo395('https://demo395.colgis.jp/api'),
  demo395Trial('https://demo395.colgis.jp/api/test'),

  //client url
  jarocClient('https://handy-jaroc.colgis.jp/api'),
  jarocClientTrial('https://handy-jaroc.colgis.jp/api/test'),

  jarocDemo('https://handy-jaroc.demo.colgis.jp/api'),
  jarocDemoTrial('https://handy-jaroc.demo.colgis.jp/api/test'),

  jarocDev('https://handy-jaroc.dev.colgis.jp/api'),
  jarocDevTrial('https://handy-jaroc.dev.colgis.jp/api/test');

  final String baseUrl;
  const ApiEnvironment(this.baseUrl);

  /// The environment selected when no `--dart-define=API_ENV=...` is passed.
  static const ApiEnvironment fallback = demo440;

  /// Resolves a `--dart-define=API_ENV=...` value, which is the enum member
  /// name verbatim (`demo440`, `demo440Trial`, `jarocDev`, ...). An unknown
  /// value falls back to [fallback] instead of throwing, so a typo in a build
  /// script can never crash the app at startup.
  static ApiEnvironment fromName(String name) =>
      values.asNameMap()[name] ?? fallback;
}

extension ApiEnvironmentX on ApiEnvironment {
  /// Every base environment has a Trial counterpart named `<base>Trial` whose
  /// [baseUrl] is the base URL plus the server's `/test` route. Trial status is
  /// derived from that naming convention, so adding a new environment pair
  /// needs no change anywhere else.
  bool get isTrial => name.endsWith('Trial');
}
