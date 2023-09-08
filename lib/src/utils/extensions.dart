extension QueryMapExtension on Map {
  /// Use this method to convert a [Map] to a query string.
  ///
  /// ``` dart
  /// const map = {
  ///   "query1": "test1",
  ///   "query2": "test2"
  /// };
  /// final str = map.convertToQueryString(); // "?query1=test1&query2=test2"
  /// ```
  String convertToQueryString() {
    String? query;
    forEach((key, value) {
      if (query == null) {
        query = "?";
      } else {
        query = "${query ?? ""}&";
      }
      query = "${query ?? ""}$key=$value";
    });
    return query ?? "";
  }
}
