import 'dart:async';

import 'package:connection_manager/connection_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks/test_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test("Test wait 2 seconds if awaitResponse is set to true", () async {
    final connManager = ConnectionManagerStub();
    final timeoutRes =
        connManager.doApiRequest(endpoint: "mocks/test_map.json");

    expect(() => timeoutRes.timeout(const Duration(seconds: 1)),
        throwsA(isA<TimeoutException>()));

    final res = await connManager
        .doApiRequest(endpoint: "mocks/test_map.json")
        .timeout(const Duration(seconds: 2, milliseconds: 100));
    expect(res.hasError, false);
  });

  test("Test no waiting if awaitResponse set to false", () async {
    final connManager = ConnectionManagerStub(awaitResponse: false);
    final res = await connManager
        .doApiRequest(endpoint: "mocks/test_map.json")
        .timeout(const Duration(
          milliseconds: 100,
        ));
    expect(res.hasError, false);
  });

  test("Test custom response status code", () async {
    final connManager = ConnectionManagerStub(responseStatusCode: 403);
    final res = await connManager.doApiRequest(endpoint: "mocks/test_map.json");
    expect(res.statusCode, 403);
  });

  test("Test doApiRequest with headers", () async {
    final connManager = ConnectionManagerStub(awaitResponse: false);
    final res = await connManager.doApiRequest(
        endpoint: "mocks/test_map.json", headers: {"custom-header": "test"});

    expect(res.originalResponse?.headers, {"custom-header": "test"});
  });

  group("Test decode response", () {
    test("Test decode model", () async {
      final connManager = ConnectionManagerStub(
        awaitResponse: false,
      );
      final res = await connManager.doApiRequest(
          endpoint: "mocks/test_map.json",
          decodeContentFromMap: TestModel.fromMap);

      expect(res.decodedBody?.test, true);
    });

    test("Test decode model with utf8", () async {
      final connManager = ConnectionManagerStub(
        awaitResponse: false,
      );
      final res = await connManager.doApiRequest(
          endpoint: "mocks/test_map.json",
          useUtf8Decoding: true,
          decodeContentFromMap: TestModel.fromMap);

      expect(res.decodedBody?.test, true);
    });

    test("Test decode model with unescape html", () async {
      final connManager = ConnectionManagerStub(
        awaitResponse: false,
      );
      var res = await connManager.doApiRequest(
          endpoint: "mocks/test_map.json",
          unescapeHtmlCodes: false,
          decodeContentFromMap: TestModel.fromMap);
      expect(res.decodedBody?.unescapeChars, "test&amp;");

      res = await connManager.doApiRequest(
          endpoint: "mocks/test_map.json",
          unescapeHtmlCodes: true,
          decodeContentFromMap: TestModel.fromMap);

      expect(res.decodedBody?.unescapeChars, "test&");
    });

    test("Test decode model from list", () async {
      final connManager = ConnectionManagerStub(
        awaitResponse: false,
      );
      final res = await connManager.doApiRequest(
          endpoint: "mocks/test_list.json",
          decodeContentFromMap: TestModel.fromMap);

      expect(res.decodedBody, null);
      expect(res.decodedBodyAsList?.length, 1);
    });
  });

  test("Test map status code from response", () async {
    final connManager = ConnectionManagerStub(
      awaitResponse: false,
      mapStatusCodeFromResponse: (data) {
        return 400;
      },
    );
    final res = await connManager.doApiRequest(
      endpoint: "mocks/test_map.json",
    );

    expect(res.statusCode, 400);
  });

  test("Test onTokenExpired callback", () async {
    bool refreshTokenCalled = false;
    final connManager = ConnectionManagerStub(
      awaitResponse: false,
      onTokenExpired: () async {
        refreshTokenCalled = true;
        return "newtoken";
      },
    );
    expect(refreshTokenCalled, false);
    final res =
        await connManager.mockResponseStatus(statusCode: 401).doApiRequest(
              endpoint: "mocks/test_map.json",
            );
    expect(refreshTokenCalled, true);
    expect(res.statusCode, 200);
  });

  test("Test onResponseReceived callback", () async {
    bool received = false;
    final connManager = ConnectionManagerStub(
        awaitResponse: false,
        onResponseReceived: (response) => received = true);
    expect(received, false);
    final _ = await connManager.doApiRequest(
      endpoint: "mocks/test_map.json",
    );

    expect(received, true);
  });

  test("Mock response for api call", () async {
    final connManager = ConnectionManagerStub(awaitResponse: false);
    final res = await connManager
        .mockResponseStatus()
        .doApiRequest(endpoint: "mocks/test_map.json");

    var testJson = await rootBundle.loadString("mocks/test_map.json");

    expect(res.originalResponse?.body, testJson);
  });

  test("Mock response for api call deprecated", () async {
    final connManager = ConnectionManagerStub(awaitResponse: false);
    final res = await connManager
        .mockResponse(responseJsonPath: "mocks/test_map.json")
        .then((value) => connManager.doApiRequest(endpoint: value));

    var testJson = await rootBundle.loadString("mocks/test_map.json");

    expect(res.originalResponse?.body, testJson);
  });
}
