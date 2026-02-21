import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_reader_app/core/utils/result.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('should contain data', () {
        const result = Result.success('test data');
        expect(
          result.maybeWhen(
            success: (data) => data,
            orElse: () => null,
        ),
          'test data',
        );
      });

      test('should be identified as success', () {
        const result = Result.success('data');
        expect(result.isSuccess, true);
        expect(result.isFailure, false);
      });

      test('mapData should transform data', () {
        const result = Result.success(5);
        final mapped = result.mapData((n) => n * 2);
        expect(
          mapped.maybeWhen(
            success: (d) => d,
            orElse: () => null,
        ),
          10,
        );
      });

      test('mapDataAsync should transform data asynchronously', () async {
        const result = Result.success(5);
        final mapped = await result.mapDataAsync((n) async => n * 2);
        expect(
          mapped.maybeWhen(
            success: (d) => d,
            orElse: () => null,
        ),
          10,
        );
      });

      test('onSuccess should execute callback', () {
        var executed = false;
        const result = Result.success('data');
        result.onSuccess((_) => executed = true);
        expect(executed, true);
      });

      test('onFailure should not execute callback', () {
        var executed = false;
        const result = Result.success('data');
        result.onFailure((_, __) => executed = true);
        expect(executed, false);
      });
    });

    group('Failure', () {
      test('should contain error', () {
        final result = Result.failure(Exception('test error'), StackTrace.current);
        expect(
          result.maybeWhen(
            failure: (e, st) => e.toString(),
            orElse: () => null,
        ),
          'Exception: test error',
        );
      });

      test('should be identified as failure', () {
        final result = Result.failure(Exception('error'), StackTrace.current);
        expect(result.isSuccess, false);
        expect(result.isFailure, true);
      });

      test('mapData should not transform and return failure', () {
        final result = Result.failure(Exception('error'), StackTrace.current);
        final mapped = result.mapData<int>((n) => n * 2);
        expect(mapped.isFailure, true);
      });

      test('onSuccess should not execute callback', () {
        var executed = false;
        final result = Result.failure(Exception('error'), StackTrace.current);
        result.onSuccess((_) => executed = true);
        expect(executed, false);
      });

      test('onFailure should execute callback', () {
        var executed = false;
        final result = Result.failure(Exception('error'), StackTrace.current);
        result.onFailure((_, __) => executed = true);
        expect(executed, true);
      });
    });

    group('Equality', () {
      test('success with same data should be equal', () {
        const result1 = Result.success('test');
        const result2 = Result.success('test');
        expect(result1, result2);
      });

      test('failure with same error should be equal', () {
        final result1 = Result.failure('error', null);
        final result2 = Result.failure('error', null);
        expect(result1, result2);
      });
    });
  });
}
