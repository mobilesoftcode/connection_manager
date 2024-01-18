

import 'base_connection_manager.dart';
import 'src/utils/enums.dart';
import 'src/data/models/decodable.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';


class ConnectionManagerStub<E extends Decodable>
    extends BaseConnectionManager<E> {
  int _responseStatusCode = 200;
  final bool awaitResponse;

  ConnectionManagerStub({
    int? responseStatusCode,
    this.awaitResponse = true,
    super.decodeErrorFromMap,
    super.mapStatusCodeFromResponse,
    super.onTokenExpired,
    super.onResponseReceived,
    super.returnCatchedErrorMessage = true,
  }) : super(
            baseUrl: "",
          constantHeaders: {},
        ) {
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
  Future<Response> getResponse(
      {required ApiRequestType requestType,
      required String url,
      required Map<String, String> headersForApiRequest,
      ApiBodyType bodyType = ApiBodyType.json,
      Object? body,
      required Duration timeout,
      required bool persistCookies,
      void Function(int p1)? uploadPercentage,
      bool Function(int p1)? validateStatus,
      void Function(int p1, int p2, int p3)? downloadProgress,
      required Client httpClient}) async {
    var json = await rootBundle.loadString(url);

    if (awaitResponse) {
      await Future.delayed(const Duration(seconds: 2));
    }

    var response = Response(
      json,
      _responseStatusCode,
      headers: headersForApiRequest,
    );
    _responseStatusCode = 200;
    return response;
  }
  
}
