abstract interface class BaseUseCase<Result, Params> {
  Result call(Params params);
}

final class NoParams {
  const NoParams();
}
