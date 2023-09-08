import 'package:connection_manager/connection_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("Test need to load more data", () {
    test("Test need to load more data when page*pageSize<data.length", () {
      final response = PaginatedAPIResponse(
          data: List.generate(30, (index) => null),
          total: 50,
          page: 1,
          pageSize: 25,
          rawValue: null,
          statusCode: 200,
          hasError: false);

      expect(response.needToLoadMoreData(), true);
    });

    test("Test not need to load more data when total<=data.length", () {
      final response = PaginatedAPIResponse(
          data: List.generate(30, (index) => null),
          total: 30,
          page: 1,
          pageSize: 50,
          rawValue: null,
          statusCode: 200,
          hasError: false);

      expect(response.needToLoadMoreData(), false);
    });

    test("Test not need to load more data when page*pageSize<=data.length", () {
      final response = PaginatedAPIResponse(
          data: List.generate(50, (index) => null),
          total: 50,
          page: 2,
          pageSize: 25,
          rawValue: null,
          statusCode: 200,
          hasError: false);

      expect(response.needToLoadMoreData(), false);
    });
  });

  test("Test error message priority", () {
    var response = PaginatedAPIResponse.error(
        response: APIResponse(
            rawValue: null,
            originalResponse: null,
            statusCode: 500,
            hasError: true,
            message: "API response message"));

    expect(response.message, "API response message");

    response = PaginatedAPIResponse.error(
        response: APIResponse(
            rawValue: null,
            originalResponse: null,
            statusCode: 500,
            hasError: true,
            message: "API response message"),
        message: "Message");

    expect(response.message, "Message");
  });

  test("Test copyWith", () {
    final res = PaginatedAPIResponse(
        total: 10,
        page: 1,
        pageSize: 10,
        rawValue: "rawValue",
        statusCode: 200,
        hasError: false);
    final resCopy = res.copyWith();

    expect(res.rawValue, resCopy.rawValue);
  });
}
