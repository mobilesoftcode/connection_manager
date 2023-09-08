import 'package:connection_manager/connection_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("Test headers", () {
    test("Test initial constant headers set", () {
      final connManager =
          ConnectionManager(baseUrl: "", constantHeaders: {"test": "1"});

      expect(connManager.headers, {"test": "1"});
    });

    test("Test other headers set", () {
      final connManager =
          ConnectionManager(baseUrl: "", constantHeaders: {"test": "1"});

      connManager.setSharedHeaders({"test2": "2"});

      expect(connManager.headers, {"test": "1", "test2": "2"});
    });

    test("Test other headers set not overriding old headers", () {
      final connManager =
          ConnectionManager(baseUrl: "", constantHeaders: {"test": "1"});

      connManager.setSharedHeaders({"test": "2"});

      expect(connManager.headers, {"test": "1"});
    });

    test("Test other headers set overriding old headers", () {
      final connManager =
          ConnectionManager(baseUrl: "", constantHeaders: {"test": "1"});

      connManager.setSharedHeaders({"test": "2"}, override: true);

      expect(connManager.headers, {"test": "2"});
    });

    test("Test auth header set", () {
      final connManager = ConnectionManager(baseUrl: "", constantHeaders: {});
      expect(connManager.headers, {});
      connManager.setAuthHeader("Bearer");

      expect(connManager.headers, {"Authorization": "Bearer"});
    });

    test("Test auth header reset", () {
      final connManager = ConnectionManager(baseUrl: "", constantHeaders: {});
      connManager.removeAuthHeader();
      expect(connManager.headers, {});

      connManager.setSharedHeaders({"Authorization": "Bearer"});

      connManager.removeAuthHeader();
      expect(connManager.headers, {});
    });
  });

  test("Test change baseurl", () {
    final connManager =
        ConnectionManager(baseUrl: "baseUrl", constantHeaders: {});
    expect(connManager.baseUrl, "baseUrl");

    connManager.changeBaseUrl("newBaseUrl");
    expect(connManager.baseUrl, "newBaseUrl");
  });
}
