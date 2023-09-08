library connection_manager;

export 'src/data/models/decodable.dart';
export 'src/data/models/file_data.dart';
export 'src/data/models/paginated_api_response.dart';
export 'src/utils/enums.dart';
export 'src/ui/api_call_builder.dart';
export 'src/ui/paginated_api_call_builder.dart';
export 'base_connection_manager.dart';
export 'connection_manager_stub.dart';
export 'src/data/models/api_response.dart';
export 'src/logic/cubit/paginated_api_call/paginated_api_call_cubit.dart';

import 'dart:convert';
import 'base_connection_manager.dart';
import 'src/data/models/file_data.dart';
import 'src/data/models/paginated_api_response.dart';
import 'src/utils/extensions.dart';
import 'package:dio/dio.dart' as d;
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'src/data/models/decodable.dart';
import 'package:http/http.dart' as http;

import 'src/data/models/api_response.dart';
import 'src/utils/enums.dart';
import 'src/utils/html_unescaper.dart';

typedef PaginatedAPIRequest<T extends Decodable, E extends Decodable>
    = Future<PaginatedAPIResponse<T, E>> Function(
        int page, Map<String, String>? query);

typedef APIRequest<T extends Decodable, E extends Decodable>
    = Future<APIResponse<T, E>>;

/// Class to manage API and network calls. It can be instantiated as a singleton
/// to use a single instance of it all through the app.
class ConnectionManager<E extends Decodable> extends BaseConnectionManager<E> {
  /// This dio instance is initialized if the `persistCookies` was set to _true_ in
  /// [ConnectionManager] constructor. This way, a cookie interceptor is added to dio options
  /// and cookies are reused for all the API calls.
  d.Dio? _dio;

  /// Initialise a [ConnectionManager] to manage API and network calls.
  ///
  /// It is suggested to initialize it as a Provider or a Singleton to use a single instance of it all through the app.
  /// The type [E] can be specified to define a custom model for error responses.
  ///
  /// ## Example
  /// ``` dart
  /// // Create the provider
  /// class NetworkProvider {
  ///  final String baseUrl;
  ///
  ///  // Connection Manager definition
  ///  final _connectionManager = ConnectionManager<CustomError>(
  ///      baseUrl: baseUrl,
  ///      constantHeaders: {"Content-Type": "application/json"},
  ///      decodeErrorFromMap: CustomError.fromMapError,
  ///      onTokenExpired: () async {
  ///         return await refreshToken(); // refreshToken() is not a method of this package
  ///      },
  ///      onResponseReceived: (response) {
  ///         print(response.body);
  ///      },
  ///   );
  ///
  ///  // Connection Manager getter
  ///  ConnectionManager<CustomError> get connectionManager => _connectionManager;
  /// }
  ///
  /// // Use the provider
  /// class MyApp extends StatelessWidget {
  ///   @override build(BuildContext context) {
  ///     return Provider(
  ///       create: (context) => NetworkProvider(
  ///         baseUrl: "https://test.com/api",
  ///       ),
  ///       child: Builder(
  ///         builder: (context) {
  ///           var networkProvider = context.read<NetworkProvider>();
  ///           return Text(networkProvider.baseUrl);
  ///         }
  ///       ),
  ///     );
  ///   }
  /// }
  /// ```
  ///
  /// For further informations on constructor parameters, see [docs]("https://git.mobilesoft.it/mobile-competence-center/competence-flutter/packages/connection_manager/-/blob/master/README.md").
  ConnectionManager({
    required baseUrl,
    required Map<String, String> constantHeaders,
    E Function(int statusCode, Map<String, dynamic> data)? decodeErrorFromMap,
    int? Function(Map<String, dynamic>? data)? mapStatusCodeFromResponse,
    bool Function(http.Response response)? onTokenExpiredRuleOverride,
    Future<String?> Function()? onTokenExpired,
    void Function(http.Response response)? onResponseReceived,
    bool returnCatchedErrorMessage = true,
    Duration timeout = const Duration(minutes: 1),
    bool persistCookies = false,
    http.Client? client,
  }) : super(
          baseUrl: baseUrl,
          constantHeaders: constantHeaders,
          decodeErrorFromMap: decodeErrorFromMap,
          mapStatusCodeFromResponse: mapStatusCodeFromResponse,
          onTokenExpiredRuleOverride: onTokenExpiredRuleOverride,
          onTokenExpired: onTokenExpired,
          onResponseReceived: onResponseReceived,
          returnCatchedErrorMessage: returnCatchedErrorMessage,
          timeout: timeout,
          persistCookies: persistCookies,
          client: client,
        ) {
    if (persistCookies) {
      _dio = d.Dio();
      _dio?.interceptors.add(CookieManager(CookieJar()));
    }
  }

  @override
  Future<APIResponse<T, E>> doApiRequest<T extends Decodable>({
    required ApiRequestType requestType,
    required String endpoint,
    Map<String, String>? headers,
    ApiBodyType bodyType = ApiBodyType.json,
    Map<String, String>? query,
    Object? body,
    T Function(Map<String, dynamic> data)? decodeContentFromMap,
    dynamic Function(Map<String, dynamic> data)?
        filterMapResponseToDecodeContent,
    E Function(int statusCode, Map<String, dynamic> data)?
        decodeErrorFromMapOverride,
    bool unescapeHtmlCodes = false,
    bool tryRefreshToken = true,
    bool useUtf8Decoding = false,
    Duration? timeout,
    bool? persistCookies,
    void Function(int)? uploadPercentage,
    bool Function(int)? validateStatus,
    void Function(int, int, int)? downloadProgress,
  }) async {
    // Evaluate correct endpoint for API call
    String url;
    if (endpoint.contains("http")) {
      url = endpoint;
    } else {
      url = baseUrl + endpoint;
    }

    // Evaluate correct headers
    Map<String, String> headersForApiRequest = Map.of(super.headers);

    if (headers != null) {
      headersForApiRequest.addAll(headers);
    }

    if (query != null) {
      url += query.convertToQueryString();
    }

    var httpClient = client ?? http.Client();

    try {
      late http.Response response;

      if (bodyType == ApiBodyType.json) {
        if (persistCookies ??
            super.persistCookies || downloadProgress != null) {
          response = await _getDioResponse(
            url: url,
            requestType: requestType,
            body: body,
            bodyType: bodyType,
            headers: headersForApiRequest,
            timeout: timeout,
            validateStatus: validateStatus,
            downloadProgress: downloadProgress,
          );
        } else {
          switch (requestType) {
            case ApiRequestType.get:
              response = await httpClient
                  .get(Uri.parse(url), headers: headersForApiRequest)
                  .timeout(timeout ?? super.timeout);
              break;
            case ApiRequestType.post:
              response = await httpClient
                  .post(Uri.parse(url),
                      headers: headersForApiRequest, body: body)
                  .timeout(timeout ?? super.timeout);
              break;
            case ApiRequestType.put:
              response = await httpClient
                  .put(Uri.parse(url),
                      headers: headersForApiRequest, body: body)
                  .timeout(timeout ?? super.timeout);
              break;
            case ApiRequestType.patch:
              response = await httpClient
                  .patch(Uri.parse(url),
                      headers: headersForApiRequest, body: body)
                  .timeout(timeout ?? super.timeout);
              break;
            case ApiRequestType.delete:
              response = await httpClient
                  .delete(Uri.parse(url), headers: headersForApiRequest)
                  .timeout(timeout ?? super.timeout);
              break;
          }
        }
      } else if (bodyType == ApiBodyType.graphQL) {
        response = await _getGraphQLResponse(
          url: url,
          requestType: requestType,
          body: body,
          bodyType: bodyType,
          headers: headersForApiRequest,
          timeout: timeout,
        );
      } else {
        response = await _getDioResponse(
          url: url,
          requestType: requestType,
          body: body,
          bodyType: bodyType,
          headers: headersForApiRequest,
          timeout: timeout,
          uploadPercentage: uploadPercentage,
          validateStatus: validateStatus,
        );
      }

      if (onResponseReceived != null) {
        onResponseReceived!(response);
      }

      // Decode body
      dynamic rawValue;
      try {
        if (response.contentLength != 0) {
          if (useUtf8Decoding) {
            rawValue = jsonDecode(utf8.decode(response.bodyBytes));
          } else {
            rawValue = jsonDecode(response.body);
          }
          if (unescapeHtmlCodes) {
            verifyHtmlToUnescape(rawValue);
          }
        }
      } catch (e) {
        rawValue = response.body;
      }

      var statusCode = response.statusCode;
      if (mapStatusCodeFromResponse != null) {
        try {
          statusCode =
              mapStatusCodeFromResponse!(rawValue) ?? response.statusCode;
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
        }
      }

      // Evaluate response
      if ((statusCode >= 200 && statusCode < 300) ||
          (validateStatus != null && validateStatus(statusCode))) {
        T? decoded;
        List<T>? decodedList;

        if (response.contentLength != 0) {
          if (decodeContentFromMap != null) {
            var mapToDecode = rawValue;
            if (filterMapResponseToDecodeContent != null) {
              mapToDecode = filterMapResponseToDecodeContent(rawValue);
            }
            if (mapToDecode is Map<String, dynamic>) {
              decoded = decodeContentFromMap(mapToDecode);
              decodedList = [decoded];
            } else if (mapToDecode is List) {
              decodedList =
                  List.from(mapToDecode.map((e) => decodeContentFromMap(e)));
            }
          }
        }
        return APIResponse<T, E>(
            decodedBody: decoded,
            decodedBodyAsList: decodedList,
            rawValue: rawValue,
            originalResponse: response,
            statusCode: statusCode,
            hasError: false);
      } else if ((statusCode == 401 ||
              (onTokenExpiredRuleOverride != null &&
                  onTokenExpiredRuleOverride!(response))) &&
          onTokenExpired != null &&
          tryRefreshToken) {
        var newToken = await onTokenExpired!();
        if (newToken != null) {
          setAuthHeader(newToken);
        }
        return await doApiRequest(
          requestType: requestType,
          endpoint: endpoint,
          headers: headers,
          bodyType: bodyType,
          query: query,
          body: body,
          decodeContentFromMap: decodeContentFromMap,
          filterMapResponseToDecodeContent: filterMapResponseToDecodeContent,
          decodeErrorFromMapOverride: decodeErrorFromMapOverride,
          unescapeHtmlCodes: unescapeHtmlCodes,
          tryRefreshToken: false,
          useUtf8Decoding: useUtf8Decoding,
          timeout: timeout,
          persistCookies: persistCookies,
          uploadPercentage: uploadPercentage,
          validateStatus: validateStatus,
          downloadProgress: downloadProgress,
        );
      }

      // http status error
      E? decoded;

      if (response.contentLength != 0) {
        try {
          if (decodeErrorFromMapOverride != null) {
            decoded = decodeErrorFromMapOverride(statusCode, rawValue);
          } else if (decodeErrorFromMap != null) {
            decoded = decodeErrorFromMap!(statusCode, rawValue);
          }
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
        }
      }
      return APIResponse<T, E>(
          decodedErrorBody: decoded,
          rawValue: rawValue,
          originalResponse: response,
          statusCode: statusCode,
          hasError: true);
    } catch (e) {
      if (e.toString().toLowerCase() == "failed to parse header value" &&
          onTokenExpired != null &&
          tryRefreshToken) {
        var newToken = await onTokenExpired!();
        if (newToken != null) {
          setAuthHeader(newToken);
        }
        return await doApiRequest(
          requestType: requestType,
          endpoint: endpoint,
          headers: headers,
          bodyType: bodyType,
          query: query,
          body: body,
          decodeContentFromMap: decodeContentFromMap,
          decodeErrorFromMapOverride: decodeErrorFromMapOverride,
          unescapeHtmlCodes: unescapeHtmlCodes,
          tryRefreshToken: false,
        );
      }
      return APIResponse(
          rawValue: null,
          originalResponse: null,
          statusCode: 500,
          hasError: true,
          message: returnCatchedErrorMessage ? e.toString() : null);
    }
  }

  /// Use DIO package to make a request with a FormData/xwwwformurlencoded body
  Future<http.Response> _getDioResponse({
    required String url,
    required ApiRequestType requestType,
    required Map<String, String> headers,
    required ApiBodyType bodyType,
    required Object? body,
    Duration? timeout,
    void Function(int)? uploadPercentage,
    bool Function(int)? validateStatus,
    void Function(int, int, int)? downloadProgress,
  }) async {
    var dio = _dio ?? d.Dio();
    dio.options.baseUrl = url;
    dio.options.headers = headers;
    dio.options.receiveTimeout = timeout ?? super.timeout;
    if (validateStatus != null) {
      dio.options.validateStatus = (status) {
        if (status == null) {
          return false;
        }
        if (status >= 200 && status < 300) {
          return true;
        }
        return validateStatus(status);
      };
    }
    var data = body;
    if (bodyType == ApiBodyType.formData && body is Map<String, dynamic>) {
      var filteredMap = Map.of(body);
      filteredMap.removeWhere((key, value) => value is FileData);
      body.removeWhere((key, value) => value is! FileData);

      body.forEach((key, value) {
        filteredMap.addEntries([
          MapEntry(
              key, d.MultipartFile.fromBytes(value.bytes, filename: value.name))
        ]);
      });
      data = d.FormData.fromMap(filteredMap);
    } else if (bodyType == ApiBodyType.xWwwFormUrlencoded) {
      dio.options.contentType = d.Headers.formUrlEncodedContentType;
    }

    onSendProgress(int count, int total) {
      var percentage = (count * 100) / total;
      if (uploadPercentage != null) {
        uploadPercentage(percentage.round());
      }
    }

    onReceiveProgress(int count, int total) {
      var percentage = (count * 100) / total;
      if (downloadProgress != null) {
        downloadProgress(count, total, percentage.round());
      }
    }

    try {
      late d.Response response;
      switch (requestType) {
        case ApiRequestType.get:
          response = await dio.get(
            url,
            onReceiveProgress: onReceiveProgress,
          );
          break;
        case ApiRequestType.post:
          response = await dio.post(
            url,
            data: data,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          );
          break;
        case ApiRequestType.put:
          response = await dio.put(
            url,
            data: data,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          );
          break;
        case ApiRequestType.patch:
          response = await dio.patch(
            url,
            data: data,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          );
          break;
        case ApiRequestType.delete:
          response = await dio.delete(
            url,
            data: data,
          );
          break;
      }

      final statusCode = response.statusCode ?? 500;
      final headers = response.headers.map
          .map((key, value) => MapEntry(key, value.join("; ")));
      final request = http.Request(
          response.requestOptions.method, response.requestOptions.uri);

      try {
        final bodyResponse = jsonEncode(response.data);
        return http.Response(
          bodyResponse,
          statusCode,
          headers: headers,
          request: request,
        );
      } catch (_) {}

      return http.Response.bytes(
        utf8.encode(response.data),
        statusCode,
        headers: headers,
        request: request,
      );
    } catch (error) {
      return http.Response(error.toString(), 500);
    }
  }

  /// Use GraphQL package to make a request with graphql
  Future<http.Response> _getGraphQLResponse({
    required String url,
    required ApiRequestType requestType,
    required Map<String, String> headers,
    required ApiBodyType bodyType,
    required Object? body,
    Duration? timeout,
  }) async {
    var link = HttpLink(
      url,
      defaultHeaders: headers,
    );

    var client =
        GraphQLClient(link: link, cache: GraphQLCache(store: InMemoryStore()));

    if (body is! String) {
      return http.Response("Body query must be a String", 500);
    }

    try {
      late QueryResult response;
      switch (requestType) {
        case ApiRequestType.get:
          QueryOptions options = QueryOptions(document: gql(body));
          response = await client.query(
            options,
          );
          break;
        case ApiRequestType.post:
        case ApiRequestType.put:
        case ApiRequestType.patch:
        case ApiRequestType.delete:
          MutationOptions options = MutationOptions(document: gql(body));
          response = await client.mutate(
            options,
          );
          break;
      }

      var responseHeaders =
          response.context.entry<HttpLinkResponseContext>()?.headers;
      responseHeaders?["content-type"] =
          headers["content-type"] ?? headers["Content-Type"] ?? "";

      var message = "";
      if (response.exception?.graphqlErrors.isNotEmpty ?? false) {
        message = response.exception?.graphqlErrors[0].message ?? "";
      }
      var exception = response.exception?.linkException;
      var responseBody =
          response.hasException && exception is HttpLinkParserException
              ? exception.response.body
              : jsonEncode(response.data ?? message);
      var statusCode =
          response.context.entry<HttpLinkResponseContext>()?.statusCode ?? 500;
      return http.Response(
        responseBody,
        response.hasException ? 500 : statusCode,
        headers: responseHeaders ?? headers,
      );
    } catch (error) {
      return http.Response(error.toString(), 500);
    }
  }
}
