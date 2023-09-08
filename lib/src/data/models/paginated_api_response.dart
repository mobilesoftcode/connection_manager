import 'api_response.dart';
import 'package:http/http.dart';

/// Generic paginated response for an API call.
/// Explicitally specify `T` and `E` to decode correctly the content.
///
/// Note that `T` should not be a list, but the single entity do decode as data.
class PaginatedAPIResponse<T, E> {
  /// Generic content, type must be specified. It can be null, i.e. if the API
  /// call resulted in an error.
  List<T>? data;

  /// Total number of elements
  int total;

  /// Number of current page
  int page;

  /// Number of elements per page
  int pageSize;

  /// Decode error body, if any.
  /// The type must be specified in [PaginatedAPIResponse] declaration.
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

  PaginatedAPIResponse({
    this.data,
    required this.total,
    required this.page,
    required this.pageSize,
    this.decodedErrorBody,
    required this.rawValue,
    this.originalResponse,
    required this.statusCode,
    required this.hasError,
    this.message,
  });

  /// Check if the paginatedResponse for the last api call needs to load more data.
  /// Returns a boolean value equal to _true_ if more data has to be downloaded.
  bool needToLoadMoreData() {
    if (total <= (data?.length ?? 0)) {
      return false;
    }

    var page = this.page + 1;

    if ((data?.length ?? 0) < total && (data?.length ?? 0) <= page * pageSize) {
      return true;
    }

    return false;
  }

  factory PaginatedAPIResponse.success(List<T> content,
      {required APIResponse response,
      required int page,
      required int pageSize,
      int? total}) {
    return PaginatedAPIResponse(
      data: content,
      total: total ?? 1000,
      page: page,
      pageSize: pageSize,
      rawValue: response.rawValue,
      originalResponse: response.originalResponse,
      decodedErrorBody: response.decodedErrorBody,
      statusCode: response.statusCode,
      hasError: response.hasError,
      message: response.message,
    );
  }

  factory PaginatedAPIResponse.error(
      {required APIResponse response, String? message}) {
    return PaginatedAPIResponse(
      total: 0,
      page: 0,
      pageSize: 0,
      rawValue: response.rawValue,
      originalResponse: response.originalResponse,
      decodedErrorBody: response.decodedErrorBody,
      statusCode: response.statusCode,
      hasError: response.hasError,
      message: message ?? response.message,
    );
  }

  PaginatedAPIResponse<T, E> copyWith({
    List<T>? data,
    int? total,
    int? page,
    int? pageSize,
    E? decodedErrorBody,
    dynamic rawValue,
    Response? originalResponse,
    int? statusCode,
    bool? hasError,
    String? message,
  }) {
    return PaginatedAPIResponse<T, E>(
      data: data ?? this.data,
      total: total ?? this.total,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      decodedErrorBody: decodedErrorBody ?? this.decodedErrorBody,
      rawValue: rawValue ?? this.rawValue,
      originalResponse: originalResponse ?? this.originalResponse,
      statusCode: statusCode ?? this.statusCode,
      hasError: hasError ?? this.hasError,
      message: message ?? this.message,
    );
  }
}
