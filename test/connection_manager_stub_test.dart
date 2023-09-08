import 'dart:async';

import 'package:connection_manager/connection_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test("Test wait 2 seconds if awaitResponse is set to true", () async {
    final connManager = ConnectionManagerStub();
    final timeoutRes = connManager.doApiRequest(endpoint: "mocks/test.json");

    expect(() => timeoutRes.timeout(const Duration(seconds: 1)),
        throwsA(isA<TimeoutException>()));

    final res = await connManager
        .doApiRequest(endpoint: "mocks/test.json")
        .timeout(const Duration(seconds: 2, milliseconds: 100));
    expect(res.hasError, false);
  });

  test("Test no waiting if awaitResponse set to false", () async {
    final connManager = ConnectionManagerStub(awaitResponse: false);
    final res = await connManager
        .doApiRequest(endpoint: "mocks/test.json")
        .timeout(const Duration(
          milliseconds: 100,
        ));
    expect(res.hasError, false);
  });

  test("Test custom response status code", () async {
    final connManager = ConnectionManagerStub(responseStatusCode: 403);
    final res = await connManager.doApiRequest(endpoint: "mocks/test.json");
    expect(res.statusCode, 403);
  });

  test("Mock response for api call", () async {
    final connManager = ConnectionManagerStub(awaitResponse: false);
    final endpoint =
        await connManager.mockResponse(responseJsonPath: "mocks/test.json");
    final res = await connManager.doApiRequest(endpoint: endpoint);

    var testJson = await rootBundle.loadString("mocks/test.json");

    expect(res.originalResponse?.body, testJson);
  });
}
