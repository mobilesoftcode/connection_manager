import 'package:connection_manager/src/utils/extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("Test on Map", () {
    test("Test convert Map to query string", () {
      var map = {};
      expect(map.convertToQueryString(), "");

      map = {"test": "1"};
      expect(map.convertToQueryString(), "?test=1");

      map = {"test1": "1", "test2": 2};
      expect(map.convertToQueryString(), "?test1=1&test2=2");
    });
  });
}
