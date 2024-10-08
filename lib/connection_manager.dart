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
export 'src/logic/cubit/single_api_call/single_api_call_cubit.dart';

import 'dart:convert';
import 'package:connection_manager/src/utils/extensions.dart';

import 'base_connection_manager.dart';
import 'src/data/models/file_data.dart';
import 'src/data/models/paginated_api_response.dart';
import 'package:dio/dio.dart' as d;
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'src/data/models/decodable.dart';
import 'package:http/http.dart' as http;

import 'src/data/models/api_response.dart';
import 'src/utils/enums.dart';

typedef PaginatedAPIRequest<T extends Decodable, E extends Decodable>
    = Future<PaginatedAPIResponse<T, E>> Function(
        int page, Map<String, String>? query);

typedef APIRequest<T extends Decodable, E extends Decodable>
    = Future<APIResponse<T, E>> Function();

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
    required super.baseUrl,
    required super.constantHeaders,
    super.decodeErrorFromMap,
    super.mapStatusCodeFromResponse,
    super.onTokenExpiredRuleOverride,
    super.onTokenExpired,
    super.onResponseReceived,
    super.returnCatchedErrorMessage = true,
    super.timeout = const Duration(minutes: 1),
    super.persistCookies = false,
    super.client,
  }) {
    if (persistCookies) {
      _dio = d.Dio();
      _dio?.interceptors.add(CookieManager(CookieJar()));
    }
  }

  @override
  Future<http.Response> getResponse({
    required ApiRequestType requestType,
    required String url,
    required Map<String, String> headersForApiRequest,
    ApiBodyType bodyType = ApiBodyType.json,
    Object? body,
    required Duration timeout,
    Map<String, String>? query,
    required bool persistCookies,
    void Function(int)? uploadPercentage,
    bool Function(int)? validateStatus,
    void Function(int, int, int)? downloadProgress,
    required http.Client httpClient,
    d.CancelToken? cancelToken,
  }) async {
    late http.Response response;
    if (query != null) {
      url += query.convertToQueryString();
    }

    if (bodyType == ApiBodyType.json) {
      if (persistCookies || downloadProgress != null || cancelToken != null) {
        response = await _getDioResponse(
          url: url,
          requestType: requestType,
          body: body,
          bodyType: bodyType,
          headers: headersForApiRequest,
          timeout: timeout,
          validateStatus: validateStatus,
          downloadProgress: downloadProgress,
          cancelToken: cancelToken,
        );
      } else {
        switch (requestType) {
          case ApiRequestType.get:
            response = await httpClient
                .get(Uri.parse(url), headers: headersForApiRequest)
                .timeout(timeout);
            break;
          case ApiRequestType.post:
            response = await httpClient
                .post(Uri.parse(url), headers: headersForApiRequest, body: body)
                .timeout(timeout);
            break;
          case ApiRequestType.put:
            response = await httpClient
                .put(Uri.parse(url), headers: headersForApiRequest, body: body)
                .timeout(timeout);
            break;
          case ApiRequestType.patch:
            response = await httpClient
                .patch(Uri.parse(url),
                    headers: headersForApiRequest, body: body)
                .timeout(timeout);
            break;
          case ApiRequestType.delete:
            response = await httpClient
                .delete(Uri.parse(url),
                    headers: headersForApiRequest, body: body)
                .timeout(timeout);
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
        cancelToken: cancelToken,
      );
    }
    return response;
  }

  /// Use DIO package to make a request with a FormData/xwwwformurlencoded body
  Future<http.Response> _getDioResponse({
    required String url,
    required ApiRequestType requestType,
    required Map<String, String> headers,
    required ApiBodyType bodyType,
    required Object? body,
    required Duration timeout,
    void Function(int)? uploadPercentage,
    bool Function(int)? validateStatus,
    void Function(int, int, int)? downloadProgress,
    d.CancelToken? cancelToken,
  }) async {
    var dio = _dio ?? d.Dio();
    dio.options.baseUrl = url;
    dio.options.headers = headers;
    dio.options.receiveTimeout = timeout;
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
            cancelToken: cancelToken,
          );
          break;
        case ApiRequestType.post:
          response = await dio.post(
            url,
            data: data,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
            cancelToken: cancelToken,
          );
          break;
        case ApiRequestType.put:
          response = await dio.put(
            url,
            data: data,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
            cancelToken: cancelToken,
          );
          break;
        case ApiRequestType.patch:
          response = await dio.patch(
            url,
            data: data,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
            cancelToken: cancelToken,
          );
          break;
        case ApiRequestType.delete:
          response = await dio.delete(
            url,
            data: data,
            cancelToken: cancelToken,
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
