import 'package:html_unescape/html_unescape.dart';

verifyHtmlToUnescape(dynamic value) {
  if (value is Map<String, dynamic>) {
    value.forEach((key, element) {
      if (element is String) {
        value[key] = HtmlUnescape().convert(element);
      } else {
        verifyHtmlToUnescape(element);
      }
    });
  } else if (value is List) {
    for (var element in value) {
      if (element is String) {
        value[value.indexOf(element)] = HtmlUnescape().convert(element);
      } else {
        verifyHtmlToUnescape(element);
      }
    }
  }
}
