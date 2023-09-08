import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

/// Generic callback for API response.
///  Explicitally specify `T` and `E` to decode correctly
/// the content.
class APIResponse<T, E> {
  /// Decode body, if any.
  /// The type must be specified in [APIResponse] declaration.
  ///
  /// It can be null, i.e. if the API
  /// call resulted in an error.
  T? decodedBody;

  /// Decode body as a List, if any.
  /// The type must be specified in [APIResponse] declaration.
  ///
  /// It can be null, i.e. if the API
  /// call resulted in an error or if it was not possible to retrieve a list.
  /// This is useful for example when the API returns a List instead of a Map.
  List<T>? decodedBodyAsList;

  /// Decode error body, if any.
  /// The type must be specified in [APIResponse] declaration.
  ///
  /// It can be null, i.e. if the API
  /// call resulted in success.
  E? decodedErrorBody;

  /// The response body of the API call, decoded.
  /// It can be _null_
  dynamic rawValue;

  /// The original response of the http request, as is.
  /// It can be _null_  (i.e. if there is no internet connection)
  Response? originalResponse;

  /// API call status code.
  int statusCode;

  /// Boolean value to indicate if the API call had an error. If `true`, content
  /// should not be considered.
  bool hasError;

  /// Eventually a message or error message can be specified.
  String? message;
  APIResponse({
    this.decodedBody,
    this.decodedBodyAsList,
    this.decodedErrorBody,
    required this.rawValue,
    required this.originalResponse,
    required this.statusCode,
    required this.hasError,
    this.message,
  });

  APIResponse<T, E> copyWith({
    T? decodedBody,
    List<T>? decodedBodyAsList,
    E? decodedErrorBody,
    dynamic rawValue,
    Response? originalResponse,
    int? statusCode,
    bool? hasError,
    String? message,
  }) {
    return APIResponse<T, E>(
      decodedBody: decodedBody ?? this.decodedBody,
      decodedBodyAsList: decodedBodyAsList ?? this.decodedBodyAsList,
      decodedErrorBody: decodedErrorBody ?? this.decodedErrorBody,
      rawValue: rawValue ?? this.rawValue,
      originalResponse: originalResponse ?? this.originalResponse,
      statusCode: statusCode ?? this.statusCode,
      hasError: hasError ?? this.hasError,
      message: message ?? this.message,
    );
  }

  @override
  String toString() {
    return 'PostApiResponse(decodedBody: $decodedBody, decodedBodyAsList: $decodedBodyAsList, decodedErrorBody: $decodedErrorBody, rawValue: $rawValue, originalResponse: $originalResponse, statusCode: $statusCode, hasError: $hasError, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is APIResponse<T, E> &&
        other.decodedBody == decodedBody &&
        listEquals(other.decodedBodyAsList, decodedBodyAsList) &&
        other.decodedErrorBody == decodedErrorBody &&
        other.rawValue == rawValue &&
        other.originalResponse == originalResponse &&
        other.statusCode == statusCode &&
        other.hasError == hasError &&
        other.message == message;
  }

  @override
  int get hashCode {
    return decodedBody.hashCode ^
        decodedBodyAsList.hashCode ^
        decodedErrorBody.hashCode ^
        rawValue.hashCode ^
        originalResponse.hashCode ^
        statusCode.hashCode ^
        hasError.hashCode ^
        message.hashCode;
  }
}
