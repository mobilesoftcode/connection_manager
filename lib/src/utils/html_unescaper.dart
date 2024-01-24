import 'package:html_unescape/html_unescape.dart';

T verifyHtmlToUnescape<T>(T value) {
  if (value is String) {
    return HtmlUnescape().convert(value) as T;
  } else if (value is Map<String, dynamic>) {
    value.forEach((key, element) {
      if (element is String) {
        value[key] = HtmlUnescape().convert(element);
      } else {
        value[key] = verifyHtmlToUnescape(element);
      }
    });
    return value;
  } else if (value is List) {
    for (var element in value) {
      if (element is String) {
        value[value.indexOf(element)] = HtmlUnescape().convert(element);
      } else {
        value[value.indexOf(element)] = verifyHtmlToUnescape(element);
      }
    }
    return value;
  }
  return value;
}
