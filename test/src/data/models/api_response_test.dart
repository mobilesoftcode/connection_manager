import 'package:connection_manager/connection_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("Test copyWith method and == operator", () {
    final res = APIResponse(
        rawValue: "rawValue",
        originalResponse: null,
        statusCode: 200,
        hasError: false,
        message: "none");

    final resCopy = res.copyWith();

    expect(res, resCopy);
  });

  test("Test hash value", () {
    final res1 = APIResponse(
        rawValue: "rawValue",
        originalResponse: null,
        statusCode: 200,
        hasError: false,
        message: "none");

    final res2 = APIResponse(
        rawValue: "rawValue",
        originalResponse: null,
        statusCode: 200,
        hasError: false,
        message: "none");
    expect(res1.hashCode, res2.hashCode);
  });
}
