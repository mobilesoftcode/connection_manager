import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'base_connection_manager.dart';
import 'src/utils/enums.dart';
import 'src/data/models/api_response.dart';
import 'src/data/models/decodable.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';

import 'src/utils/html_unescaper.dart';

class ConnectionManagerStub<E extends Decodable>
    extends BaseConnectionManager<E> {
  int _responseStatusCode = 200;
  final bool awaitResponse;

  ConnectionManagerStub({
    int? responseStatusCode,
    this.awaitResponse = true,
    E Function(int statusCode, Map<String, dynamic> data)? decodeErrorFromMap,
    int? Function(Map<String, dynamic>? data)? mapStatusCodeFromResponse,
    Future<String?> Function()? onTokenExpired,
    void Function(Response response)? onResponseReceived,
    bool returnCatchedErrorMessage = true,
  }) : super(
            baseUrl: "",
            constantHeaders: {},
            decodeErrorFromMap: decodeErrorFromMap,
            onTokenExpired: onTokenExpired,
            onResponseReceived: onResponseReceived,
            returnCatchedErrorMessage: returnCatchedErrorMessage) {
    _responseStatusCode = responseStatusCode ?? 200;
  }

  @Deprecated("Use `mockResponseStatus` instead")
  Future<String> mockResponse(
      {required String responseJsonPath, int statusCode = 200}) async {
    _responseStatusCode = statusCode;
    return await Future.value(responseJsonPath);
  }

  ConnectionManagerStub mockResponseStatus({int statusCode = 200}) {
    _responseStatusCode = statusCode;
    return this;
  }


  @override
  Future<APIResponse<T, E>> doApiRequest<T extends Decodable>({
    ApiRequestType requestType = ApiRequestType.post,
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
  }) async {
    try {
      var json = await rootBundle.loadString(endpoint);

      if (awaitResponse) {
        await Future.delayed(const Duration(seconds: 2));
      }

      // Evaluate correct headers
      Map<String, String> headersForApiRequest = Map.of(super.headers);

      if (headers != null) {
        headersForApiRequest.addAll(headers);
      }

      var response = Response(
        json,
        _responseStatusCode,
        headers: headersForApiRequest,
      );

      if (onResponseReceived != null) {
        onResponseReceived!(response);
      }

      _responseStatusCode = 200;

      // Decode body
      dynamic rawValue;
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
      if (statusCode >= 200 && statusCode < 300) {
        T? decoded;
        List<T>? decodedList;

        if (response.contentLength != 0) {
          if (decodeContentFromMap != null) {
            if (rawValue is Map<String, dynamic>) {
              decoded = decodeContentFromMap(rawValue);
              decodedList = [decoded];
            } else if (rawValue is List) {
              decodedList =
                  List.from(rawValue.map((e) => decodeContentFromMap(e)));
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
      } else if (statusCode == 401 &&
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
      } else {
        E? decoded;

        if (response.contentLength != 0) {
          if (decodeErrorFromMapOverride != null) {
            decoded = decodeErrorFromMapOverride(statusCode, rawValue);
          }
        }
        return APIResponse<T, E>(
            decodedErrorBody: decoded,
            rawValue: rawValue,
            originalResponse: response,
            statusCode: statusCode,
            hasError: true);
      }
    } catch (e) {
      return APIResponse(
          rawValue: null,
          originalResponse: null,
          statusCode: 500,
          hasError: true,
          message: returnCatchedErrorMessage ? e.toString() : null);
    }
  }
}
