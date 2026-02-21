import 'package:freezed_annotation/freezed_annotation.dart';

part 'result.freezed.dart';

/// Result type for operations that can fail
@freezed
class Result<T> with _$Result<T> {
  const Result._();

  const factory Result.success(T data) = Success;
  const factory Result.failure(Object error, [StackTrace? stackTrace]) = Failure;
}

/// Extension on Result for additional utility methods
extension ResultExtension<T> on Result<T> {
  /// Returns true if the result is successful
  bool get isSuccess => maybeWhen(success: (_) => true, orElse: () => false);

  /// Returns true if the result is a failure
  bool get isFailure => !isSuccess;

  /// Get the data or throw if failure
  T get dataOrThrow {
    return when(
      success: (data) => data,
      failure: (error, stackTrace) {
        Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current);
      },
    );
  }

  /// Get the data or return a default value
  T dataOr(T defaultValue) {
    return maybeWhen(success: (data) => data, orElse: () => defaultValue);
  }

  /// Transform the data if successful
  Result<R> mapData<R>(R Function(T data) transform) {
    return when(
      success: (data) {
        try {
          return Result.success(transform(data));
        } catch (e, st) {
          return Result.failure(e, st);
        }
      },
      failure: (error, stackTrace) => Result.failure(error, stackTrace),
    );
  }

  /// Async transform
  Future<Result<R>> mapDataAsync<R>(Future<R> Function(T data) transform) async {
    return when(
      success: (data) async {
        try {
          final result = await transform(data);
          return Result.success(result);
        } catch (e, st) {
          return Result.failure(e, st);
        }
      },
      failure: (error, stackTrace) => Result.failure(error, stackTrace),
    );
  }

  /// Execute a callback on success
  Result<T> onSuccess(void Function(T data) callback) {
    return when(
      success: (data) {
        callback(data);
        return Result.success(data);
      },
      failure: (error, stackTrace) => Result.failure(error, stackTrace),
    );
  }

  /// Execute a callback on failure
  Result<T> onFailure(void Function(Object error, StackTrace? stackTrace) callback) {
    return when(
      success: (data) => Result.success(data),
      failure: (error, stackTrace) {
        callback(error, stackTrace);
        return Result.failure(error, stackTrace);
      },
    );
  }
}

/// Extension to convert Futures to Results
extension ResultFutureExtensions<T> on Future<T> {
  Future<Result<T>> toResult() async {
    try {
      final data = await this;
      return Result.success(data);
    } catch (e, st) {
      return Result.failure(e, st);
    }
  }
}

/// Extension to convert synchronous functions to Results
extension ResultSyncExtensions<T> on T Function() {
  Result<T> toResult() {
    try {
      final data = this();
      return Result.success(data);
    } catch (e, st) {
      return Result.failure(e, st);
    }
  }
}
