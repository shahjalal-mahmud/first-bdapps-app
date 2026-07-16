/// Domain-level exception hierarchy for the API client.
///
/// The repository layer translates low-level [ApiException]s into
/// user-facing messages; UI components never see raw HTTP errors.
library;

/// Base class for every API-related failure.
sealed class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// No internet connection or DNS failure.
class NetworkException extends ApiException {
  const NetworkException([String message = 'No internet connection'])
    : super(message);
}

/// Server unreachable, timeout, or 5xx response.
class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode});
}

/// 4xx response with a structured error payload from the wrapper.
class BadRequestException extends ApiException {
  final String? serverMessage;

  const BadRequestException(super.message, {this.serverMessage, super.statusCode});
}

/// Wrapper returned a payload we cannot decode.
class UnexpectedResponseException extends ApiException {
  const UnexpectedResponseException([String message = 'Unexpected response'])
    : super(message);
}
