import 'package:connection_manager/src/utils/html_unescaper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const htmlToUnescape = "test&amp;test";
  test("Test unescape html characters in string", () {
    var unescaped = verifyHtmlToUnescape(htmlToUnescape);
    expect(unescaped, "test&test");
  });

  test("Test unescape html characters in list", () {
    final list = [htmlToUnescape];
    var unescaped = verifyHtmlToUnescape(list);
    expect(unescaped, ["test&test"]);
  });

  test("Test unescape html characters in map", () {
    final map = {"test": htmlToUnescape};
    var unescaped = verifyHtmlToUnescape(map);
    expect(unescaped, {"test": "test&test"});
  });

  test("Test unescape html characters in map containing list", () {
    final map = {
      "test": [htmlToUnescape]
    };
    var unescaped = verifyHtmlToUnescape(map);
    expect(unescaped, {
      "test": ["test&test"]
    });
  });

  test("Test unescape html characters in list containing map", () {
    final list = [
      {"test": htmlToUnescape}
    ];
    var unescaped = verifyHtmlToUnescape(list);
    expect(unescaped, [
      {"test": "test&test"}
    ]);
  });
}
