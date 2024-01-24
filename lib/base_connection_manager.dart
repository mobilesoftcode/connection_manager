import 'dart:convert';

import 'package:http/http.dart';

import 'connection_manager.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'src/utils/extensions.dart';

import 'package:http/http.dart' as http;

import 'src/utils/html_unescaper.dart';
export 'package:dio/src/cancel_token.dart';

abstract class BaseConnectionManager<E extends Decodable> {
  /// The base url for all the API calls
  String baseUrl;

  /// Headers for the API requests that are not supposed to change for different API calls.
  final Map<String, String> constantHeaders;

  /// A function to decode an error body received from an API call can be eventually provided.
  /// The [E] type must extend [Decodable].
  ///
  /// The method has two input arguments to retrieve information about http status code
  /// and data as map. It must be passed as _tear-off_ to the [ConnectionManager] constructor.
  /// Note that this function can be overriden for each api request, if needed.
  final E Function(int statusCode, Map<String, dynamic> data)?
      decodeErrorFromMap;

  /// By default, the response of `doApiRequest` method has the status code retrieved
  /// by the http header. Sometimes, this status code is overridden by a code in the response body.
  /// You can use this method to map that code from body and use it to override the http status code.
  ///
  /// Note that the `data` argument is nullable because the parse of body to [Map] can fail.
  /// If the returned [int] is null, the default http status code will be used.
  final int? Function(Map<String, dynamic>? data)? mapStatusCodeFromResponse;

  /// This method can be used in combination with `onTokenExpired` to define a custom rule
  /// to trigger the `onTokenExpired` method. By default, `onTokenExpired` is fired when
  /// the http response has a 401 status code. Eventually, this rule can be expanded thanks
  /// to this method.
  ///
  /// The `onTokenExpired` method will be called either when the status code is 401 or
  /// when the response has an error and this method returns _true_. Check the following code as example.
  ///
  /// ``` dart
  /// onTokenExpiredRuleOverride: (response) {
  ///   if (response.statusCode == 500 && response.body.contains("missing auth")) {
  ///     return true;
  ///   }
  ///   return false;
  /// }
  /// ```
  final bool Function(http.Response response)? onTokenExpiredRuleOverride;

  /// A function fired when the http client gives a 401 response after an API call.
  /// It is used to refresh the auth token, if set, and after returning the new token
  /// the [ConnectionManager] will attempt the API call once again.
  ///
  /// If _null_ the [doApiRequest] method will directly return the error.
  ///
  /// You can use the `onTokenExpiredRuleOverride` parameter to specify other custom rules
  /// to trigger this method depending on the response apart from the 401 status code.
  final Future<String?> Function()? onTokenExpired;

  /// A function fired, if not _null_, when the `doApiRequest` method receives a response
  /// from the BE. This can be useful to manage broadly a [http.Response] the same way
  /// for every api call.
  final void Function(http.Response response)? onResponseReceived;

  /// Specify if the error message coming from the try-catch block in `doApiRequest`
  /// should be returned in the response (i.e. decoding errors). Default to _true_.
  final bool returnCatchedErrorMessage;

  /// Specify the timeout for all the API calls done with this [ConnectionManager].
  /// Defaults to 1 minute.
  final Duration timeout;

  /// If _true_, creates a persistent instance of a cookie manager to be used for
  /// all the API calls done with this [ConnectionManager]. Defaluts to _false_.
  final bool persistCookies;

  /// If set, overrides the default http client for API calls
  final Client? client;

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
  ///
  BaseConnectionManager({
    required this.baseUrl,
    required this.constantHeaders,
    this.decodeErrorFromMap,
    this.mapStatusCodeFromResponse,
    this.onTokenExpiredRuleOverride,
    this.onTokenExpired,
    this.onResponseReceived,
    this.returnCatchedErrorMessage = true,
    this.timeout = const Duration(minutes: 1),
    this.persistCookies = false,
    this.client,
  });

  /// This method is used to generate an API request. It returns a Future to await
  /// with a [APIResponse] with some useful attributes from http response.
  ///
  /// Other then [E] (the custom class to decode error specified in [ConnectionManager] initialisation),
  /// also a [T] custom class can be specified referred to the specific expected response model
  /// for the current API request. Note that [T] must implement [Decodable] and its
  /// [fromMap] method to be used here.
  ///
  /// Other than specifying the request type (get, post...), it is possible to specify
  /// the body type: json, formdata, graphql...
  /// To do so, use the `bodyType` parameter (defaults to json type).
  /// When passing a _json_ body, it's mandatory to json encode the Map, as follows.
  ///
  /// ``` dart
  /// var response = context.read<NetworkProvider>().connectionManager.doApiRequest(
  ///   requestType: ApiRequestType.post,
  ///   endpoint: "/test-endpoint",
  ///   body: jsonEncode({
  ///     "test": "test"
  ///   }),
  /// );
  /// ```
  ///
  /// When using a _formData_ body, it's mandatory to pass it as a [Map<String,dynamic>].
  /// To pass a file, use the [FileData] class provided by this library to create a file and add it
  /// as a vaue of the Map. It's left to the package to manage it correctly.
  ///
  /// When using a _graphQL_ body, it's mandatory to pass it as a [String].
  /// Parameters must be passed as values in the string itself. The [ApiRequestType] should be
  /// _get_ for queries or anything else for _mutations_.
  ///
  /// ## Parameters
  /// - `requestType`: mandatory, the [ApiRequestType] (get, post...)
  /// - `endpoint`: mandatory, the endpoint for this API call
  /// - `bodyType`: the [ApiBodyType] to specify the body type (json, formdata, graphQL...). Defaults to json.
  /// - `headers`: optional, headers as [Map] _to add_ to the headers provided in [ConnectionManager] constructor
  /// - `query`: optional, query parameters as [Map] to add to endpoint
  /// - `body`: optional, the body of the request (usually a json encoded value)
  /// - `decodeContentFromMap`: optional, a method to automatically decode the response model, of type [T], passed as _tear-off_, from a Map response
  /// - `filterMapResponseToDecodeContent`: optional, a key from the original json response map (retrieved as argument of this method) can be specificied to try to the decode the content. This is useful, for example, when the response body has many nested keys but we need to decode a specific one, also deep in the json tree
  /// - `decodeErrorFromMapOverride`: optional, a method to automatically decode the error response model, of type [E], passed as _tear-off_
  /// that overrides the method specified in [ConnectionManager] constructor
  /// - `unescapeHtmlCodes`: a boolean value to eventually unescape html chars in response, defaults to _false_
  /// - `tryRefreshToken`: a boolean value to refresh the auth token and retry the API call when the http status code is 401. Defaluts to _true_.
  /// - `useUtf8Decoding`: a boolean value to eventyally decode the response with utf8 directly to the bytes, ignoring the body. Defaluts to _false_.
  /// - `timeout`: the timeout for the API call, overrides that of the [ConnectionManager].
  /// - `persistCookies`: overrides the persistCookies property of [ConnectionManager]. If _true_ creates an instance of [CookieManager] to persist cookies for all the API calls.
  /// - `uploadPercentage`: optional, it's used to retrieve the upload percentage status for _formData_ bodies. It's ignored for other _bodyTypes_.
  /// - `validateStatus`: optional, it's used to evaluate response status code and manage it as success/error accordingly. Simply return _true_ or _false_ depending on the _status_. Note that status codes between 200 and 299 are always accepted as successfull.
  /// - `downloadProgress`: optional, it's used to retrieve the download percentage status for responses from BE. It has three arguments: download bytes, total bytes count and percentage downloaded.
  /// - `cancelToken`: optional, it's eventually used to cancel the http request before awaiting termination. It does not work for _graphql_ requests.
  ///
  /// ## Usage
  /// ``` dart
  /// // Class to decode in response
  /// class User implements Decodable {
  ///   String? name;
  ///
  ///   User({
  ///     this.name,
  ///   });
  ///
  ///   factory User.fromMap(Map<String, dynamic> map) => User(name: map['user']);
  /// }
  ///
  /// // Api network caller
  /// var response = context.read<NetworkProvider>().connectionManager.doApiRequest(
  ///   requestType: ApiRequestType.get,
  ///   endpoint: "/test-endpoint",
  ///   decodeContentFromMap: User.fromMap,
  /// );
  /// ```
  Future<APIResponse<T, E>> doApiRequest<T extends Decodable>({
    ApiRequestType requestType = ApiRequestType.get,
    required String endpoint,
    ApiBodyType bodyType = ApiBodyType.json,
    Map<String, String>? headers,
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
    CancelToken? cancelToken,
  }) async {
    // Evaluate correct endpoint for API call
    String url;
    if (endpoint.contains("http")) {
      url = endpoint;
    } else {
      url = baseUrl + endpoint;
    }

    // Evaluate correct headers
    Map<String, String> headersForApiRequest = Map.of(this.headers);

    if (headers != null) {
      headersForApiRequest.addAll(headers);
    }

    if (query != null) {
      url += query.convertToQueryString();
    }

    var httpClient = client ?? http.Client();

    try {
      http.Response response = await getResponse(
        requestType: requestType,
        url: url,
        headersForApiRequest: headersForApiRequest,
        bodyType: bodyType,
        body: body,
        timeout: timeout ?? this.timeout,
        persistCookies: persistCookies ?? this.persistCookies,
        uploadPercentage: uploadPercentage,
        validateStatus: validateStatus,
        downloadProgress: downloadProgress,
        httpClient: httpClient,
        cancelToken: cancelToken,
      );

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

  Future<http.Response> getResponse({
    required ApiRequestType requestType,
    required String url,
    required Map<String, String> headersForApiRequest,
    ApiBodyType bodyType = ApiBodyType.json,
    Object? body,
    required Duration timeout,
    required bool persistCookies,
    void Function(int)? uploadPercentage,
    bool Function(int)? validateStatus,
    void Function(int, int, int)? downloadProgress,
    required http.Client httpClient,
    CancelToken? cancelToken,
  });

  /// The headers used for the API call
  Map<String, String> get headers {
    Map<String, String> map = {};
    map.addAll(constantHeaders);
    map.addAll(_addedHeaders);
    return map;
  }

  /// The headers added after the isntantiation of the [ConnectionManager],
  /// using [setSharedHeaders].
  Map<String, String> _addedHeaders = {};

  /// Call this method to add new headers to the Connection Manager to be used
  /// for all the API calls toghether with `constantHeaders` passed to the constructor.
  ///
  /// To add an "Authorization" header, use [setAuthHeader].
  void setSharedHeaders(Map<String, String> headers, {bool override = false}) {
    if (override) {
      _addedHeaders = headers;
    } else {
      headers.removeWhere((key, value) => this.headers.containsKey(key));
      _addedHeaders.addAll(headers);
    }
  }

  /// Call this method to add or reset an Authorization header after creating the [ConnectionManager].
  ///
  /// This method will override eixisting "Authorization" header.
  void setAuthHeader(String token) {
    _addedHeaders["Authorization"] = token;
  }

  /// Call this method to change the base url of the [ConnectionManager].
  void changeBaseUrl(String newBaseUrl) {
    baseUrl = newBaseUrl;
  }

  /// Deletes the auth header from headers
  void removeAuthHeader() {
    _addedHeaders.remove("Authorization");
  }
}
