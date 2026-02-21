import 'package:equatable/equatable.dart';

/// Base exception for app-specific errors
abstract base class AppException implements Exception {
  const AppException(this.message, [this.cause, this.stackTrace]);

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => message;
}

/// Exception for file-related errors
final class FileException extends AppException {
  const FileException(super.message, [super.cause, super.stackTrace]);
}

/// Exception for PDF parsing/rendering errors
final class PdfException extends AppException {
  const PdfException(super.message, [super.cause, super.stackTrace]);
}

/// Exception for storage-related errors
final class StorageException extends AppException {
  const StorageException(super.message, [super.cause, super.stackTrace]);
}

/// Exception for network-related errors (future use)
final class NetworkException extends AppException {
  const NetworkException(super.message, [super.cause, super.stackTrace]);
}

/// Exception for permission-related errors
final class PermissionException extends AppException {
  const PermissionException(super.message, [super.cause, super.stackTrace]);
}

/// Exception for validation errors
final class ValidationException extends AppException {
  const ValidationException(super.message, [super.cause, super.stackTrace]);
}

/// Failure object for state management - renamed to avoid conflict with Result
class AppFailure extends Equatable {
  const AppFailure({
    required this.message,
    this.cause,
    this.stackTrace,
    this.code,
  });

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;
  final String? code;

  @override
  List<Object?> get props => [message, cause, code];

  factory AppFailure.fromException(AppException exception) {
    return AppFailure(
      message: exception.message,
      cause: exception.cause,
      stackTrace: exception.stackTrace,
      code: _exceptionToCode(exception),
    );
  }

  static String? _exceptionToCode(AppException exception) {
    return switch (exception) {
      FileException() => 'FILE_ERROR',
      PdfException() => 'PDF_ERROR',
      StorageException() => 'STORAGE_ERROR',
      NetworkException() => 'NETWORK_ERROR',
      PermissionException() => 'PERMISSION_ERROR',
      ValidationException() => 'VALIDATION_ERROR',
      _ => null,
    };
  }

  @override
  String toString() => 'AppFailure(message: $message, code: $code)';
}
